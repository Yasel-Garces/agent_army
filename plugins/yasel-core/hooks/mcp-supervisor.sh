#!/usr/bin/env bash
# mcp-supervisor.sh — PreToolUse hook
#
# Fires before any mcp__* tool call. Three jobs:
#   1. Append an audit log entry of every MCP call (server, tool, args summary).
#   2. PII egress guard: scan args for email/phone/CC/SSN going to non-memory servers; block.
#   3. Postgres write-statement guard: block INSERT/UPDATE/DELETE/DROP/TRUNCATE/ALTER/GRANT
#      unless MCP_POSTGRES_ALLOW_WRITES=1 is set in the session env.

set -euo pipefail

tool="${CLAUDE_TOOL_NAME:-}"
# Only act on MCP tool calls.
[[ "$tool" == mcp__* ]] || exit 0

# Extract the MCP server name from the tool name. Convention: mcp__<server>__<toolname>.
server="${tool#mcp__}"
server="${server%%__*}"

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
log_dir="${project_dir}/.claude/logs"
mkdir -p "$log_dir"
log_file="${log_dir}/mcp-audit.log"

# Args summary — Claude Code passes the tool input as JSON in CLAUDE_TOOL_INPUT.
args="${CLAUDE_TOOL_INPUT:-}"
# Truncate for the log line (avoid logging full payloads which may contain PII themselves).
args_summary="${args:0:200}"

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '%s\t%s\t%s\t%s\n' "$ts" "$server" "$tool" "$args_summary" >> "$log_file"

# --- PII egress guard ----------------------------------------------------------
# Local-only servers don't need PII scanning.
case "$server" in
  memory|filesystem) ;;
  *)
    # Patterns for the most common PII we care about. Tuned for low false-positive rate
    # in normal code/SQL — not perfect.
    declare -a PII=(
      # Email
      '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
      # US SSN
      '\b[0-9]{3}-[0-9]{2}-[0-9]{4}\b'
      # Credit card (13-19 digits, possibly spaced/dashed). False-positive risk —
      # we additionally require a leading 'card', 'cc', 'pan' nearby to lower noise.
      '(card|cc|pan|credit)[^A-Za-z0-9]{0,8}[0-9]{4}[ -]?[0-9]{4}[ -]?[0-9]{4}[ -]?[0-9]{1,4}'
      # E.164 phone
      '\+[1-9][0-9]{7,14}\b'
    )
    for pat in "${PII[@]}"; do
      if printf '%s' "$args" | grep -E -i -q "$pat"; then
        cat >&2 <<EOF
{"block": true, "message": "PII egress guard: tool '${tool}' is being called with an argument that matches a PII pattern (\`${pat}\`). Server '${server}' is external — refusing to send PII. Either redact the argument, scope the call to opaque IDs, or set the override env var if this is intentional and you've reviewed the data flow."}
EOF
        exit 2
      fi
    done
    ;;
esac

# --- Postgres write-statement guard --------------------------------------------
if [[ "$server" == "postgres" ]]; then
  if [[ "${MCP_POSTGRES_ALLOW_WRITES:-0}" != "1" ]]; then
    # Look at the args (SQL is usually in a `sql` or `query` field).
    if printf '%s' "$args" | grep -E -i -q '\b(INSERT|UPDATE|DELETE|DROP|TRUNCATE|ALTER|GRANT|REVOKE|CREATE)\b'; then
      cat >&2 <<EOF
{"block": true, "message": "Postgres MCP is read-only by default. Detected write-class SQL (INSERT/UPDATE/DELETE/DROP/TRUNCATE/ALTER/GRANT/REVOKE/CREATE). To allow writes for this session, set MCP_POSTGRES_ALLOW_WRITES=1 in the shell that started Claude Code, then restart. See plugins/yasel-core/docs/SECURITY.md."}
EOF
      exit 2
    fi
  fi
fi

exit 0
