#!/usr/bin/env bash
# env-file-guard.sh — PreToolUse hook
#
# Refuses Read/Edit/Write/MultiEdit on sensitive credential files regardless of permission mode.
# Defense in depth: deny-list in settings.json catches most, this catches the rest.

set -euo pipefail

tool="${CLAUDE_TOOL_NAME:-}"
path="${CLAUDE_TOOL_INPUT_FILE_PATH:-}"

case "$tool" in
  Read|Edit|Write|MultiEdit|NotebookEdit) ;;
  *) exit 0 ;;
esac

[[ -z "$path" ]] && exit 0

# Normalize: only check the basename + any "secrets" segment in the path.
base="$(basename "$path")"

# Files we refuse to even read. Reading is the issue — once content is in Claude's context,
# it can be smuggled to an MCP call.
refuse=0
case "$base" in
  .env|.env.*|*.env) refuse=1 ;;
  *.pem|*.key|*.p12|*.pfx|*.jks) refuse=1 ;;
  credentials|credentials.*|aws-credentials|gcp-credentials*) refuse=1 ;;
  id_rsa|id_ed25519|id_ecdsa|id_dsa) refuse=1 ;;
  *service-account*.json) refuse=1 ;;
esac

# Path-based: anything under a directory named "secrets" or "credentials".
if [[ "$path" == *"/secrets/"* ]] || [[ "$path" == *"/credentials/"* ]] || [[ "$path" == *"/private/"* ]]; then
  refuse=1
fi

# Exception: .env.example is a documented public template.
if [[ "$base" == ".env.example" || "$base" == "env.example" ]]; then
  refuse=0
fi

if [[ "$refuse" -eq 1 ]]; then
  cat >&2 <<EOF
{"block": true, "message": "Refusing to ${tool} on '${path}' — looks like a credential file. Read .env.example if you need a template. If you genuinely need to inspect this file, do it outside Claude Code so the contents don't enter the agent's context (where they could leak via MCP)."}
EOF
  exit 2
fi

exit 0
