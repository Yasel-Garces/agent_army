# agent_army (meta)

This is the source-of-truth repo for Yasel's Claude Code configuration. Other projects install from here via the plugin marketplace mechanism.

## When editing this repo

- The plugin **is** the product. Treat `plugins/yasel-core/` content with the same rigor you'd apply to library code.
- **Always bump `plugins/yasel-core/.claude-plugin/plugin.json#version` before pushing** if downstream repos should see the change. Without an explicit bump, every commit becomes a new version (per Claude Code plugin spec) — fine for trunk-following installs, dangerous for stable installs.
- `template/` mirrors a subset of `plugins/yasel-core/`. If you change a hook or settings file in the plugin, check whether `template/` needs the same change.
- `docs/SECURITY.md` (in the plugin) is the threat model. Update it whenever you change MCP tiers, the supervisor hook, or the permission policy.

## Workflow this repo enforces in *downstream* projects

(Documented here so anyone editing the plugin keeps the contract in mind.)

1. Downstream project runs `/init-knowledge` → `.claude/knowledge/` is scaffolded.
2. Downstream project runs `/onboard-agent` → agent reads KB, reports understanding.
3. Only after that does `/ship` accept work. The `require-knowledge.sh` PreToolUse hook blocks dev actions until `.claude/knowledge/scope.md` exists.

## Versioning

`0.1.0` is the initial v1. Semver: bump minor for new agents/commands/skills, patch for fixes, major when changing the public surface (renaming commands, removing agents, breaking hook contracts).

## Don't commit

- `.claude/settings.local.json` (gitignored, session-local)
- `plugins/yasel-core/logs/` (MCP audit logs, runtime artifact)
- Anything that smells like a secret
