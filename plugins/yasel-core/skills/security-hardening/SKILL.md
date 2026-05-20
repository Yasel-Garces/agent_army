---
name: security-hardening
description: Application security checklist tuned for Next.js + AWS Lambda + Postgres + Firebase stacks. Use when writing or reviewing auth, route handlers, Lambda handlers, DB queries, or third-party integrations. Covers OWASP top 10 with stack-specific examples.
---

# Security Hardening

## When this applies

You're touching code that:
- Handles auth / sessions / tokens
- Defines an API route handler (Next.js `/app/api/*` or `/pages/api/*`)
- Is a Lambda handler
- Builds or executes SQL
- Calls an outbound HTTP API
- Renders user-supplied content

## Core rules

### Input validation at the trust boundary
- Every external input (request body, query param, header, env var, MCP tool result) is untrusted.
- Validate with `zod` / `pydantic` at the handler entry. Reject on schema mismatch — don't coerce.
- Length-limit every string. Type-check every number. Whitelist every enum.

### Output encoding
- Don't construct HTML by string concatenation. React's JSX is safe by default — `dangerouslySetInnerHTML` is the exception that needs justification.
- SQL: parameterized queries only (`pg`'s `$1, $2, ...`). No template literals into queries.
- Shell: never spawn a shell with user input. Use the args array form.

### AuthN/AuthZ
- **Default deny.** Every route handler / Lambda must answer: "who can call this?" If the answer isn't documented in code (middleware, guard, decorator), it's broken.
- Verify tokens server-side. Never trust a JWT signature claim until verified.
- Session storage: HttpOnly + Secure cookies for browser sessions; never `localStorage`.
- Authorization (z) is separate from authentication (n). Authenticated ≠ authorized for *this* resource. Check ownership/role on every protected action.

### Next.js App Router specifics
- Server Actions: protect against CSRF. Use the built-in actions only with proper origin checks.
- Route handlers: read-only methods (`GET`, `HEAD`) shouldn't mutate; mutations need POST/PUT/PATCH/DELETE *and* auth check.
- `dangerouslySetInnerHTML`: only for content you've sanitized server-side (e.g., DOMPurify on the server). Never on user input.
- Middleware: `middleware.ts` runs on the edge — don't use Node-only APIs.

### AWS Lambda specifics
- IAM: least privilege. No `Resource: "*"` in policies unless documented and necessary.
- Secrets: SSM Parameter Store / Secrets Manager. Not env vars baked at deploy time. Not Lambda layers.
- Cold starts: don't read secrets on every invocation; cache in module scope but watch for rotation.
- VPC: if the Lambda touches RDS, put it in a VPC; if it doesn't, don't (saves cold-start time).

### Postgres specifics
- RLS (Row-Level Security) for multi-tenant tables — app-layer `WHERE user_id = ...` is necessary but not sufficient.
- Separate roles: `app_reader` (read-only) and `app_writer`. Don't run app code as superuser.
- Migrations: see `postgres-migrations` skill.

### Outbound HTTP / SSRF
- User-supplied URLs going into `fetch()` → block private IP ranges (`10.*`, `192.168.*`, `127.*`, `169.254.*`).
- Set timeouts on every outbound call (Node `AbortController`; Python `requests` `timeout=`).
- Validate response size before parsing.

### Dependencies
- Run `npm audit` / `pnpm audit` / `pip-audit` / `osv-scanner` after every dep change. High/Critical = block merge.
- Pin versions in lockfiles. Don't `^*.*.*` on anything you care about.
- Inspect new dependencies: download count, last release date, maintainer count. Tiny + new + no maintainers = supply-chain risk.

## Anti-patterns (block on sight)

- `eval(...)`, `new Function(...)`, `exec(req.body.cmd)`
- `app.use(cors({ origin: '*' }))` on a route that has auth
- `JSON.parse(req.body)` without size limit
- `bcrypt.compare(password, hash)` with timing-attack-vulnerable wrapper
- `Math.random()` for tokens / IDs / cryptographic purposes
- `localStorage.setItem('token', ...)`
- `process.env.DATABASE_URL` baked into client-side bundle
