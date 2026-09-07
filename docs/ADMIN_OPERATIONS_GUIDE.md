# React admin operations guide

SOUL uses a custom Laravel + React admin. It has no paid admin-panel dependency. Laravel authorizes every operation; hiding a React button is never the security control.

## Roles

- Moderators review reports, verification and safety cases.
- Super-admins additionally manage users, operator accounts, religion taxonomy, broadcasts, events, subscriptions, translations, spoken languages and operational privacy/account summaries.
- Sensitive writes require a reason and create an immutable audit record.

## Catalogs and localization

Source JSON files define the allowed translation keys and safe fallback. A super-admin may override an existing key for a configured locale. Unknown keys are rejected so the API, Flutter and React catalogs cannot silently drift. Overrides take effect in bootstrap immediately and keep the base files unchanged for rollback.

Spoken-language options can be renamed, ordered or deactivated. Deactivation hides future selection without deleting existing member data. Interests and personality traits are member-provided bounded values in V1, not global admin taxonomies.

## Privacy and account operations

The operations screen shows provider counts, privacy-mode counts, export statuses and scheduled deletions. Provider identity IDs, export file paths, contact hashes, messages and private media are never returned. Members remain the only actors allowed to request/download exports or cancel deletion during recovery.

## Subscription operations

Features, plans, allocations, products and promotions can be created and changed through authorized endpoints. Retiring/deactivating configuration preserves historical subscriptions and audit evidence. Store prices remain owned by Apple/Google.

## Operator checklist

1. Confirm the correct environment and role.
2. Review current state before editing.
3. Enter a clear operational reason.
4. Make one bounded change.
5. Confirm the audit entry and member-facing result.
6. Never paste secrets, raw identity documents or private messages into reasons.
