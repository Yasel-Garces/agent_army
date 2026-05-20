#!/usr/bin/env node
/**
 * skill-eval.js — UserPromptSubmit skill matcher.
 *
 * Reads the user's prompt from stdin (JSON {prompt: "..."} or raw text),
 * matches it against skill-rules.json, and prints a structured reminder
 * listing skills the agent should consider activating.
 */

const fs = require('fs');
const path = require('path');

const RULES_PATH = path.join(__dirname, 'skill-rules.json');

function loadRules() {
  try {
    return JSON.parse(fs.readFileSync(RULES_PATH, 'utf-8'));
  } catch (err) {
    // Fail closed (silent) — don't block prompts because of a bad rules file.
    process.exit(0);
  }
}

function extractFilePaths(prompt) {
  const paths = new Set();
  const extensionPattern =
    /(?:^|\s|["'`])([\w\-./]+\.(?:[tj]sx?|json|gql|graphql|ya?ml|md|sh|py|sql|tf))\b/gi;
  let m;
  while ((m = extensionPattern.exec(prompt)) !== null) paths.add(m[1]);

  const dirPattern =
    /(?:^|\s|["'`])((?:src|app|pages|components|hooks|lib|server|api|aws-lambda|aws-migration|migrations|infra|terraform|\.claude|\.github)\/[\w\-./]+)/gi;
  while ((m = dirPattern.exec(prompt)) !== null) paths.add(m[1]);

  const quotedPattern = /["'`]([\w\-./]+\/[\w\-./]+)["'`]/g;
  while ((m = quotedPattern.exec(prompt)) !== null) paths.add(m[1]);

  return Array.from(paths);
}

function matchesPattern(text, pattern, flags = 'i') {
  try {
    return new RegExp(pattern, flags).test(text);
  } catch {
    return false;
  }
}

function matchesGlob(filePath, globPattern) {
  const r = globPattern
    .replace(/\./g, '\\.')
    .replace(/\*\*\//g, '<<DSS>>')
    .replace(/\*\*/g, '<<DS>>')
    .replace(/\*/g, '[^/]*')
    .replace(/<<DSS>>/g, '(.*\\/)?')
    .replace(/<<DS>>/g, '.*')
    .replace(/\?/g, '.');
  try {
    return new RegExp(`^${r}$`, 'i').test(filePath);
  } catch {
    return false;
  }
}

function matchDirectoryMapping(filePath, mappings) {
  for (const [dir, skill] of Object.entries(mappings)) {
    if (filePath === dir || filePath.startsWith(dir + '/')) return skill;
  }
  return null;
}

function evaluateSkill(name, skill, prompt, promptLower, filePaths, rules) {
  const { triggers = {}, excludePatterns = [], priority = 5 } = skill;
  const { scoring } = rules;
  let score = 0;
  const reasons = [];

  for (const ex of excludePatterns) {
    if (matchesPattern(promptLower, ex)) return null;
  }

  if (triggers.keywords) {
    for (const kw of triggers.keywords) {
      if (promptLower.includes(kw.toLowerCase())) {
        score += scoring.keyword;
        reasons.push(`keyword "${kw}"`);
      }
    }
  }

  if (triggers.keywordPatterns) {
    for (const pat of triggers.keywordPatterns) {
      if (matchesPattern(promptLower, pat)) {
        score += scoring.keywordPattern;
        reasons.push(`pattern /${pat}/`);
      }
    }
  }

  if (triggers.intentPatterns) {
    for (const pat of triggers.intentPatterns) {
      if (matchesPattern(promptLower, pat)) {
        score += scoring.intentPattern;
        reasons.push('intent detected');
        break;
      }
    }
  }

  if (triggers.contextPatterns) {
    for (const pat of triggers.contextPatterns) {
      if (promptLower.includes(pat.toLowerCase())) {
        score += scoring.contextPattern;
        reasons.push(`context "${pat}"`);
      }
    }
  }

  if (triggers.pathPatterns && filePaths.length > 0) {
    for (const fp of filePaths) {
      for (const pat of triggers.pathPatterns) {
        if (matchesGlob(fp, pat)) {
          score += scoring.pathPattern;
          reasons.push(`path "${fp}"`);
          break;
        }
      }
    }
  }

  if (rules.directoryMappings && filePaths.length > 0) {
    for (const fp of filePaths) {
      const mapped = matchDirectoryMapping(fp, rules.directoryMappings);
      if (mapped === name) {
        score += scoring.directoryMatch;
        reasons.push('directory mapping');
        break;
      }
    }
  }

  if (triggers.contentPatterns) {
    for (const pat of triggers.contentPatterns) {
      if (matchesPattern(prompt, pat)) {
        score += scoring.contentPattern;
        reasons.push('code pattern detected');
        break;
      }
    }
  }

  if (score > 0) {
    return { name, score, reasons: [...new Set(reasons)], priority };
  }
  return null;
}

function getRelatedSkills(matches, skills) {
  const matched = new Set(matches.map((m) => m.name));
  const related = new Set();
  for (const m of matches) {
    const s = skills[m.name];
    if (s?.relatedSkills) {
      for (const r of s.relatedSkills) {
        if (!matched.has(r)) related.add(r);
      }
    }
  }
  return Array.from(related);
}

function formatConfidence(score, minScore) {
  if (score >= minScore * 3) return 'HIGH';
  if (score >= minScore * 2) return 'MEDIUM';
  return 'LOW';
}

function evaluate(prompt) {
  const rules = loadRules();
  const { config, skills } = rules;
  const promptLower = prompt.toLowerCase();
  const filePaths = extractFilePaths(prompt);

  const matches = [];
  for (const [name, skill] of Object.entries(skills)) {
    const m = evaluateSkill(name, skill, prompt, promptLower, filePaths, rules);
    if (m && m.score >= config.minConfidenceScore) matches.push(m);
  }

  if (matches.length === 0) return '';

  matches.sort((a, b) =>
    b.score !== a.score ? b.score - a.score : b.priority - a.priority
  );
  const top = matches.slice(0, config.maxSkillsToShow);
  const related = getRelatedSkills(top, skills);

  let out = '<user-prompt-submit-hook>\n';
  out += 'SKILL SUGGESTIONS (from .claude/hooks/skill-rules.json)\n\n';
  if (filePaths.length > 0) {
    out += `Detected paths: ${filePaths.join(', ')}\n\n`;
  }
  out += 'Ranked by relevance:\n';
  for (let i = 0; i < top.length; i++) {
    const m = top[i];
    const conf = formatConfidence(m.score, config.minConfidenceScore);
    out += `${i + 1}. ${m.name} (${conf})`;
    if (config.showMatchReasons && m.reasons.length) {
      out += ` — ${m.reasons.slice(0, 3).join(', ')}`;
    }
    out += '\n';
  }
  if (related.length) {
    out += `\nRelated: ${related.join(', ')}\n`;
  }
  out += '\nBefore implementing: evaluate each suggested skill and invoke via the Skill tool if applicable.\n';
  out += '</user-prompt-submit-hook>';
  return out;
}

function main() {
  let input = '';
  process.stdin.setEncoding('utf8');
  process.stdin.on('data', (c) => (input += c));
  process.stdin.on('end', () => {
    let prompt = '';
    try {
      prompt = (JSON.parse(input).prompt) || '';
    } catch {
      prompt = input;
    }
    if (!prompt.trim()) process.exit(0);
    try {
      const out = evaluate(prompt);
      if (out) console.log(out);
    } catch {
      // never block the prompt because of a skill-eval bug
    }
    process.exit(0);
  });
}

main();
