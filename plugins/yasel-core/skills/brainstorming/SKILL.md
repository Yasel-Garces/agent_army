---
name: brainstorming
description: Generative ideation — exploring an option space before committing to one. Use when the user is in divergent-thinking mode: "what should I build next," "what are the ways to solve X," "I'm thinking about Y, what are the trade-offs." Pairs with /brainstorm for explicit entry, but should also trigger on conversational signals.
---

# Brainstorming

## When this applies

The user is generating options, not narrowing them. Signals:
- "I'm thinking about..."
- "What are the ways to..."
- "Could we..."
- "What if..."
- "How would you approach..."
- Open-ended "should I X or Y" questions
- No concrete acceptance criteria stated yet

Distinct from:
- **`/discuss`** — narrowing toward a shippable task (convergent).
- **`devil-advocate`** — critiquing an *existing* plan (defensive).
- **`/ship`** — executing a concrete task.

The progression is usually: **brainstorm → discuss → ship**. Most users skip brainstorm when the task is obvious; lean into brainstorm when the user is genuinely unsure of direction.

## How to brainstorm well

### 1. Generate before you evaluate

The single most important rule. Get 5-8 options on the table *before* judging any of them. Premature evaluation kills the option space.

Bad: "I'm thinking about user retention features." → "Email notifications could work, here's how I'd build them..."

Good: "I'm thinking about user retention features." → "Let me list the lanes first:
1. **Re-engagement notifications** — email / push / SMS triggered by inactivity
2. **Personalized recommendations** — show 'here's what you missed' on return
3. **Streaks / gamification** — daily-use rewards, social proof
4. **Onboarding depth** — get users to a 'hooked' state in week 1
5. **Reducing churn signals** — find users about to leave, intervene
6. **Network effects** — make leaving cost more (group features, shared state)
7. **Habit anchoring** — daily digest at a fixed time
8. **Reactivation campaigns** — win-back flows for already-churned

Want to dig into any of these, or should I add lanes you'd want to explore?"

### 2. Consider constraints LAST

Listing constraints first ("we have 2 weeks and one engineer") narrows before the option space is visible. Brainstorm the world where anything is possible, *then* filter through constraints. You'll often realize the constraint can move.

### 3. Compare on multiple axes

Don't just rank "best" → "worst." Show the trade-off plane:

| Option | Time to ship | User value | Reversibility | Cost | Strategic value |
|---|---|---|---|---|---|
| A | 1 week | medium | high | low | low |
| B | 1 month | high | medium | medium | high |
| C | quarter | very high | low | high | very high |

The user picks based on what axis matters now.

### 4. Surface the option the user didn't name

If you only echo their inputs, you're a notetaker. The value-add is:
- Adjacent options they haven't considered.
- A reframing of the problem ("what if the goal isn't retention but reactivation — different metric, different solution").
- A "do nothing" or "do less" option ("the simplest version is a weekly digest email; everything else is a step up from that").

### 5. Pre-mortem on each surviving option

For options the user is leaning toward, ask: "what would have to be true for this to be the wrong choice?" Forces explicit consideration of failure modes before commitment.

### 6. Know when to stop

Signs you're done brainstorming and should transition to `/discuss`:
- The user picks one option and starts asking implementation questions.
- The option space feels exhausted (no new lanes emerge).
- A clear winner emerges by elimination.
- The user signals: "OK let's go with X."

At that point, suggest: "Shall I switch to `/discuss` to scope this concretely?"

### 7. Don't pad

Eight bad options are worse than three good ones. If you genuinely only see three lanes, say so — don't manufacture filler to hit a target count.

## What NOT to do

- **Don't write code.** Brainstorming is text-only. Diagrams and pseudocode are fine; real code commits the user mentally.
- **Don't pick.** You're a sparring partner, not a decider. State preferences when asked ("if it were my call, I'd lean toward B because..."), but the user picks.
- **Don't grade-school list ideas.** "Pros / Cons" is fine; "Pros: It's good!" is not. Be specific about what trade-off you're naming.
- **Don't lose the option space.** Track what's been considered so you can return to it ("we mentioned X earlier and parked it — worth revisiting?").
- **Don't conflate with planning.** If the user starts asking "OK how would we build option B," gently transition: "That's a `/discuss` question — want me to switch modes?"

## Output shape

For each brainstorming turn:

```
## Brainstorm: <topic>

**Lanes considered so far:**
1. <option> — <one-line essence>
2. ...

**New lanes I'm adding:**
- <option> — <why this is worth considering>

**Trade-off frame:**
(table or short comparison along the axes that matter to this user)

**Question(s) back to you:**
- Which lane(s) do you want to dig into?
- (or) Any constraint you want to apply now that we have the space mapped?
```

Keep each turn tight. The user is thinking; don't drown them.
