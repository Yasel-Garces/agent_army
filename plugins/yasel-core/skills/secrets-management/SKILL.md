---
name: secrets-management
description: Env var hygiene, KMS / SSM Parameter Store / Secrets Manager / Firebase secure config patterns, secret rotation, .env file rules. Use when adding any new credential, API key, token, or connection string.
---

# Secrets Management

## When this applies

Adding or rotating: API keys, database passwords, third-party tokens, OAuth client secrets, encryption keys, signing keys, webhook secrets, cron auth tokens.

## Hard rules

1. **Never commit `.env*` to git.** Enforced by `.gitignore` and `env-file-guard.sh`. `.env.example` (no real values) is fine.
2. **Never log a secret.** Even partially. Don't print "loaded API key starting with sk-..." — that's enough for fingerprinting.
3. **Never paste a secret into a prompt** to Claude / ChatGPT / Gemini. Use placeholders.
4. **One secret per credential, per environment.** Don't share the same API key across dev / staging / prod.
5. **Rotation cadence in the calendar.** Document in `.claude/knowledge/decisions/` when each secret was last rotated and when next.

## Storage by environment

### Local development
- `.env.local` (Next.js convention) — gitignored.
- Direnv (`.envrc`) is fine if it's also gitignored.
- 1Password / Bitwarden CLI for sharing across the user's own machines: `op run -- npm run dev`.

### CI / GitHub Actions
- Repository secrets (`Settings → Secrets and variables → Actions`).
- Reference via `${{ secrets.NAME }}`. Never `echo "$SECRET"` in a step — GitHub redacts in logs, but a redirect into a file can leak.
- Scope tokens narrowly: GitHub PATs use fine-grained tokens, not classic; AWS credentials use OIDC + assumed-role with least-privilege, not long-lived keys.

### AWS Lambda / runtime
- **SSM Parameter Store** for tier-1 secrets that change infrequently — encrypted with KMS.
- **Secrets Manager** for credentials that need automatic rotation (RDS master passwords).
- Read at cold start, cache in module scope. Re-read if you detect auth failure (handles rotation).
- IAM policy: `ssm:GetParameter` / `secretsmanager:GetSecretValue` scoped to the specific parameter, not `*`.

### Next.js
- `NEXT_PUBLIC_*` variables are bundled into the client. **Never** put a secret there.
- Server-only secrets: any env var without `NEXT_PUBLIC_`. Read inside server components, route handlers, server actions only.
- Verify at build time that the server bundle doesn't include any known-secret pattern (use the `secret-scan.sh` hook).

### Firebase
- Firebase config (API key, auth domain, project ID) is *technically* public — it's in the client. Restrictions are enforced via Firebase Security Rules + API key restrictions in GCP console, not by hiding the key.
- Service account JSON keys (for server-side admin SDK): never client-side. Store in SSM / Secrets Manager.

## Rotation

- API keys with no rotation = expired keys with no rotation. Pick a cadence (90 days for high-value; annual for low-risk) and put it on the calendar.
- When rotating: dual-write period (both old and new accepted), switch consumers, then revoke old. Don't atomic-swap; you'll page yourself.

## Anti-patterns (block on sight)

- `const API_KEY = "sk-..."` in any source file
- `process.env.STRIPE_SECRET_KEY` referenced in a file that ends up in the client bundle
- Service account JSON committed to `infrastructure/` or `scripts/`
- `.env.production` committed
- Sharing a single token across "all integrations" — one breach = total compromise
- Long-lived AWS access keys for CI — use OIDC + assumed role instead
- Test keys in `.env.example` with real-looking values that have ever been live
