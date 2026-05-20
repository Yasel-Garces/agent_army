#!/usr/bin/env bash
# auto-typecheck.sh — PostToolUse hook on Edit|Write|MultiEdit.
# Non-blocking type check for TypeScript or Python files.
# Surfaces the first few errors so the agent can self-correct on next turn.

set -euo pipefail

file_path="${CLAUDE_TOOL_INPUT_FILE_PATH:-}"
[[ -z "$file_path" ]] && exit 0

ext="${file_path##*.}"
project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$project_dir" || exit 0

case "$ext" in
  ts|tsx)
    if [[ -f "tsconfig.json" ]] && command -v npx >/dev/null 2>&1; then
      output="$(npx --no -- tsc --noEmit 2>&1 || true)"
      if echo "$output" | grep -q "error TS"; then
        errors="$(echo "$output" | grep -A 1 "error TS" | head -20)"
        printf '{"feedback": "TypeScript errors detected:\\n%s"}\n' "$(echo "$errors" | sed 's/"/\\"/g' | tr '\n' ' ')" >&2
      else
        echo '{"feedback": "Typecheck clean.", "suppressOutput": true}'
      fi
    fi
    ;;
  py)
    if command -v mypy >/dev/null 2>&1 && [[ -f "pyproject.toml" || -f "mypy.ini" ]]; then
      output="$(mypy "$file_path" 2>&1 || true)"
      if echo "$output" | grep -q "error:"; then
        errors="$(echo "$output" | grep "error:" | head -10)"
        printf '{"feedback": "mypy errors:\\n%s"}\n' "$(echo "$errors" | sed 's/"/\\"/g' | tr '\n' ' ')" >&2
      else
        echo '{"feedback": "mypy clean.", "suppressOutput": true}'
      fi
    fi
    ;;
esac

exit 0
