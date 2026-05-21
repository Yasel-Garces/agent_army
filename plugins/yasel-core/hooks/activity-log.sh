#!/usr/bin/env bash
# activity-log.sh — PostToolUse hook on every tool call.
# Appends a one-line timestamped record to .claude/logs/activity.log so a
# second terminal can `tail -f` it and watch what the agent is doing in real time.

set -euo pipefail

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
log_dir="${project_dir}/.claude/logs"
mkdir -p "$log_dir"
log_file="${log_dir}/activity.log"
state_file="${log_dir}/session-state.json"

tool="${CLAUDE_TOOL_NAME:-unknown}"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
epoch="$(date +%s)"

# Extract a tight summary of what the tool did. Tool-specific.
summary=""
case "$tool" in
  Read|Edit|Write|MultiEdit|NotebookEdit)
    summary="${CLAUDE_TOOL_INPUT_FILE_PATH:-?}"
    ;;
  Bash)
    cmd="${CLAUDE_TOOL_INPUT_COMMAND:-${CLAUDE_TOOL_INPUT:-?}}"
    summary="${cmd:0:120}"
    ;;
  Grep|Glob)
    summary="${CLAUDE_TOOL_INPUT_PATTERN:-${CLAUDE_TOOL_INPUT:-?}}"
    summary="${summary:0:120}"
    ;;
  mcp__*)
    server="${tool#mcp__}"; server="${server%%__*}"
    summary="server=$server"
    ;;
  Agent|Task*)
    summary="${CLAUDE_TOOL_INPUT_SUBAGENT_TYPE:-${CLAUDE_TOOL_INPUT:-?}}"
    summary="${summary:0:120}"
    ;;
  *)
    summary="${CLAUDE_TOOL_INPUT:-}"
    summary="${summary:0:120}"
    ;;
esac

# Sanitize newlines so each log line stays one line.
summary="$(printf '%s' "$summary" | tr '\n\r\t' '   ')"

printf '%s\t%s\t%s\n' "$ts" "$tool" "$summary" >> "$log_file"

# Update session-state.json (used by runtime-watchdog).
# Lightweight: first call writes the start epoch; every call updates last-seen.
if [[ ! -f "$state_file" ]]; then
  printf '{"start_epoch":%s,"last_epoch":%s,"tool_count":1}\n' "$epoch" "$epoch" > "$state_file"
else
  if command -v jq >/dev/null 2>&1; then
    tmp="$(mktemp)"
    jq --argjson e "$epoch" '.last_epoch=$e | .tool_count=(.tool_count // 0)+1' "$state_file" > "$tmp" && mv "$tmp" "$state_file"
  else
    # Fallback: rewrite the file naively.
    start="$(grep -oE '"start_epoch":[0-9]+' "$state_file" | head -1 | grep -oE '[0-9]+' || echo "$epoch")"
    count="$(grep -oE '"tool_count":[0-9]+' "$state_file" | head -1 | grep -oE '[0-9]+' || echo 0)"
    count=$((count + 1))
    printf '{"start_epoch":%s,"last_epoch":%s,"tool_count":%s}\n' "$start" "$epoch" "$count" > "$state_file"
  fi
fi

exit 0
