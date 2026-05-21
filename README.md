# agent_army

Canonical Claude Code configuration, packaged as a plugin marketplace. Install once per project, get the full kit.

## What you get

**Agents** — orchestrator + 10 specialists: `security-reviewer`, `data-compliance`, `data-engineer`, `design-reviewer`, `implementer`, `code-reviewer`, `debugger`, `tester`, `docs-writer`, `github-workflow`.

**Workflow** — plan-first, knowledge-grounded, security-gated:
1. `/init-knowledge` scaffolds `.claude/knowledge/` (scope, context, architecture, data-model, glossary, ADRs).
2. `/onboard-agent` reads the KB + repo, reports understanding, asks gaps. Iterate until aligned.
3. `/ship "task"` runs the orchestrator: plan → user approves → implementer → security + compliance review (mandatory gate) → code review → tests → commit → PR.

**Autopilot** — asymmetric on purpose:
- Aggressive on **code edits** (file edits don't prompt; broad Bash allowlist for build/test/git).
- Restrictive on **data egress** (MCP servers tiered by trust; Postgres write-blocked by default; PII egress hook; `.env*` writes denied).

## Install in any project

Inside Claude Code:

```
/plugin marketplace add Yasel-Garces/agent_army
/plugin install yasel-core@agent_army
```

Then in that project:

```
/init-knowledge      # scaffold .claude/knowledge/
# fill in scope.md, context.md, data-model.md, etc.
/onboard-agent       # confirm the agent understands the project
/ship "your task"    # off to the races
```

## Commands

11 slash commands ship with `yasel-core`. Grouped by purpose:

### Setup (run once per project)

| Command | What it does |
|---|---|
| `/init-knowledge` | Scaffolds `.claude/knowledge/` skeleton. Edit `scope.md` + `data-model.md` after. |
| `/onboard-agent` | Agent reads KB + repo, reports "what I understand," asks gap questions. Confirms grounding before `/ship`. |
| `/update-knowledge` | Standalone KB update. Run with no args after a chat to mine the conversation for decisions, or pass a direct description (`/update-knowledge "we chose X over Y"`). Agent drafts edits, flags conflicts, applies on approval. |

### Doing work

| Command | What it does |
|---|---|
| `/discuss "rough idea"` | **Conversational refinement.** Use when you don't yet know exactly what you want. Agent asks clarifying questions, surfaces trade-offs, suggests alternatives. When you say "ready," it hands off to `/ship`. |
| `/ship "task"` | End-to-end: plan → user approves → implementer → security + compliance gate → code review → test → commit → PR. **The workhorse.** Use when the task is already concrete. |
| `/ticket ENG-123` | Same as `/ship` but starts by reading a Linear ticket and updates it on PR open. |
| `/design-import "<source>"` | Translate a design (claude.ai/design URL, pasted JSX, screenshot, reference component) into production code. Maps tokens, swaps in shadcn primitives, adds missing interactive states. Runs through the full chain including design-reviewer. |

### Auditing / reviewing

| Command | What it does |
|---|---|
| `/security-audit` | Repo-wide PII + OWASP + secrets sweep. Runs gitleaks, dep CVE scan, optionally files Linear tickets for findings. |
| `/pr-review <PR#>` | Runs security-reviewer + data-compliance + code-reviewer on an existing PR; posts a structured comment. |
| `/code-quality <dir>` | Lint + typecheck + manual smell check on a directory. Reports by severity. |
| `/docs-sync` | Checks if README / `/docs/` / `.claude/knowledge/` match recent code changes. Surfaces actual mismatches only. |

### Exploration (read-only, no edits)

| Command | What it does |
|---|---|
| `/deep-dive <area>` | Dispatches Explore subagents in parallel to map a codebase area. Output: structure + data flow + smells. Use before a refactor. |
| `/onboard "task"` | **Per-task** onboarding (vs. `/onboard-agent` which is per-project). Heavy exploration + writes `.claude/tasks/<id>/onboarding.md`. Use before deciding to `/ship`. |

### Monitoring

| Command | What it does |
|---|---|
| `/status` | Human-readable snapshot: active session activity, last session summary, uncommitted changes, recent commits, open PRs, recent MCP calls. Read-only — safe to run in a second terminal while a long task is in progress. |

Plus, in any shell:

```bash
tail -f .claude/logs/activity.log    # real-time tool-by-tool progress
cat .claude/logs/sessions.log        # session history
```

The plugin now also includes a **runtime watchdog** that warns at 30 min (soft) and 60 min (hard) of session time, and detects stuck-loop patterns (5 identical tool calls in a row). Override with `CLAUDE_SESSION_SOFT_LIMIT` / `CLAUDE_SESSION_HARD_LIMIT` env vars (seconds).

### Generating

| Command | What it does |
|---|---|
| `/pr-summary` | Reads `git diff` against `main`, generates a PR title + body. Use when you've committed manually and just need the description. |

### Quick decision tree

- **Want to ship code** → `/ship` (or `/ticket` if Linear)
- **Want to understand code** → `/deep-dive`
- **Want a security check** → `/security-audit`
- **Reviewing someone else's PR** → `/pr-review`
- **Just need a PR description** → `/pr-summary`
- **Suspect docs are stale** → `/docs-sync`
- **Auditing a specific area** → `/code-quality <dir>`

The setup commands (`/init-knowledge`, `/onboard-agent`) you forget about after each project's first day. The rest you use as needed.

## Update

When this repo bumps `plugins/yasel-core/.claude-plugin/plugin.json`:

```
/plugin update yasel-core
```

## Layout

```
agent_army/
├── .claude-plugin/marketplace.json    # catalog
├── plugins/yasel-core/                # the plugin (agents, commands, skills, hooks, .mcp.json, settings.json)
├── template/                          # non-plugin copy-paste fallback (used by GitHub Actions)
└── scripts/                           # install + bootstrap helpers
```

## Threat model

See `plugins/yasel-core/docs/SECURITY.md` for the MCP trust tiers and prompt-injection mitigations.

## License

MIT.
