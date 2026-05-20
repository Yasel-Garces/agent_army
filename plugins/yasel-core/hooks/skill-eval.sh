#!/usr/bin/env bash
# skill-eval.sh — UserPromptSubmit hook wrapper.
# Delegates to skill-eval.js for the actual matching logic.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_SCRIPT="$SCRIPT_DIR/skill-eval.js"

if ! command -v node >/dev/null 2>&1; then
  # Node not installed — silently skip so we don't block the prompt.
  exit 0
fi

if [[ ! -f "$NODE_SCRIPT" ]]; then
  exit 0
fi

# Pipe stdin (the prompt payload from Claude Code) into the JS engine.
cat | node "$NODE_SCRIPT" 2>/dev/null

exit 0
