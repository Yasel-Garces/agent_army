---
description: Scaffold the .claude/knowledge/ directory in the current project so the agent has scope, context, data-model, and decision history to ground on.
allowed-tools: Write, Read, Bash(mkdir:*), Bash(ls:*)
---

# /init-knowledge

Scaffold a project knowledge base under `.claude/knowledge/` so future agent work has scope, context, and decisions to ground on. This MUST run before any `/ship`-style work in a fresh project (the `require-knowledge.sh` hook will block until it does).

## Your steps

1. Check if `.claude/knowledge/scope.md` already exists. If yes, stop and report — do NOT overwrite. The user can edit it directly or delete and re-run.
2. Create the directory: `.claude/knowledge/decisions/`.
3. Write the seven skeleton files below, each with a banner the user must replace before `/onboard-agent` will accept the KB as filled in.
4. Report:
   - what was created,
   - which fields the user must fill in first (scope, data-model — the rest can come later; design-system can come right after if the project has UI),
   - that the next command is `/onboard-agent` once the user has filled in at least scope and data-model.

## Skeleton files to write

### `.claude/knowledge/scope.md`

```markdown
# Scope

> **[TODO: replace this banner once you've filled the file in. The agent treats unmodified banners as "not yet filled in".]**

## What this project IS

- (one-line elevator pitch)
- (top 3 user-visible capabilities)

## What this project is NOT (non-goals)

- (things explicitly out of scope — be specific)

## Current phase

- (e.g., "pre-launch MVP", "post-launch growth", "deprecated, maintenance only")

## Success metrics

- (how do you know the project is working?)
```

### `.claude/knowledge/context.md`

```markdown
# Context

> **[TODO: replace this banner once filled in.]**

## Why this project exists

- (business / personal motivation)

## Users / audience

- (who uses it; primary persona)

## Stakeholders

- (anyone besides the user who has a stake — investors, beta users, regulators)

## Constraints

- Budget / cost ceiling:
- Time / deadline:
- Regulatory: (GDPR? CCPA? SOC2? finance-specific?)
- Other:
```

### `.claude/knowledge/architecture.md`

```markdown
# Architecture

> **[TODO: replace this banner once filled in.]**

## System map (high level)

```
[Client] ──> [API] ──> [DB]
            └─> [External APIs]
```

## Stack

- Frontend:
- Backend:
- Database:
- Auth:
- Hosting / infra:
- Key third-party services:

## Data flow (critical paths)

1. (e.g., "User signs in → Firebase issues token → API verifies → returns user profile")
2.
```

### `.claude/knowledge/data-model.md`

```markdown
# Data Model

> **[TODO: replace this banner once filled in. This file drives the security-reviewer and data-compliance agents — be accurate.]**

## Entities

### `user`
| field | type | PII? | notes |
|---|---|---|---|
| id | uuid | no | |
| email | string | **YES** | encrypted-at-rest? |
| name | string | YES (low) | |
| date_of_birth | date | **YES** | |

### `(next entity)`
| field | type | PII? | notes |
|---|---|---|---|

## PII classification legend

- **YES (high):** SSN, financial account numbers, health, full address, DOB → encrypt-at-rest mandatory, never log, never send to third parties without consent.
- **YES (medium):** email, phone, full name → encrypt-at-rest, redact in logs.
- **YES (low):** first name, city, generic preferences → still PII under GDPR; redact in logs.
- **no:** non-personal.

## Retention policy

- (how long is each PII field kept? what triggers deletion?)
```

### `.claude/knowledge/design-system.md`

Copy from `template/.claude/knowledge/design-system.md` in the agent_army repo. It captures the project's color tokens, spacing scale, typography, installed shadcn primitives, responsive breakpoints, and a11y baseline. The `design-reviewer` agent reads this when verifying UI fidelity.

If the project has no UI (pure backend / library), leave the banner intact — the design-reviewer will skip files when this file is unfilled.

### `.claude/knowledge/glossary.md`

```markdown
# Glossary

> **[TODO: replace this banner once filled in.]**

Domain terms that show up in the codebase. Important for fintech / health / niche domains where vocabulary is non-obvious.

| Term | Meaning |
|---|---|
| (e.g., "trade") | (e.g., "a buy-or-sell event recorded against a user's portfolio; immutable after confirm") |
| | |
```

### `.claude/knowledge/decisions/0000-template.md`

```markdown
# 0000 - (decision title)

> **[TODO: copy this template for each decision. Use `YYYY-MM-DD-short-title.md` naming. Delete this template once you have real decisions.]**

- **Date:** YYYY-MM-DD
- **Status:** proposed | accepted | superseded by [...](#)

## Context

What forced the decision? What were the constraints?

## Decision

What did you choose?

## Alternatives considered

- A — rejected because ...
- B — rejected because ...

## Consequences

What does this make easy? What does this make hard?
```

## When done

Print a checklist of files written, point the user at `scope.md` and `data-model.md` as the must-fill-first, and tell them to run `/onboard-agent` once those two are filled in.
