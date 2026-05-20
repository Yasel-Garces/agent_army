#!/usr/bin/env bash
# require-knowledge.sh — PreToolUse hook
#
# Blocks development-flavored tool calls in any project that hasn't run /init-knowledge yet.
# Specifically: refuses Edit/Write/MultiEdit and mcp__postgres__* tools when
# .claude/knowledge/scope.md is missing. Read/Grep/Glob are allowed (the agent needs to
# explore to onboard).
#
# The intent: every project Yasel deploys this plugin into must have a knowledge base
# (scope, context, data-model) before any code change happens. See [[feedback-plan-first-with-kb]].

set -euo pipefail

# CLAUDE_TOOL_NAME is set by Claude Code for every hook invocation.
tool="${CLAUDE_TOOL_NAME:-}"

# Tools that count as "development actions" — block these if KB is missing.
case "$tool" in
  Edit|Write|MultiEdit|NotebookEdit) ;;
  mcp__postgres__*) ;;
  *)
    # Anything else (Read, Grep, Glob, Bash exploration, etc.) — let it through.
    exit 0
    ;;
esac

# Look for the KB in the current project. CLAUDE_PROJECT_DIR is set by Claude Code.
project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
kb_scope="${project_dir}/.claude/knowledge/scope.md"

if [[ -f "$kb_scope" ]]; then
  # KB exists. Also check that scope.md no longer contains the TODO banner — that means
  # the user has actually filled it in, not just scaffolded it.
  if grep -q '\[TODO: replace this banner' "$kb_scope" 2>/dev/null; then
    cat >&2 <<EOF
{
  "block": true,
  "message": "Knowledge base exists but scope.md still contains the [TODO: replace this banner ...] marker. Fill in .claude/knowledge/scope.md and .claude/knowledge/data-model.md before proceeding. The security-reviewer and data-compliance agents read these files."
}
EOF
    exit 2
  fi
  exit 0
fi

cat >&2 <<EOF
{
  "block": true,
  "message": "This project has no .claude/knowledge/ directory. Run /init-knowledge to scaffold it, then /onboard-agent to confirm context, before making code changes. See plugins/yasel-core/commands/init-knowledge.md for what the KB contains and why."
}
EOF
exit 2
