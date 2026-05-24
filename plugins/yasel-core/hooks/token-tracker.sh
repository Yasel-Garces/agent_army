#!/usr/bin/env bash
# token-tracker.sh — PostToolUse hook.
#
# Captures per-tool-call cost estimates. Writes one JSON object per line to
# .claude/logs/tokens.jsonl so /tokens can aggregate them later.
#
# Honest caveat: Claude Code does not (yet) reliably expose per-tool token
# counts to hooks. We capture what we can: byte length of the tool input as a
# rough proxy (~4 chars per token for English/code), plus tool name and time.
# If future Claude Code releases set CLAUDE_TOKENS_IN / CLAUDE_TOKENS_OUT
# env vars on hook invocation, we'll prefer those (see the env block below).

set -euo pipefail

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
log_dir="${project_dir}/.claude/logs"
mkdir -p "$log_dir"
log_file="${log_dir}/tokens.jsonl"

tool="${CLAUDE_TOOL_NAME:-unknown}"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
epoch="$(date +%s)"

# Byte-length of the tool input as a proxy. Prefer specific fields when set,
# fall back to the full CLAUDE_TOOL_INPUT JSON blob.
input_blob="${CLAUDE_TOOL_INPUT_COMMAND:-${CLAUDE_TOOL_INPUT_PATTERN:-${CLAUDE_TOOL_INPUT_CONTENT:-${CLAUDE_TOOL_INPUT:-}}}}"
input_bytes="${#input_blob}"

# Output-side: in PostToolUse, Claude Code may set CLAUDE_TOOL_OUTPUT.
output_blob="${CLAUDE_TOOL_OUTPUT:-}"
output_bytes="${#output_blob}"

# Prefer real token counts if Claude Code ever exposes them. None of these
# are guaranteed today; the assignments are no-ops when the vars are unset.
tokens_in="${CLAUDE_TOKENS_IN:-${CLAUDE_INPUT_TOKENS:-}}"
tokens_out="${CLAUDE_TOKENS_OUT:-${CLAUDE_OUTPUT_TOKENS:-}}"
tokens_cache="${CLAUDE_TOKENS_CACHE:-${CLAUDE_CACHE_READ_TOKENS:-}}"

# Estimate when real counts aren't available. 4 chars/token is a common rough
# average for English + code mixes. Underestimates code with lots of symbols.
if [[ -z "$tokens_in" ]]; then
  tokens_in_est=$(( (input_bytes + 3) / 4 ))
else
  tokens_in_est="$tokens_in"
fi
if [[ -z "$tokens_out" ]]; then
  tokens_out_est=$(( (output_bytes + 3) / 4 ))
else
  tokens_out_est="$tokens_out"
fi

# Sanitize tool name for JSON.
tool_safe="${tool//\"/}"
tool_safe="${tool_safe//\\/}"

# Build a single-line JSON record.
record="$(printf '{"ts":"%s","epoch":%s,"tool":"%s","input_bytes":%s,"output_bytes":%s,"tokens_in":%s,"tokens_out":%s,"is_estimate":%s}' \
  "$ts" "$epoch" "$tool_safe" "$input_bytes" "$output_bytes" "$tokens_in_est" "$tokens_out_est" \
  "$([[ -z "$tokens_in" && -z "$tokens_out" ]] && echo true || echo false)")"

# Optional cache field if present.
if [[ -n "$tokens_cache" ]]; then
  record="${record%\}},\"tokens_cache\":${tokens_cache}}"
fi

printf '%s\n' "$record" >> "$log_file"

# Update session-level rolling totals in session-state.json for the watchdog.
state_file="${log_dir}/session-state.json"
if [[ -f "$state_file" ]] && command -v jq >/dev/null 2>&1; then
  tmp="$(mktemp)"
  jq --argjson tin "$tokens_in_est" --argjson tout "$tokens_out_est" \
    '.tokens_in_total=((.tokens_in_total // 0) + $tin) | .tokens_out_total=((.tokens_out_total // 0) + $tout)' \
    "$state_file" > "$tmp" && mv "$tmp" "$state_file"
fi

exit 0
