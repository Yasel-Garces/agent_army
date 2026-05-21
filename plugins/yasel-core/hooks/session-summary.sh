#!/usr/bin/env bash
# session-summary.sh — Stop hook.
# When the session ends, append a one-line summary to .claude/logs/sessions.log
# and clear session-state.json so the next session starts fresh.

set -euo pipefail

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
log_dir="${project_dir}/.claude/logs"
mkdir -p "$log_dir"

activity_log="${log_dir}/activity.log"
state_file="${log_dir}/session-state.json"
sessions_log="${log_dir}/sessions.log"

end_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
end_epoch="$(date +%s)"

start_epoch="$end_epoch"
tool_count=0

if [[ -f "$state_file" ]]; then
  if command -v jq >/dev/null 2>&1; then
    start_epoch="$(jq -r '.start_epoch' "$state_file" 2>/dev/null || echo "$end_epoch")"
    tool_count="$(jq -r '.tool_count' "$state_file" 2>/dev/null || echo 0)"
  else
    start_epoch="$(grep -oE '"start_epoch":[0-9]+' "$state_file" | head -1 | grep -oE '[0-9]+' || echo "$end_epoch")"
    tool_count="$(grep -oE '"tool_count":[0-9]+' "$state_file" | head -1 | grep -oE '[0-9]+' || echo 0)"
  fi
fi

duration=$(( end_epoch - start_epoch ))
start_ts="$(date -u -r "$start_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$start_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "$end_ts")"

# Files touched: extract unique paths from activity.log lines that look like edits/writes.
files_touched=0
if [[ -f "$activity_log" ]]; then
  files_touched="$(awk -F'\t' '$2 ~ /^(Edit|Write|MultiEdit|NotebookEdit)$/ {print $3}' "$activity_log" | sort -u | wc -l | tr -d ' ')"
fi

# Last 3 lines from activity log as a quick fingerprint of what was happening.
last3=""
if [[ -f "$activity_log" ]]; then
  last3="$(tail -3 "$activity_log" | awk -F'\t' '{printf "%s(%s)|", $2, substr($3,1,40)}' | sed 's/|$//' )"
fi

printf '%s\tstart=%s\tdur=%ss\ttools=%s\tfiles=%s\tlast=%s\n' \
  "$end_ts" "$start_ts" "$duration" "$tool_count" "$files_touched" "$last3" \
  >> "$sessions_log"

# Reset session state so the next session starts a fresh timer.
rm -f "$state_file"

exit 0
