#!/usr/bin/env bash
# block-main-edits.sh — PreToolUse hook on Edit|Write|MultiEdit.
# Refuses file edits when the current branch is main (or master).

set -euo pipefail

tool="${CLAUDE_TOOL_NAME:-}"
case "$tool" in
  Edit|Write|MultiEdit|NotebookEdit) ;;
  *) exit 0 ;;
esac

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$project_dir" || exit 0

# Only act inside a git repo.
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

branch="$(git branch --show-current 2>/dev/null || echo '')"

if [[ "$branch" == "main" || "$branch" == "master" ]]; then
  cat >&2 <<EOF
{"block": true, "message": "Refusing to ${tool} on branch '${branch}'. Create a feature branch first: git checkout -b yg/<description>. This protects the default branch from accidental commits."}
EOF
  exit 2
fi

exit 0
