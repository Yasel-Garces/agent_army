# Data Model

> **[TODO: replace this banner once filled in. This file drives the security-reviewer and data-compliance agents — be accurate.]**

## Entities

### `user`

| field | type | PII? | notes |
|---|---|---|---|
| id | uuid | no | |
| email | string | **YES (medium)** | encrypted-at-rest? |
| name | string | YES (low) | |
| date_of_birth | date | **YES (high)** | |

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
