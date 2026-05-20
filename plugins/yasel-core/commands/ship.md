---
description: End-to-end "do the thing" — orchestrator plans, you approve, chain runs through implementer + security/compliance gates + code review + tests + commit + PR. Default flow.
allowed-tools: Read, Grep, Glob, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Agent
---

# /ship

Task: $ARGUMENTS

Hand the task to the orchestrator. Plan-first is the default; the orchestrator will produce a plan and wait for your approval before executing.

## What happens

1. Orchestrator reads `.claude/knowledge/*`. If the KB is missing, it stops and tells you to run `/init-knowledge`.
2. Orchestrator checks the task against `scope.md` non-goals. If conflict, surfaces and asks.
3. Orchestrator produces a plan (KB context + steps + gates + risks). You review and say "go."
4. Orchestrator delegates:
   - `data-engineer` first if data work is involved.
   - `implementer` builds.
   - **Mandatory gate:** `security-reviewer` ‖ `data-compliance` in parallel. Either blocks → stop.
   - `code-reviewer` last.
   - `tester` to add coverage if the orchestrator's plan asked for it.
   - `github-workflow` commits + opens PR.
5. Orchestrator returns a one-paragraph summary + PR link.

## Your steps

Invoke the orchestrator subagent with $ARGUMENTS as the task. Pass through any constraints the user provided.

```
Use Agent(subagent_type: orchestrator) with the user's task. Wait for the plan.
Display the plan. Wait for approval. On approval, tell the orchestrator to execute.
```

## When to bypass plan-first

The user can say "no plan, just do it" — in that case, tell the orchestrator to skip the plan-output step and execute directly. The mandatory security + compliance gate **still runs.** That is non-negotiable.
