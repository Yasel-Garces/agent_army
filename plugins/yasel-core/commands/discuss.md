---
description: Conversational task refinement BEFORE planning. Agent asks clarifying questions, explores trade-offs with you, narrows scope. When you say "ready," it hands off to /ship for the formal plan + execution chain.
allowed-tools: Read, Grep, Glob, Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(ls:*), Bash(rg:*), Agent
---

# /discuss

Use this when you have a rough idea, not a concrete task. We talk first; `/ship` happens when you're ready.

Starting topic: $ARGUMENTS (can be empty — just describe in chat)

## Your steps

### 1. Ground in the project KB

Read `.claude/knowledge/*` so your questions are project-aware. If the KB is missing, stop and tell the user to run `/init-knowledge` first.

### 2. Restate your understanding

```
## Topic restated

<one-line restatement of what the user seems to want>

Open questions before I can scope this:
1. ...
2. ...
3. ...
```

Keep questions specific and ranked by what's most load-bearing. Don't ask everything at once — start with the 2-3 questions that, once answered, narrow the scope most.

### 3. Iterate

Loop with the user. Each turn:
- Restate what's now decided.
- Surface any conflicts with the KB (e.g., the user's direction collides with a `scope.md` non-goal or a `decisions/` ADR — call it out, ask if we're superseding or narrowing).
- Ask the next-most-load-bearing question(s).
- Suggest alternatives where you see them ("we could do A or B — A is faster, B is more flexible because..."). Don't be a passive note-taker.

Stop iterating when:
- The user says "ready" / "ship it" / "let's do it" / equivalent.
- The scope is concrete enough that you could write a plan with no further ambiguity.
- The user pivots to something else entirely (in which case, ask if you should drop the current thread).

### 4. Produce the crystallized task

When ready, summarize:

```
## Refined task

**One-line description:** <what we're building>

**In scope:**
- ...

**Explicitly out of scope (decided during discussion):**
- ...

**Key decisions made:**
- (chose A over B because ...)
- ...

**KB updates implied:**
- data-model.md: add ...
- decisions/<date>-<slug>.md: NEW ADR for ...

**Ready to hand to /ship? (y/n, or tell me what's still missing)**
```

### 5. Hand off

On "y" / "go" / "ship":

- The agent invokes `/ship "<one-line description>"` (or directly invokes the orchestrator subagent with the refined task context).
- From that point on, the standard chain runs: orchestrator plans → user approves the plan → KB updates → implementer → security + compliance + design gates → code review → tests → commit → PR.

If the user said anything during discussion that updates the KB (decisions, new entities), include those in the orchestrator's KB-update plan — don't make them re-explain.

## When NOT to use /discuss

- **You already know exactly what you want** → use `/ship "..."` directly.
- **You're investigating a bug** → use `/onboard "bug ..."` (heavier exploration writes notes to a file) or just describe symptoms and let `/ship` route to the debugger.
- **You want to map an unfamiliar area without committing to a task** → use `/deep-dive <area>` for a structural map.

## Example

```
You: /discuss "I want some kind of notification system"

Agent: Let me narrow this. Most load-bearing questions first:
  1. What triggers a notification? (someone follows you? system event? scheduled?)
  2. Where do users see it? (in-app bell, browser push, email, SMS — or several?)
  3. Real-time, or is polling on page load OK?

You: in-app bell only, triggered on follow events, polling is fine

Agent: Good. Next:
  - You already have a followers relationship in data-model.md (yes: `user_follows`). When a follow row is inserted, the notification is created in the same transaction, async, or via a separate trigger? Same-tx is simplest and stays consistent.
  - Multiple notifications per user — yes, batch dropdown view. Need mark-as-read state? Most apps do.

You: same-tx, yes mark-as-read

Agent: One more thing — retention. Notifications older than (30 days? 90 days? forever?) — and is that a hard delete or a flag?

You: 90 days hard delete

Agent: ## Refined task

  In scope: new notifications table + insert in follow-tx + bell icon component + dropdown + mark-read endpoint + 90-day cleanup job.
  Out of scope (decided): push/email/SMS, real-time websockets.
  Key decisions: same-tx insert (consistency > throughput); 90-day hard delete (storage cost > audit trail need).
  KB updates implied:
    - data-model.md: new `notifications` entity (user_id, type, body, created_at, read_at) — PII (low) since body may include other users' names
    - decisions/2026-05-20-notifications-mvp.md: NEW ADR
  Ready to hand to /ship? (y/n)

You: y

Agent: → /ship "implement in-app follow notifications with mark-read and 90-day cleanup"
```
