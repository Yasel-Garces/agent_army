---
description: End-to-end "do the thing" — orchestrator plans, you approve, chain runs through implementer + security/compliance gates + code review + tests + commit + PR. Default flow.
allowed-tools: Read, Grep, Glob, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Agent
---

# /ship

Task: $ARGUMENTS

Hand the task to the orchestrator. Plan-first is the default; the orchestrator will produce a plan and wait for your approval before executing.

## What happens

1. Orchestrator reads `.claude/knowledge/*`. If the KB is missing, it stops and tells you to run `/init-knowledge`. Creates a task workspace at `.claude/tasks/<task-id>/` (resumes if a checkpoint already exists).
2. **KB diff + conflict detection.** Orchestrator computes what KB additions the task implies (new entity? new ADR? new architecture component?) and flags any conflicts (task contradicts `scope.md` non-goals, a `decisions/` ADR, or an existing `data-model.md` field).
3. **Plan + devil-advocate critique.** Orchestrator drafts a plan with Definition of done (evidence artifacts to produce). Invokes `devil-advocate` to critique the plan from a "what could go wrong / what cheaper alternative is being skipped" angle. Shows you BOTH the plan and the critique. You review and say "go" (or revise based on the critique).
4. **KB updates land FIRST** (so security-reviewer and data-compliance see the new entities/PII tags when they review the code).
5. Orchestrator delegates:
   - `data-engineer` first if data work is involved.
   - `implementer` builds (writes notes to `scratchpad.md`).
   - **Mandatory gate:** `security-reviewer` ‖ `data-compliance` (‖ `design-reviewer` if UI). Any blocks → stop.
   - `code-reviewer` last.
   - `tester` to add coverage if the orchestrator's plan asked for it.
6. **Replanning trigger:** if any step fails twice in a row, orchestrator stops and presents three options: re-plan, narrow scope, or abandon. No silent runaway loops.
7. **Verify gate:** orchestrator collects evidence artifacts (test output, typecheck output, smoke test) into `.claude/tasks/<task-id>/evidence/`. If fewer artifacts than the Definition of done required, the task is NOT done.
8. `github-workflow` commits + opens PR (KB updates + code + `.claude/tasks/<id>/` artifacts all in the same commit).
9. Orchestrator returns a one-paragraph summary + PR link + evidence summary.

**You never edit `.claude/knowledge/*` by hand for normal work.** The agent proposes the edits in the plan; your "go" approves them; the agent applies them. The only times you'd edit the KB manually: initial fill-in after `/init-knowledge`, or to override a stale entry the agent missed.

## Your steps

Invoke the orchestrator subagent with $ARGUMENTS as the task. Pass through any constraints the user provided.

```
Use Agent(subagent_type: orchestrator) with the user's task. Wait for the plan.
Display the plan. Wait for approval. On approval, tell the orchestrator to execute.
```

## When to bypass plan-first

The user can say "no plan, just do it" — in that case, tell the orchestrator to skip the plan-output step and execute directly. The mandatory security + compliance gate **still runs.** That is non-negotiable.
