---
description: Thorough Explore-style codebase audit. Dispatches multiple Explore subagents in parallel to map an area of the codebase before planning a refactor or significant feature.
allowed-tools: Read, Glob, Grep, Bash(git:*), Bash(find:*), Bash(ls:*), Bash(wc:*), Bash(rg:*)
---

# /deep-dive

Audit area: $ARGUMENTS (a directory, module, or concept like "auth" or "the trades flow")

## Your steps

This is a read-only command — no edits.

1. **Scope the area** in one paragraph: what's in, what's out.
2. **Dispatch 2-3 Explore subagents in parallel** (one tool-call message, multiple `Agent` invocations with `subagent_type: Explore`). Give each a distinct angle:
   - Agent 1: "Map the structure" — files, modules, public/private surface.
   - Agent 2: "Trace the data flow" — where data enters, transforms, persists, exits.
   - Agent 3: "Find the smells" — dead code, duplication, security/PII suspects, performance hotspots.
3. **Wait, synthesize.** Don't redo their searches yourself.
4. **Output a map** in this format:

```markdown
# Deep dive: <area>

## Structure
(tree + per-file one-liner)

## Data flow
(numbered steps from input to output, file:line for each step)

## Touchpoints
- DB: tables / queries involved
- External APIs:
- Hooks/effects/middleware:

## Smells
- ...

## Likely places a change would land
- ...

## Open questions for the user
- ...
```

Don't recommend changes. The user gets to decide what to do with the map.
