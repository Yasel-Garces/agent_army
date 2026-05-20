---
description: Check if documentation (README, /docs, CLAUDE.md, .claude/knowledge/*) is in sync with recent code changes. Reports only actual mismatches.
allowed-tools: Read, Glob, Grep, Bash(git:*)
---

# /docs-sync

Audit docs against recent code changes.

## Your steps

1. **Find recent code changes:**
   ```bash
   git log --since="30 days ago" --name-only --pretty=format: -- "*.ts" "*.tsx" "*.js" "*.jsx" "*.py" "*.sql" | sort -u
   ```

2. **Find candidate docs to check:**
   - `README.md`, `README.md` in subdirs
   - `/docs/**`
   - `CLAUDE.md`, `CLAUDE.local.md`
   - `.claude/knowledge/*.md` — especially `architecture.md`, `data-model.md`, `glossary.md`
   - Doc comments inside changed files

3. **Verify:**
   - Do code examples in docs still compile / run?
   - Do API signatures in docs match the current code?
   - Does `data-model.md` reflect new schemas / migrations?
   - Does `architecture.md` reflect new services / data flows?
   - Does the README's quickstart still work?

4. **Report only what's actually wrong.** Docs are living documents; missing-but-not-wrong is fine. Wrong-and-misleading is what we care about.

5. **Output:** a checklist of doc updates needed, each with the source-of-truth file + line and the doc file + line.
