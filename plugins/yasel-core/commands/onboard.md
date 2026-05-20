---
description: Onboard the agent to a specific task — explore the codebase, ask clarifying questions, write everything to .claude/tasks/<id>/onboarding.md so a fresh session can resume.
allowed-tools: Read, Glob, Grep, Bash(git:*), Bash(find:*), Bash(ls:*), Write
---

# /onboard

Per-task onboarding. Distinct from `/onboard-agent` (which grounds the agent on the whole *project*); `/onboard` grounds the agent on a single *task* before implementation starts.

Task context: $ARGUMENTS

## Your steps

> "AI models are geniuses who start from scratch on every task." — Noam Brown

Get fully prepared to do the work, then record what you learned so a future session can resume from your notes alone.

1. Use extended thinking. This is the place to over-invest.
2. Read `.claude/knowledge/*` for project-level grounding.
3. Explore the codebase relevant to the task — entry points, related modules, tests that already exist.
4. Identify open questions and surface them inline to the user. Wait for answers.
5. Determine a task ID. If the task came in via Linear (`ENG-123`), use that. Otherwise, slugify: `add-health-check`.
6. Write everything to `.claude/tasks/<id>/onboarding.md`:

```markdown
# Onboarding: <task title>

## What's being asked
(restate the task)

## Definition of done
(specific acceptance criteria)

## Files I expect to touch
- path/a.ts — why
- path/b.ts — why

## Existing patterns to follow
- (from `.claude/knowledge/`, from the codebase)

## Existing patterns NOT to follow
- (anti-patterns I noticed nearby; out of scope for this task)

## Open questions resolved during onboarding
- Q: ...  A: ...

## Risks / concerns
- (security, compliance, perf, etc.)

## Implementation plan
1. step
2. step
3. step

## Verification plan
- (how I'll prove it works)
```

7. Report the file path and stop. The user can review and then run `/ship` (or invoke the orchestrator) to execute.

Overdoing this is better than underdoing it. If onboarding feels heavy, the work itself will be lighter.
