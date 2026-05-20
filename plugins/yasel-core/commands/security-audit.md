---
description: Full repo-wide security + compliance + secrets sweep. Runs security-reviewer, data-compliance, and external scanners (gitleaks, osv-scanner, npm/pip audit). Output is a prioritized findings report.
allowed-tools: Read, Grep, Glob, Bash(git:*), Bash(rg:*), Bash(gitleaks:*), Bash(trufflehog:*), Bash(osv-scanner:*), Bash(npm:*), Bash(pnpm:*), Bash(pip-audit:*), Agent
---

# /security-audit

Repo-wide sweep. Not scoped to a diff — looks at the whole tree. Run this:
- After a major feature lands.
- Before a release.
- On schedule (weekly) via `.github/workflows/scheduled-security-audit.yml`.
- Any time you want to know "is anything ugly in here right now?"

## Your steps

### 1. Run the agents (parallel)

Invoke `security-reviewer` and `data-compliance` in **whole-repo mode**:
- Tell `security-reviewer` to ignore `git diff` scoping and review the whole tree under `app/`, `lib/`, `server/`, `aws-lambda/`, `migrations/`, etc.
- Tell `data-compliance` to do a full PII inventory against `.claude/knowledge/data-model.md` and check for entities/fields the code uses that aren't in the data model (un-documented PII).

### 2. Run external scanners (parallel)

```bash
# Secrets in git history (not just current tree)
gitleaks detect --source . --no-banner --redact || true
# or
trufflehog filesystem . --no-update --json 2>/dev/null || true

# Dependency CVEs
if [[ -f "package.json" ]]; then
  (npm audit --audit-level=high --json 2>/dev/null || pnpm audit --audit-level high --json 2>/dev/null) || true
fi
if [[ -f "pyproject.toml" || -f "requirements.txt" ]]; then
  (uv run pip-audit 2>/dev/null || pip-audit 2>/dev/null) || true
fi
if command -v osv-scanner >/dev/null 2>&1; then
  osv-scanner --recursive . 2>/dev/null || true
fi
```

(These tools may not be installed on every machine; gracefully skip if missing — note it in the report.)

### 3. Aggregate

Produce a single report:

```markdown
# Security Audit — <date>

## Critical findings (must fix)
- (finding) — source: <tool/agent>, location: <file:line>
- ...

## High
- ...

## Medium
- ...

## Tooling availability
- gitleaks: installed / not installed
- npm audit: ran / N/A
- osv-scanner: ran / not installed

## PII inventory delta
- Fields in code but NOT in .claude/knowledge/data-model.md:
  - ...
- Fields in data-model.md but NOT used in code (stale):
  - ...

## Suggested follow-up tickets
- (one-line each — to file via Linear MCP if available)
```

### 4. Optionally file Linear tickets

If `mcp__linear__*` is available and the user approves, file one ticket per Critical/High finding. Group by file/area to avoid noise.

### 5. Save the report

Write to `.claude/audits/security-<YYYY-MM-DD>.md` so future audits can diff against it.
