---
description: Work on a Linear ticket end-to-end — read, explore, branch, implement (through the orchestrator chain), commit, PR, update ticket.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git:*), Bash(gh:*), Bash(npm:*), Bash(pnpm:*), mcp__linear__*, mcp__github__*
---

# /ticket

End-to-end Linear ticket workflow.

Ticket: $ARGUMENTS (Linear ID, e.g., `ENG-123`)

## Your steps

### 1. Fetch the ticket via Linear MCP

Use `mcp__linear__*` tools to get:
- Title, description, acceptance criteria
- Status, assignee, priority
- Linked tickets / parent epic
- Recent comments

Restate in 3-5 lines: what needs to be done, what done looks like, blockers.

### 2. Ground in the project KB

Read `.claude/knowledge/scope.md`, `data-model.md`, and any relevant `decisions/*.md`. Match the ticket's scope against the project's non-goals — if the ticket pushes a non-goal, surface it and stop.

### 3. Explore the codebase

Find the files this ticket will touch. Don't edit yet. Note related code, existing patterns, and any tech debt nearby that you should *not* fix in this PR (scope discipline).

### 4. Create a branch

```bash
git checkout -b yg/$ARGUMENTS-short-description
```

### 5. Hand off to the orchestrator

Pass the ticket summary + your exploration findings to `/ship` (or invoke the orchestrator subagent directly). The orchestrator runs the standard chain:

`data-engineer` (if data work) → `implementer` → `security-reviewer` ‖ `data-compliance` → `code-reviewer` → `tester` → commit → PR via `github-workflow`.

### 6. Update Linear

After the PR is open:
- Transition ticket to "In Review" via Linear MCP.
- Add a comment with the PR URL.
- Do NOT auto-close the ticket — the human reviewer does that on merge.

### 7. If you find an unrelated bug while working

Don't fix it. Create a new Linear ticket via `mcp__linear__*` with what you found, link it to the current ticket if related, and continue with the original task.

## Example

```
You: /ticket ENG-123

Agent:
1. Fetched ENG-123: "Add health check endpoint to API"
   Done = GET /api/health returns 200 + { ok: true, version }.
2. KB check: in scope (architecture.md mentions monitoring); no PII involved.
3. Will touch: app/api/health/route.ts (new), app/api/health/route.test.ts (new).
4. Created branch yg/ENG-123-health-check.
5. Handing to orchestrator...
   [implementer writes route + test, hooks format + typecheck + run test]
   [security-reviewer: APPROVED — no auth needed, public endpoint]
   [data-compliance: APPROVED — no PII]
   [code-reviewer: APPROVED]
   [github-workflow: PR #56 opened]
6. Linear ENG-123 → "In Review" + comment with PR link.
```
