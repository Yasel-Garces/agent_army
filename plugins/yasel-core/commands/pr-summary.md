---
description: Generate a PR summary + body for the current branch's changes against main.
allowed-tools: Bash(git:*), Read, Grep
---

# /pr-summary

Produce a PR title + body for the current branch's changes against `main`.

## Your steps

1. **Determine base + diff:**
   ```bash
   base=$(git merge-base HEAD main 2>/dev/null || echo main)
   git log "$base"..HEAD --oneline
   git diff --stat "$base"...HEAD
   git diff "$base"...HEAD
   ```

2. **Synthesize:**
   - **Title:** conventional-commit format. 70 chars max. Scope from the most-touched module.
   - **Summary:** 1-3 bullets on *why* (the user-visible outcome), not *what* (the diff already shows that).
   - **Test plan:** specific things to verify, not generic checklist.
   - **Linked tickets:** scan commits for Linear IDs (`ENG-\d+`, `[A-Z]+-\d+`).
   - **Security / compliance:** mark as "pending automated review" — the actual verdicts come from `/pr-review`.

3. **Output the title and body** ready to paste into `gh pr create`:

   ```
   --title "feat(...): ..."
   --body "$(cat <<'EOF'
   ## Summary
   - ...

   ## Test plan
   - [ ] ...

   ## Linked tickets
   - ...

   ## Security / compliance
   - pending automated review
   EOF
   )"
   ```
