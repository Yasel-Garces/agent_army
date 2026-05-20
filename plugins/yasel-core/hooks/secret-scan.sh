#!/usr/bin/env bash
# secret-scan.sh — PreToolUse hook
#
# Fires before Edit/Write/MultiEdit. Scans the proposed content for secret-looking strings.
# Blocks the write if anything matches. Cheap regex pass — not a replacement for gitleaks/trufflehog.

set -euo pipefail

tool="${CLAUDE_TOOL_NAME:-}"
case "$tool" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

# Claude Code sets CLAUDE_TOOL_INPUT_CONTENT to the proposed new content.
# Fall back to reading the input file path if content isn't directly exposed.
content="${CLAUDE_TOOL_INPUT_CONTENT:-}"
if [[ -z "$content" && -n "${CLAUDE_TOOL_INPUT_FILE_PATH:-}" && -f "${CLAUDE_TOOL_INPUT_FILE_PATH}" ]]; then
  content="$(cat "${CLAUDE_TOOL_INPUT_FILE_PATH}")"
fi
[[ -z "$content" ]] && exit 0

# Patterns that almost always indicate a secret. Order matters — most specific first.
# Each pattern uses extended regex, anchored loosely.
declare -a PATTERNS=(
  # AWS
  'AKIA[0-9A-Z]{16}'
  'aws_secret_access_key\s*=\s*[A-Za-z0-9/+=]{40}'
  # GitHub
  'gh[ps]_[A-Za-z0-9]{36,}'
  'github_pat_[A-Za-z0-9_]{82}'
  # Stripe
  'sk_live_[A-Za-z0-9]{24,}'
  'rk_live_[A-Za-z0-9]{24,}'
  # OpenAI / Anthropic
  'sk-[A-Za-z0-9]{20,}'
  'sk-ant-[A-Za-z0-9_-]{20,}'
  # Slack
  'xox[abprs]-[A-Za-z0-9-]{10,}'
  # Google
  'AIza[0-9A-Za-z_-]{35}'
  # JWT (three base64url segments)
  'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
  # Generic high-entropy key=value (env-file style)
  '(API|SECRET|TOKEN|PASSWORD|PASSWD|PRIVATE_?KEY)[A-Z_]*\s*[:=]\s*["'"'"']?[A-Za-z0-9_+/=-]{24,}["'"'"']?'
  # Private key headers
  '-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----'
  # DB connection strings
  'postgres(ql)?://[^/[:space:]]+:[^@[:space:]]+@'
  'mongodb(\+srv)?://[^/[:space:]]+:[^@[:space:]]+@'
)

matched=""
for pat in "${PATTERNS[@]}"; do
  match="$(printf '%s' "$content" | grep -E -o -- "$pat" | head -1 || true)"
  if [[ -n "$match" ]]; then
    # Truncate the match for the message — don't echo a full secret back at the user.
    snippet="${match:0:8}…${match: -4}"
    matched="${matched}- pattern \`$pat\` → \`$snippet\`\n"
  fi
done

if [[ -n "$matched" ]]; then
  # Strip the trailing \n for clean JSON
  printf '{"block": true, "message": "Refusing to write content that looks like it contains secrets:\\n%s\\nIf this is a legitimate test fixture, use .env.example with obviously-fake values, or commit it through a different tool. If it is a real secret, move it to SSM/Secrets Manager and reference via env var."}\n' "$(printf '%b' "$matched" | sed 's/"/\\"/g' | tr '\n' ' ')" >&2
  exit 2
fi

exit 0
