---
description: Import a design from claude.ai/design (or another source) into the production codebase. Routes through implementer → design-reviewer → security/compliance gate → code-reviewer.
allowed-tools: Read, Write, Edit, Glob, Grep, WebFetch, Bash(git:*), Bash(npm:*), Bash(pnpm:*), Bash(npx:*), Agent
---

# /design-import

Bring a design into the codebase faithfully.

Source: $ARGUMENTS

`$ARGUMENTS` can be:
- A `claude.ai/design` artifact URL.
- Pasted JSX / HTML the user generated.
- A path to a screenshot or markup file in the repo.
- Empty → ask the user where the design is.

## Your steps

### 1. Acquire the design source

- **claude.ai URL:** WebFetch it. Extract the JSX/HTML the artifact produces.
- **Pasted code:** read it from the conversation.
- **Screenshot path:** Read it (Claude reads images).
- **Empty:** ask the user where the design is. Don't guess.

### 2. Read the design system KB

Read `.claude/knowledge/design-system.md`. This is what tokens, primitives, and breakpoints the project uses.

If it's missing, suggest running `/update-knowledge "set up the design system for this project"` first — but offer to proceed with sensible defaults (warn the reviewer will be looser).

### 3. Plan the translation

Map the design source → production code:

```
## Design import plan

**Source:** <link / "pasted in chat" / path>

**Target location:** <where this lands in the codebase>
- e.g., `app/(marketing)/pricing/page.tsx` for a page
- e.g., `components/pricing-card.tsx` for a reusable component

**Token translation:**
- design used `bg-slate-900` → project's `bg-background` (dark theme)
- design used custom `#3b82f6` → project's `bg-primary`
- ...

**Primitive translation:**
- design's raw `<button>` → `<Button variant="default">`
- design's card div → `<Card>/<CardHeader>/<CardContent>`
- ...

**Missing in the design (will add per design-fidelity skill):**
- focus-visible states
- disabled states
- aria-label on icon button at line 42
- mobile breakpoint (design shows desktop only — ask user)

**Missing primitives the project needs:**
- `<Toggle>` — run `npx shadcn add toggle` before implementing

**Open questions for the user:**
- ...
```

Wait for user approval.

### 4. Execute the chain

Hand off to the orchestrator with the import plan. Standard chain runs:

1. `implementer` — write the production code per the plan.
2. **Hooks** auto-run (format, typecheck).
3. **`design-reviewer`** — verify fidelity against the source + design-system.
4. **`security-reviewer` ‖ `data-compliance`** — usually a no-op for pure UI, but if the design includes forms touching PII, they engage.
5. **`code-reviewer`** — TS / state hygiene.
6. `github-workflow` — commit + PR.

`design-reviewer` can block here, just like security-reviewer can. If it blocks, surface findings, hand back to `implementer`, loop until approved.

### 5. Report

```
## Design import complete

**Source:** <link>
**Lands at:** <path(s)>
**Design fidelity:** APPROVED | APPROVED WITH NOTES
**PR:** <link>

**Notes:**
- (e.g., "added focus states the design omitted")
- (e.g., "swapped Toggle primitive in via shadcn add")
```

## Examples

```
You: /design-import https://claude.ai/design/abc123

Agent: Fetching artifact...
  Detected: pricing page (3 tier cards + CTA section).
  Target: app/(marketing)/pricing/page.tsx + components/pricing-card.tsx.
  Token translation: 4 raw colors → 4 design-system tokens.
  Primitive translation: 3 raw <button>s → <Button>, card div → <Card>.
  Missing in design: focus rings, hover states on cards, mobile layout (desktop only).
  Open question: mobile layout — stack vertically or use horizontal scroll?

You: stack vertically

Agent: Plan ready. Apply?

You: go

[orchestrator chain runs]

Agent: Design import complete.
  Lands at: app/(marketing)/pricing/page.tsx, components/pricing-card.tsx
  Design fidelity: APPROVED WITH NOTES (added focus + hover states, mobile stack)
  PR: https://github.com/Yasel-Garces/stock-navigator/pull/58
```
