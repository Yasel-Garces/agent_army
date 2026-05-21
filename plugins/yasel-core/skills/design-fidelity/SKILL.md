---
name: design-fidelity
description: Faithful translation of designs (claude.ai/design artifacts, Figma exports, screenshots) into production code. Covers Tailwind token usage, shadcn/ui primitive mapping, responsive breakpoint parity, interactive states (hover/focus/disabled/loading), and accessibility hooks. Use when implementing or reviewing any UI component, page, or layout.
---

# Design Fidelity

## When this applies

You're translating a design — from `claude.ai/design`, Figma, a screenshot, or a reference component — into production code. The goal is to match, not approximate.

## Source-of-truth ordering

When implementing, you have multiple "sources" that may conflict. Use this priority:

1. **The design source the user provided** (claude.ai/design link, pasted snippet, screenshot) — highest authority.
2. **`.claude/knowledge/design-system.md`** — what tokens / primitives / breakpoints the project uses. If the design source uses a raw color, map it to the closest token here.
3. **Existing components in the codebase** — match conventions for component composition, prop names, file layout.
4. **Tailwind / shadcn defaults** — fallback only.

If 1 and 2 conflict (design uses `#1f2937`, design-system.md has no slate-800 token), surface to the user — don't silently pick one.

## Tailwind token discipline

- Use design-system tokens: `bg-primary`, `text-muted-foreground`, `border-input`. Not raw palette indices (`bg-blue-500`) unless the design-system maps to them.
- Spacing: use the scale (`px-4`, `gap-6`). Arbitrary values (`px-[13px]`) are a smell — usually means a design pixel-pushed and you should round to the scale or update the scale.
- Dark mode: every color class needs a `dark:` counterpart unless the token is theme-aware (which most shadcn tokens are).

## shadcn/ui primitive mapping

claude.ai/design often emits raw JSX. Map to shadcn primitives:

| Raw JSX | shadcn primitive |
|---|---|
| `<button class="...">` | `<Button variant="...">` |
| `<input class="...">` | `<Input>` |
| Card layout (div with shadow + padding) | `<Card><CardHeader/><CardContent/></Card>` |
| Modal / overlay | `<Dialog>` |
| Bottom sheet on mobile | `<Sheet>` |
| Dropdown | `<Select>` or `<DropdownMenu>` |
| Checkbox | `<Checkbox>` |
| Toggle | `<Switch>` (or add `<Toggle>` if needed) |
| Toast | `<Sonner>` toast |

If the design uses a primitive the project doesn't have, run `npx shadcn add <name>` before implementing — don't hand-roll a replacement.

## Interactive states (the part claude.ai/design usually skips)

Every clickable / focusable element needs:

- **Hover** — `hover:bg-primary/90` (or token equivalent). Cursor change implied.
- **Focus visible** — `focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2` (or your project's ring tokens). Keyboard users need this.
- **Active** — visual feedback on click (`active:scale-[0.98]` or token).
- **Disabled** — `disabled:opacity-50 disabled:pointer-events-none`. Reduced visual prominence.
- **Loading** — spinner + disabled state during async ops. Button text optionally hidden or replaced.

shadcn primitives bake most of these in — that's why you map to them.

## Responsive parity

If the design shows mobile + desktop versions, the implementation needs `sm:` / `md:` / `lg:` prefixes that recreate both. Common patterns:

- Stack → grid: `flex flex-col md:grid md:grid-cols-3`
- Hidden on mobile: `hidden md:block`
- Hidden on desktop: `md:hidden`
- Sheet (mobile) vs Dialog (desktop): use both, toggle by breakpoint.

If only one breakpoint was designed, ask the user about the other — don't invent.

## Accessibility baseline

Non-negotiable:

- Icon-only buttons get `aria-label`.
- Form inputs get `<Label htmlFor>` or `aria-labelledby`.
- Decorative images: `alt=""`; meaningful images: descriptive alt.
- Color is never the only signal (error state needs text/icon, not just red border).
- Body text contrast ≥ 4.5:1. Use the design-system tokens — they should pre-pass.
- Keyboard navigation: every interactive element reachable via Tab; modals trap focus; Escape closes.

## Importing from claude.ai/design

When the user shares a `claude.ai/design` artifact:

1. Read the JSX it generated as the layout source.
2. **Don't paste it raw.** It's often vanilla Tailwind without project tokens — translate to your token system.
3. Replace raw `<button>` / `<input>` / `<div>`-with-card-styling with shadcn primitives.
4. Add the interactive states claude.ai/design typically omits.
5. Verify with `design-reviewer` before committing.

## Anti-patterns (block on sight)

- Inline `style={{ color: '#1f2937' }}` — use tokens.
- `<div onClick={...}>` for clickable items — use `<button>` or `<Button>`.
- `text-2xl` on a body paragraph in a card meant to display data — check the design's hierarchy.
- Magic numbers for spacing (`mt-[7px]`) — match scale or update the scale.
- Re-implementing a shadcn primitive that's already installed.
- No focus styles ("the design didn't show them" — claude.ai/design rarely does; add them anyway).
- Missing `aria-label` on icon buttons.
- Light-mode-only when the project supports dark mode.
