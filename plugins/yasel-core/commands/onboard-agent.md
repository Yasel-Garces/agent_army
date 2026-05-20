---
description: Read the project's knowledge base + key repo files, report "what I understand", and ask targeted gap-filling questions. Run this before any /ship work in a new project.
allowed-tools: Read, Grep, Glob, Bash(git log:*), Bash(git status:*), Bash(ls:*), Bash(find:*), Bash(cat:*)
---

# /onboard-agent

Prove the agent has enough context about THIS project before any code work runs. This is the second step in the standard agent_army workflow (`/init-knowledge` first, then this, then `/ship`).

## Your steps

### 1. Verify the KB exists and is filled in

- Confirm `.claude/knowledge/scope.md` and `.claude/knowledge/data-model.md` exist.
- Read both. If either still contains the `[TODO: replace this banner ...]` marker, stop and tell the user to fill them in first. Don't proceed.

### 2. Read the rest of the KB

Read every file under `.claude/knowledge/` including all ADRs under `decisions/`. Note any TODO banners still present and surface them.

### 3. Read the repo signal

- `git log --oneline -30` for recent activity.
- `git status` for in-progress work.
- Top-level files: `README.md`, `CLAUDE.md` (if any), `package.json` / `pyproject.toml` / `requirements.txt`, `.mcp.json`, `.claude/settings.json`.
- Skim the largest 5 source files (use `find` + `wc -l` if helpful) to spot architectural shape.
- Identify entry points and any obvious "danger zones" (auth code, payment code, DB migrations).

### 4. Produce the report

Output exactly this structure (terse — the user reads this every onboarding):

```
## Project: <name>

**One-line:** <restate the project's purpose in your own words>

**Stack:** <bullets — frontend, backend, db, auth, hosting>

**Critical entities + PII:** <list each entity from data-model.md with a one-line PII summary>

**Active decisions I'll honor:** <bullets from decisions/ — only the still-relevant ones>

**Non-goals I'll respect:** <bullets from scope.md>

**Current state of the repo:** <1-2 sentences from git log/status>

**Open questions I need answered before /ship:**
1. ...
2. ...
3. ...
```

### 5. Ask the gap questions

Ask the open questions inline. Stop and wait for the user. Once they answer, optionally suggest specific updates to `.claude/knowledge/` files so the answers are persisted (don't make the edits unless they say go).

### 6. End state

When the user says "yes, you have it" (or equivalent), output a single line:

```
Context confirmed. /ship is ready.
```

This is the signal subsequent commands (and the orchestrator) treat as "agent is grounded."
