# Design System

> **[TODO: replace this banner once filled in. This file drives the design-reviewer agent — accuracy matters when implementing UI.]**

## Source of truth for designs

- **Primary:** claude.ai/design (Yasel's preferred design tool)
- **Other:** (Figma URL if any; screenshots in /docs/design/; etc.)

## Tokens

### Colors

Using shadcn/ui theme tokens (mapped via `app/globals.css` CSS vars + Tailwind config):

| Token | Light | Dark | Used for |
|---|---|---|---|
| `background` | white | near-black | Page background |
| `foreground` | near-black | white | Body text |
| `primary` | (brand color) | (brand dark) | Primary buttons, links, accents |
| `primary-foreground` | white | (brand text) | Text on primary surfaces |
| `secondary` | gray-100 | gray-800 | Secondary buttons |
| `muted` | gray-100 | gray-900 | Subtle backgrounds |
| `muted-foreground` | gray-500 | gray-400 | Subtle text, labels |
| `border` | gray-200 | gray-800 | Borders, dividers |
| `destructive` | red-500 | red-700 | Errors, delete actions |
| `ring` | (focus ring) | (focus ring) | Focus rings |

> Update this table to match your actual `app/globals.css` / `tailwind.config.ts`.

### Spacing scale

Tailwind defaults (4px base). Allowed: `0, 0.5, 1, 1.5, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24`. Arbitrary values are a smell.

### Typography

- **Font (sans):** (e.g., Inter, Geist Sans)
- **Font (mono):** (e.g., Geist Mono)
- **Scale:** `text-xs` 12px, `text-sm` 14px, `text-base` 16px, `text-lg` 18px, `text-xl` 20px, `text-2xl` 24px, `text-3xl` 30px, `text-4xl` 36px
- **Headings:** h1 = text-3xl/4xl bold, h2 = text-2xl semibold, h3 = text-xl semibold, h4 = text-lg medium

### Responsive breakpoints

Tailwind defaults: `sm` 640px, `md` 768px, `lg` 1024px, `xl` 1280px, `2xl` 1536px.

Mobile-first design: write base classes for mobile, layer on `md:`/`lg:` for larger.

## Primitives installed

Run `npx shadcn add <name>` to install. Current set:

- [ ] Button
- [ ] Input
- [ ] Label
- [ ] Card (+ CardHeader, CardContent, CardFooter)
- [ ] Dialog
- [ ] Sheet (mobile bottom sheet)
- [ ] Select
- [ ] DropdownMenu
- [ ] Checkbox
- [ ] Switch
- [ ] Toast (sonner)
- [ ] Tooltip
- [ ] Tabs
- [ ] Avatar
- [ ] Skeleton (loading states)

> Check the boxes for what's installed. design-reviewer reads this — if the design needs a Toggle and the box is unchecked, the agent will prompt to install before implementing.

## Patterns

### Interactive states (always required)

- **Hover:** color shift on primary/secondary actions.
- **Focus visible:** `focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2`.
- **Active:** subtle scale or color depress.
- **Disabled:** `opacity-50 pointer-events-none`.
- **Loading:** spinner + disabled state for async actions.

### Loading / empty / error states

- Lists must have empty states (no naked `.map()`).
- Errors first in render order: `if (error) ... if (loading && !data) ... if (!data.length) ... return <ListUI>`.
- Skeleton placeholders on first load (use `<Skeleton>`); spinner on refetch only when no data.

### Accessibility baseline

- Icon-only buttons: `aria-label`.
- Form inputs: associated `<Label>`.
- Modals: focus trap + Escape to close.
- Color contrast ≥ 4.5:1 (the tokens above should pre-pass; check if you add custom).
- Keyboard nav: every interactive element via Tab; focus rings visible.

## Where the design lives

- claude.ai/design artifacts: (paste URLs as they're produced, or link a Notion / GitHub Discussions doc that catalogs them)
- Static assets / mockups: `/docs/design/`
- Brand guidelines: (link)

## Non-goals (visual)

- (e.g., "no Material Design", "no Bootstrap", "no custom-built primitives we could pull from shadcn")
