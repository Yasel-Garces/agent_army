---
description: Update the project knowledge base (.claude/knowledge/*) without writing code. Use to record a decision, add a new entity, capture a constraint, or fix stale info. Agent drafts the edits, you approve, agent applies them.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(git status:*), Bash(git diff:*), Bash(date:*), Agent
---

# /update-knowledge

Standalone KB update. Use this when:
- You made a design decision in a meeting and want to record it as an ADR.
- You realized `data-model.md` is missing a field or has the wrong PII tier.
- A constraint changed (`scope.md` non-goal added, retention policy changed).
- A teammate / external source delivered a fact the KB doesn't have yet.
- The KB drifted from reality and you want to reconcile.

For KB updates that fall out of *implementing a feature* — don't use this. `/ship` already handles those inline (since v0.2.0).

What you say: $ARGUMENTS

## Your steps

### 1. Read the current KB

Read every file under `.claude/knowledge/`. If `.claude/knowledge/scope.md` is missing or still has the `[TODO: replace this banner ...]` marker, stop and tell the user to run `/init-knowledge` first.

### 2. Interpret the user's input

`$ARGUMENTS` is the user's natural-language description of what's changed or what they want recorded. Categorize:

- **New entity / field** → `data-model.md` addition (with PII tier).
- **New decision** → new ADR `decisions/YYYY-MM-DD-<slug>.md`.
- **New scope item or non-goal** → `scope.md` update.
- **Architectural change** → `architecture.md` update.
- **New domain term** → `glossary.md` addition.
- **Stale entry** → in-place edit to the relevant file (mark superseded if it's a decision).

If the user's input is ambiguous about which file to update, ask before drafting.

### 3. Draft the edits

Produce concrete diffs — file paths + before/after snippets — not vague descriptions. Use today's date (`$(date +%Y-%m-%d)`) for ADR filenames.

### 4. Detect conflicts

If the proposed update conflicts with existing KB (e.g., contradicts a previously-accepted ADR, redefines an entity field, removes a published non-goal), flag the conflict explicitly. Offer:

1. **Supersede** — write the new ADR with `Status: accepted, supersedes: <old ADR>` and update the old ADR's status to `superseded by: <new ADR>`.
2. **Drop the update** — keep the KB as-is.
3. **Reconcile** — narrow the update so it doesn't conflict.

Don't apply on conflict without explicit user choice.

### 5. Show the plan

```markdown
## KB update plan

**Source:** <user's input restated>

**Conflicts:** <none, or list with file:line citations>

**Proposed edits:**
- `data-model.md`: add row → `bank_account: string, YES (high)`
- `decisions/2026-05-19-bank-account-linking.md`: NEW ADR
- (etc.)

**Apply now? (y/n)**
```

Wait for user approval.

### 6. Apply

On approval: write the edits. Confirm by reading the files back.

### 7. Commit (optional)

Ask the user: "Commit these KB updates now, or leave uncommitted for later?"

- If commit: stage only the `.claude/knowledge/` paths, commit with message `docs(kb): <summary>`, push if the user says push.
- If leave: report the files changed and stop.

## Examples

```
You: /update-knowledge we decided to use Plaid for bank linking instead of manual entry; rejected manual because of fraud risk on self-reported account numbers

Agent: KB update plan:
  Source: chose Plaid over manual bank account entry; reason = fraud risk on self-reported account numbers.
  Conflicts: none.
  Proposed edits:
    - decisions/2026-05-19-plaid-for-bank-linking.md: NEW ADR
      Status: accepted
      Decision: use Plaid Link for bank account linking
      Alternatives: manual entry (rejected — fraud risk)
      Consequences: external dependency, Plaid fees, but stronger account verification
  Apply now? (y/n)

You: y

Agent: Wrote decisions/2026-05-19-plaid-for-bank-linking.md (28 lines).
       Commit now? (y/n)

You: y

Agent: docs(kb): record decision to use Plaid for bank linking
       Pushed to origin/main.
```

```
You: /update-knowledge data-model says email is YES (low) but it should be YES (medium) — we send password reset tokens to it, so leak risk is bigger than I thought

Agent: KB update plan:
  Source: re-classify user.email from YES (low) → YES (medium); reason = password reset token destination.
  Conflicts: none (this is a refinement, not a contradiction).
  Proposed edits:
    - data-model.md: change user.email PII tier from "YES (low)" to "YES (medium)"
    Suggested follow-up ADR (optional): decisions/2026-05-19-email-pii-reclassification.md
  Apply now? (y/n)
```
