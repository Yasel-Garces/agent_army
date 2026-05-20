#!/usr/bin/env bash
# auto-test-related.sh — PostToolUse hook on Edit|Write|MultiEdit.
# When a test file is edited, run just the related tests. Non-blocking — surfaces failures.

set -euo pipefail

file_path="${CLAUDE_TOOL_INPUT_FILE_PATH:-}"
[[ -z "$file_path" ]] && exit 0

# Only trigger when a test file itself was edited. (Editing source files is too noisy —
# the test runner would re-run on every keystroke equivalent.)
case "$file_path" in
  *.test.ts|*.test.tsx|*.test.js|*.test.jsx|*.spec.ts|*.spec.tsx) ;;
  test_*.py|*_test.py|tests/*) ;;
  *) exit 0 ;;
esac

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$project_dir" || exit 0

ext="${file_path##*.}"

case "$ext" in
  ts|tsx|js|jsx)
    if command -v npx >/dev/null 2>&1; then
      # Try vitest first (Next.js / modern stacks), then jest.
      if [[ -f "vitest.config.ts" || -f "vitest.config.js" || -f "vite.config.ts" ]]; then
        output="$(npx --no -- vitest run "$file_path" --reporter=basic 2>&1 || true)"
      else
        output="$(npx --no -- jest --findRelatedTests "$file_path" --passWithNoTests 2>&1 || true)"
      fi
      tail="$(echo "$output" | tail -10)"
      if echo "$output" | grep -q -E "(FAIL|✗|failed)"; then
        printf '{"feedback": "Tests failed:\\n%s"}\n' "$(echo "$tail" | sed 's/"/\\"/g' | tr '\n' ' ')" >&2
      else
        echo '{"feedback": "Tests passed.", "suppressOutput": true}'
      fi
    fi
    ;;
  py)
    if command -v pytest >/dev/null 2>&1 || (command -v uv >/dev/null 2>&1 && [[ -f "pyproject.toml" ]]); then
      cmd=(pytest "$file_path" -q)
      if command -v uv >/dev/null 2>&1; then
        cmd=(uv run pytest "$file_path" -q)
      fi
      output="$("${cmd[@]}" 2>&1 || true)"
      tail="$(echo "$output" | tail -10)"
      if echo "$output" | grep -q -E "(FAILED|failed)"; then
        printf '{"feedback": "pytest failed:\\n%s"}\n' "$(echo "$tail" | sed 's/"/\\"/g' | tr '\n' ' ')" >&2
      else
        echo '{"feedback": "pytest passed.", "suppressOutput": true}'
      fi
    fi
    ;;
esac

exit 0
