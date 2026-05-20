---
name: pii-handling
description: PII inventory, redact-before-log, encryption-at-rest, third-party egress rules. Use whenever code touches user fields classified as PII in .claude/knowledge/data-model.md, or when adding new such fields.
---

# PII Handling

## When this applies

Any code path that:
- Reads or writes a field tagged PII (any tier) in `data-model.md`
- Logs anything user-shaped (user object, request body, error with user context)
- Sends user data to a third party (analytics, error tracking, AI APIs, marketing, email)
- Stores user data in a new place (cache, queue, log, file, external DB)

## PII tiers (mirrors `data-model.md`)

- **YES (high):** SSN, financial account numbers, brokerage account IDs, full credit card, health data, full address, DOB, biometric, government ID, geolocation, kids' data.
- **YES (medium):** email, phone, full name, IP address, device ID, account-linked username.
- **YES (low):** first name, city, generic preferences (still PII under GDPR).
- **no:** opaque IDs (UUIDs not tied to identity), aggregates, public posts the user explicitly published.

## Core rules

### Redact before log
Every log statement that *could* include PII must redact. Two patterns:

```ts
// GOOD — explicit fields
logger.info('user signed in', { userId: user.id });

// GOOD — redacted serializer
logger.info('user signed in', { user: redactPii(user) });

// BAD — whole object
logger.info('user signed in', { user });
logger.error('failure', error);  // error message may quote payload
```

Where `redactPii(user)` keeps `id`, drops `email`/`phone`/`name`/`dob`, partial-masks if you must keep something (`a***@example.com`).

### Encryption at rest
- PII (high) fields: column-level encryption or KMS envelope encryption. Plaintext = block.
- PII (medium) fields: column encryption strongly preferred; tablespace-level encryption (RDS at-rest) is the minimum.
- Backups inherit encryption — check this is explicit, not assumed.

### Encryption in transit
- TLS only — no `http://` to a server. Block `http://` URLs going to anywhere except `localhost`.
- Internal-network calls (Lambda → RDS via VPC) — TLS still recommended; some teams skip and rely on VPC isolation. Document the choice.

### Third-party egress
- Default: redact PII before sending to *any* third party.
- Sentry / Datadog / Bugsnag: scrub PII from error contexts. They have SDK config for this (`beforeSend`, `setUser` with only an ID, etc.) — use it.
- Analytics (PostHog, Amplitude, Mixpanel): use opaque user IDs; never raw emails.
- AI APIs (OpenAI, Anthropic, Gemini): treat as third party. PII in prompts goes off-system. Redact or get explicit consent.
- Email senders (SendGrid, Postmark): obviously they need the email — but log only success/fail, not the email content.

### Right-to-erasure code paths
- Account deletion must purge or anonymize every PII field.
- Soft-delete + anonymize is acceptable for business records that reference users (keep order history, replace user_id with NULL or a "deleted-user" sentinel).
- Cascade through caches, queues, search indexes, backups (subject to retention policy).

## Anti-patterns (block on sight)

- `console.log(user)` / `console.log(req.body)` in production code
- `Sentry.captureException(error)` with raw error containing PII
- `analytics.track('event', { email: user.email })`
- Storing emails / phones / names in cache keys (they end up in logs)
- "user data" CSV exports without auth
- Mailing-list buildouts that include unsubscribed users
- Hardcoded `user_id = 1` "for testing" in production paths

## Where to put redaction logic

One central util: `lib/security/redact.ts` (Next.js) or `app/security/redact.py` (Python). All loggers wrap through it. All third-party SDK init calls reference it.
