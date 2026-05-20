---
description: Review a pull request using project standards. Invokes the security-reviewer, data-compliance, and code-reviewer agents in sequence and posts a structured comment on the PR.
allowed-tools: Read, Glob, Grep, Bash(git:*), Bash(gh:*), Bash(npm:*), Bash(pnpm:*)
---

# /pr-review

Review pull request: $ARGUMENTS

## Your steps

1. **Fetch PR context:**
   ```bash
   gh pr view $ARGUMENTS
   gh pr diff $ARGUMENTS
   ```

2. **Check out the branch locally** if not already:
   ```bash
   gh pr checkout $ARGUMENTS
   ```

3. **Read the project KB** (`.claude/knowledge/*`) so your review uses the project's specific PII model, decisions, and non-goals.

4. **Run the three reviewers in order** (each is a subagent — use the Agent tool):
   - `security-reviewer` — must pass before continuing
   - `data-compliance` — must pass before continuing
   - `code-reviewer` — runs last

5. **Aggregate findings** into one structured comment:

   ```markdown
   ## Automated Review

   **Security:** APPROVED | BLOCKED — (reason if blocked)
   **Compliance:** APPROVED | BLOCKED — (reason if blocked)
   **Code quality:** APPROVED | NEEDS CHANGES | BLOCKED

   ### Critical
   - ...

   ### Warning
   - ...

   ### Suggestion
   - ...
   ```

6. **Post the comment:**
   ```bash
   gh pr comment $ARGUMENTS --body "$(cat <<'EOF'
   <aggregated review>
   EOF
   )"
   ```

7. **Update PR status** if any reviewer blocked: leave it open and surface the blockers to the user. Do not approve programmatically.
