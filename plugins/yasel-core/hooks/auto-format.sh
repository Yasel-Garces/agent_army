#!/usr/bin/env bash
# auto-format.sh — PostToolUse hook on Edit|Write|MultiEdit.
# Auto-formats the just-edited file. Stack-detects JS/TS (prettier or biome) vs Python (ruff).
# Non-blocking — formatting failure surfaces feedback but doesn't undo the edit.

set -euo pipefail

file_path="${CLAUDE_TOOL_INPUT_FILE_PATH:-}"
[[ -z "$file_path" || ! -f "$file_path" ]] && exit 0

ext="${file_path##*.}"

case "$ext" in
  ts|tsx|js|jsx|mjs|cjs|json|md|yaml|yml|css|scss)
    if command -v biome >/dev/null 2>&1 && [[ -f "biome.json" || -f "biome.jsonc" ]]; then
      biome format --write "$file_path" >/dev/null 2>&1 && \
        echo '{"feedback": "Formatted with Biome.", "suppressOutput": true}' || \
        echo '{"feedback": "Biome formatting failed — check syntax."}' >&2
    elif command -v npx >/dev/null 2>&1; then
      npx --no -- prettier --write "$file_path" >/dev/null 2>&1 && \
        echo '{"feedback": "Formatted with Prettier.", "suppressOutput": true}' || \
        echo '{"feedback": "Prettier formatting failed — check syntax."}' >&2
    fi
    ;;
  py)
    if command -v ruff >/dev/null 2>&1; then
      ruff format "$file_path" >/dev/null 2>&1 && \
      ruff check --fix --select I "$file_path" >/dev/null 2>&1 && \
        echo '{"feedback": "Formatted + imports sorted with Ruff.", "suppressOutput": true}' || \
        echo '{"feedback": "Ruff formatting failed — check syntax."}' >&2
    fi
    ;;
  *)
    ;;
esac

exit 0
