# agent_army

Canonical Claude Code configuration, packaged as a plugin marketplace. Install once per project, get the full kit.

## What you get

**Agents** — orchestrator + 9 specialists: `security-reviewer`, `data-compliance`, `data-engineer`, `implementer`, `code-reviewer`, `debugger`, `tester`, `docs-writer`, `github-workflow`.

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
