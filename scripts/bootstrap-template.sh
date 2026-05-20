#!/usr/bin/env bash
# bootstrap-template.sh — copy template/ from agent_army into the current repo.
# For use in GitHub Actions or scratch repos where the Claude Code plugin install isn't viable.

set -euo pipefail

# Default: clone to a temp dir, copy template/, clean up.
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

REPO_URL="${AGENT_ARMY_REPO_URL:-https://github.com/Yasel-Garces/agent_army.git}"
BRANCH="${AGENT_ARMY_BRANCH:-main}"

echo "Cloning agent_army (${BRANCH})..."
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TMPDIR/agent_army"

TARGET="$(pwd)"
SRC="$TMPDIR/agent_army/template"

echo "Copying template into $TARGET ..."

# Use rsync-like copy. Preserve directory structure.
copy_if_missing() {
  local src="$1"
  local dst="$2"
  if [[ -e "$dst" ]]; then
    echo "  skip (exists): $dst"
  else
    mkdir -p "$(dirname "$dst")"
    cp -r "$src" "$dst"
    echo "  added: $dst"
  fi
}

# .claude/
copy_if_missing "$SRC/.claude/knowledge" "$TARGET/.claude/knowledge"
copy_if_missing "$SRC/.claude/settings.json" "$TARGET/.claude/settings.json"
copy_if_missing "$SRC/.claude/settings.local.json.example" "$TARGET/.claude/settings.local.json.example"
copy_if_missing "$SRC/.claude/settings.unattended.json" "$TARGET/.claude/settings.unattended.json"

# .mcp.json
copy_if_missing "$SRC/.mcp.json" "$TARGET/.mcp.json"

# CLAUDE.md (only if no CLAUDE.md exists)
if [[ -e "$TARGET/CLAUDE.md" ]]; then
  echo "  skip (exists): $TARGET/CLAUDE.md"
else
  cp "$SRC/CLAUDE.md.template" "$TARGET/CLAUDE.md"
  echo "  added: $TARGET/CLAUDE.md (from template — edit it)"
fi

# .github/workflows
mkdir -p "$TARGET/.github/workflows"
for wf in "$SRC/.github/workflows/"*.yml; do
  copy_if_missing "$wf" "$TARGET/.github/workflows/$(basename "$wf")"
done

echo ""
echo "Done. Next steps:"
echo "  1. Edit CLAUDE.md and .claude/knowledge/* to fit this project."
echo "  2. Add ANTHROPIC_API_KEY to repo secrets for the workflows to run."
echo "  3. Commit + push."
