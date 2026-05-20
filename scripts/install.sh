#!/usr/bin/env bash
# install.sh — print the install snippet for a target repo.
# This script doesn't actually run /plugin commands (only Claude Code can).
# It prints a copy-paste snippet you run *inside* a Claude Code session in your target repo.

set -euo pipefail

cat <<'EOF'
agent_army install — paste these into Claude Code inside your target repo:

  /plugin marketplace add Yasel-Garces/agent_army
  /plugin install yasel-core@agent-army

Then bootstrap the project:

  /init-knowledge
  # fill in .claude/knowledge/scope.md and data-model.md (minimum)
  /onboard-agent
  # confirm the agent has context

You're ready:

  /ship "your first task"

For non-Claude-Code contexts (CI runners, scratch repos without a session), use:

  curl -sSfL https://raw.githubusercontent.com/Yasel-Garces/agent_army/main/scripts/bootstrap-template.sh | bash

That copies the template/ contents into the current repo for use by GitHub Actions.
EOF
