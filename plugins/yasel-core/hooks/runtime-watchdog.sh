#!/usr/bin/env bash
# runtime-watchdog.sh — PreToolUse hook on every tool call.
# Reads .claude/logs/session-state.json (maintained by activity-log.sh) and emits
# a non-blocking warning to stderr when a session exceeds soft / hard time limits.
#
# This DOES NOT kill the session — it can't, and shouldn't (you may legitimately
# want a long-running task). It loudly notifies, so a runaway is visible in the
# transcript and `tail -f`-able from another terminal.

set -euo pipefail

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
state_file="${project_dir}/.claude/logs/session-state.json"
[[ -f "$state_file" ]] || exit 0

# Soft + hard limits in seconds. Override per-project via env vars.
SOFT="${CLAUDE_SESSION_SOFT_LIMIT:-1800}"   # 30 min
HARD="${CLAUDE_SESSION_HARD_LIMIT:-3600}"   # 60 min

# Optional token budget (in tokens). When set, warn at soft/hard thresholds.
# Default unset → no token warnings.
TOKEN_SOFT="${CLAUDE_TOKEN_SOFT_LIMIT:-0}"
TOKEN_HARD="${CLAUDE_TOKEN_HARD_LIMIT:-0}"

now="$(date +%s)"

if command -v jq >/dev/null 2>&1; then
  start="$(jq -r '.start_epoch' "$state_file" 2>/dev/null || echo "$now")"
  tool_count="$(jq -r '.tool_count' "$state_file" 2>/dev/null || echo 0)"
  warned_soft="$(jq -r '.warned_soft // false' "$state_file" 2>/dev/null || echo false)"
  warned_hard="$(jq -r '.warned_hard // false' "$state_file" 2>/dev/null || echo false)"
  tokens_total="$(jq -r '(.tokens_in_total // 0) + (.tokens_out_total // 0)' "$state_file" 2>/dev/null || echo 0)"
  warned_tokens_soft="$(jq -r '.warned_tokens_soft // false' "$state_file" 2>/dev/null || echo false)"
  warned_tokens_hard="$(jq -r '.warned_tokens_hard // false' "$state_file" 2>/dev/null || echo false)"
else
  start="$(grep -oE '"start_epoch":[0-9]+' "$state_file" | head -1 | grep -oE '[0-9]+' || echo "$now")"
  tool_count="$(grep -oE '"tool_count":[0-9]+' "$state_file" | head -1 | grep -oE '[0-9]+' || echo 0)"
  warned_soft="false"
  warned_hard="false"
  tokens_total=0
  warned_tokens_soft="false"
  warned_tokens_hard="false"
fi

elapsed=$(( now - start ))

mark_warned() {
  local field="$1"
  if command -v jq >/dev/null 2>&1; then
    tmp="$(mktemp)"
    jq --arg f "$field" '.[$f]=true' "$state_file" > "$tmp" && mv "$tmp" "$state_file"
  fi
}

if (( elapsed >= HARD )) && [[ "$warned_hard" != "true" ]]; then
  cat >&2 <<EOF
{"feedback": "RUNTIME WATCHDOG (hard limit hit): this session has been running for ${elapsed}s (limit ${HARD}s) across ${tool_count} tool calls. If you didn't expect a long-running task, the orchestrator may be stuck — interrupt (Esc / Ctrl+C) and run /status to inspect. Set CLAUDE_SESSION_HARD_LIMIT to raise the limit if this is intentional."}
EOF
  mark_warned "warned_hard"
elif (( elapsed >= SOFT )) && [[ "$warned_soft" != "true" ]]; then
  cat >&2 <<EOF
{"feedback": "RUNTIME WATCHDOG (soft limit hit): this session has been running for ${elapsed}s across ${tool_count} tool calls. Heads up — if you don't expect a long-running task, check progress (/status or tail -f .claude/logs/activity.log)."}
EOF
  mark_warned "warned_soft"
fi

# Token-based warnings (only when a budget is set).
if (( TOKEN_HARD > 0 )) && (( tokens_total >= TOKEN_HARD )) && [[ "$warned_tokens_hard" != "true" ]]; then
  cat >&2 <<EOF
{"feedback": "TOKEN WATCHDOG (hard limit hit): this session has used ~${tokens_total} tokens (limit ${TOKEN_HARD}). Run /tokens for the breakdown. Consider compacting, splitting the task, or raising CLAUDE_TOKEN_HARD_LIMIT."}
EOF
  mark_warned "warned_tokens_hard"
elif (( TOKEN_SOFT > 0 )) && (( tokens_total >= TOKEN_SOFT )) && [[ "$warned_tokens_soft" != "true" ]]; then
  cat >&2 <<EOF
{"feedback": "TOKEN WATCHDOG (soft limit hit): this session has used ~${tokens_total} tokens (soft limit ${TOKEN_SOFT}). Run /tokens for the breakdown."}
EOF
  mark_warned "warned_tokens_soft"
fi

# Stuck detection: same exact tool + same args called many times in a row is a smell.
# We use activity.log's last 5 lines and check whether they're identical.
log_file="${project_dir}/.claude/logs/activity.log"
if [[ -f "$log_file" ]]; then
  last5="$(tail -5 "$log_file" | awk -F'\t' '{print $2 "\t" $3}' | sort -u | wc -l | tr -d ' ')"
  if [[ "$last5" == "1" && "$tool_count" -gt 5 ]]; then
    cat >&2 <<EOF
{"feedback": "WATCHDOG: the last 5 tool calls were identical. Possible loop — consider interrupting and inspecting via /status."}
EOF
  fi
fi

exit 0
