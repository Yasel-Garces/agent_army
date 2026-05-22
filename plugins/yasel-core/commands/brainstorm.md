---
description: Pure idea-generation mode. Explore an option space without committing. The agent generates options before evaluating, surfaces lanes you haven't named, and compares on multiple axes. When you pick a direction, transition to /discuss to scope it concretely.
allowed-tools: Read, Grep, Glob, Bash(git log:*), Bash(ls:*), Skill
---

# /brainstorm

Topic: $ARGUMENTS (can be empty — describe in chat)

This is **divergent-thinking mode**. We generate options before evaluating them. No code gets written. No plan is produced. The deliverable is a mapped option space + a clear sense of which lane to dig into next.

Progression you're in:

```
/brainstorm  →  /discuss  →  /ship
divergent       narrowing    executing
```

## Your steps

### 1. Read the brainstorming skill

Invoke the `brainstorming` skill via the Skill tool. The skill carries the discipline (generate before evaluating, consider constraints last, compare on multiple axes, surface lanes the user didn't name, pre-mortem before committing).

### 2. Light KB read (only what's needed)

Read `.claude/knowledge/scope.md` and `.claude/knowledge/context.md` to ground the brainstorm in what the project actually is and isn't. Don't do a deep KB read — at brainstorm stage, fewer constraints in the room means a wider option space.

### 3. Map the lanes

For the topic, list **5-8 distinct directions** (or 3 if you genuinely only see 3 — don't pad). Each lane gets:
- A name.
- A one-line essence.
- Why it's worth considering — what kind of project would this be the right answer for?

**Critical:** include at least one lane the user didn't name in their topic. The point of brainstorming is to surface options the user hasn't seen yet.

### 4. Trade-off frame

Show the lanes along axes that matter. Use a small table or a tight comparison:

| Lane | Time | User value | Reversibility | Strategic |
|---|---|---|---|---|

Tailor the axes to the topic — for a tech choice it might be "lock-in / community / performance / your team's expertise"; for a product feature it might be "time-to-ship / user value / strategic moat / reversibility."

### 5. Ask, don't pick

End every turn with a question that helps the user narrow:
- "Which lanes feel alive to you?"
- "Any constraint you want to apply now that the space is mapped?"
- "Which axis matters most for this decision?"

You can state a preference if asked ("if it were my call I'd lean toward B because..."), but you don't decide.

### 6. Iterate

The user will say things like "tell me more about lane 3" or "what's a hybrid of 2 and 4 look like." Stay in brainstorming mode — don't jump to implementation details. If they say "OK how would we build lane 3," gently offer: "want me to switch to `/discuss` to scope it?"

### 7. Transition out

When the user picks a direction (signals: "let's go with X," "OK X is the move," "fine, X"), say:

```
Direction: <lane chosen>

Ready to hand to /discuss for concrete scoping? Or do you want to brainstorm at the next level (sub-lanes within X)?
```

If they say "discuss," invoke `/discuss "<the chosen direction>"`. If they say "deeper," stay in brainstorm mode, treating the chosen lane as the new topic.

## When NOT to use /brainstorm

- **You already know what to build** → `/ship` directly.
- **You have a rough idea, want to scope it** → `/discuss` (one step further down the funnel).
- **You want a structural map of existing code** → `/deep-dive`.

## Example

```
You: /brainstorm "user retention features"

Agent: Reading the brainstorming skill...
       Reading scope.md, context.md...

## Brainstorm: user retention features

**Lanes I see:**

1. **Re-engagement notifications** — email/push/SMS on inactivity signals.
   Right when retention is about absence, not engagement quality.

2. **Personalized recommendations on return** — show "here's what you missed."
   Right for content-heavy products with daily updates.

3. **Streaks / gamification** — daily-use rewards, public streak counters.
   Right for habit-formation products (Duolingo-shape).

4. **Onboarding depth** — get users to a "hooked" moment in week 1.
   Right when retention is actually an activation problem disguised.

5. **Churn-signal intervention** — detect "about-to-leave" users, intervene.
   Right when you have enough usage data to model intent.

6. **Network / social anchors** — features that cost more to leave
   (shared state, groups, social proof of others' usage).
   Right when product has multiplayer dynamics.

7. **Habit anchoring** — fixed-time daily digests / reminders.
   Right for low-frequency, low-stakes products that benefit from being
   "in the rotation."

**A lane you didn't name:** **(7) habit anchoring** — the least flashy but
often the highest-ROI move. A weekly digest email is the boring version of
everything else on this list, and it works.

**Trade-off frame:**

| Lane | Eng cost | User value | Reversibility | Strategic |
|---|---|---|---|---|
| 1 Re-engagement | low–med | medium | high | low |
| 2 Personalized | high | high | medium | medium |
| 3 Streaks | medium | medium | medium | low |
| 4 Onboarding | medium | high | high | high (activation lift) |
| 5 Churn signal | high (data) | high | medium | medium |
| 6 Network | very high | high | low | very high (moat) |
| 7 Habit anchor | low | medium-low | high | low–medium |

**Questions back to you:**
- Is your retention problem actually a churn problem (users leave) or an
  activation problem (users never got hooked)? Different answers ⇒
  different lanes.
- Time horizon: pick something shippable this month, or willing to invest
  a quarter for the strategic lane (6)?

You: definitely activation — most users never come back after day 1

Agent: Then lane 4 (onboarding depth) is probably the move. Want to dig
       into sub-lanes within "onboarding depth," or hand off to /discuss
       to start scoping a concrete onboarding rework?
```
