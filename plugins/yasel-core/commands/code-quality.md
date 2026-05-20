---
description: Run code quality checks on a directory (lint, typecheck, dead-code, smells). Stack-agnostic — detects TS/JS or Python automatically.
allowed-tools: Read, Glob, Grep, Bash(npm:*), Bash(pnpm:*), Bash(npx:*), Bash(eslint:*), Bash(tsc:*), Bash(ruff:*), Bash(mypy:*), Bash(rg:*)
---

# /code-quality

Audit code quality in: $ARGUMENTS (defaults to the whole repo if blank).

## Your steps

1. **Detect stack:** check for `package.json` → TS/JS; `pyproject.toml` / `requirements.txt` → Python.

2. **Automated checks (TS/JS):**
   ```bash
   pnpm exec eslint $ARGUMENTS --max-warnings=0
   pnpm exec tsc --noEmit
   ```
   Or `npm`/`yarn`/`npx` if pnpm isn't present.

3. **Automated checks (Python):**
   ```bash
   uv run ruff check $ARGUMENTS
   uv run mypy $ARGUMENTS
   ```

4. **Manual review checklist** (apply to changed/specified files only):
   - No `any` (TS) / no untyped function signatures (Python).
   - Error handling at every async boundary.
   - Loading/error/empty states on lists (Next.js).
   - Mutations disable button + show loading.
   - Parameterized SQL only.
   - No PII in logs (`console.log(user)`, `console.log(req.body)`).
   - No hardcoded credentials.

5. **Report by severity:**
   - **Critical** — must fix
   - **Warning** — should fix
   - **Suggestion** — could improve

   Don't pad the report. If everything is clean, say so.
