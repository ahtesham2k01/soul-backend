# Architecture & Data Design — SOUL V1

> **Authority:** This is a role-specific working guide derived from `docs/SOUL_V1_MASTER_DOCUMENTATION.md`. The master document remains the single product source of truth. If this guide and the master ever disagree, follow the master and update this guide in the same change.

## System overview

SOUL consists of:

- Flutter member application for Android/iOS;
- Laravel 13 / PHP 8.3 backend/API;
- custom Laravel + React administration;
- relational primary database;
- Redis-style production cache/queue dependency;
- Cloudinary media delivery/moderation boundary;
- APNs/FCM/email notification providers;
- Apple/Google identity and store integrations;
- Cloudflare-aware approximate IP location plus pluggable GPS reverse geocoding.

## Authority boundaries

Laravel owns protected business decisions. Flutter owns presentation, native permissions and safe local caching. React admin owns authorized operator workflows. External providers never become the source of truth for SOUL business state without server validation.

## Identity model

One member account may link Email, Google and Apple identities. Duplicate-account merge is conservative and audited. Active device sessions are separately visible/revocable.

Use public ULIDs in client contracts. Internal database IDs stay internal.

## Profile model

Profile data separates:

- required core identity/eligibility;
- optional profile detail;
- privacy/withheld state;
- location/residence;
- languages/interests/traits;
- religion hierarchy;
- lifecycle/moderation state;
- photos/media;
- verification badges/cases.

Exact DOB and exact coordinates are private.

## Religion taxonomy

Future-ready hierarchy:

`Religion → Sect/Tradition → Sub-sect/School/Movement → Caste/Community`

Taxonomy is multilingual and country-aware. Client screens are dynamic and should not assume a fixed depth.

## Interaction model

Primary interaction entities cover:

- discovery preferences/candidate decisions;
- Likes/passes;
- matches;
- conversations/messages;
- presence/typing/read state;
- block/report;
- private-photo grants.

Visibility and safety/audit retention may differ; deleting something from the member UI does not imply all safety evidence disappears immediately.

## Media model

Three photo slots are supported in V1. Cover/public/private rules and clear-face requirements are server validated.

Direct upload uses a signed provider session; private delivery is re-authorized through Laravel. Provider asset internals are not member API identifiers.

## Abuse-risk model

The safety architecture should support privacy-minimized risk evidence such as:

- account/session/device associations needed for ban-evasion prevention;
- coarse network/context signals;
- behavioral velocity counters/windows;
- enforcement/report history;
- approved media fingerprint/similarity evidence;
- message-safety reason codes for member nudges.

Store normalized reason codes/evidence references rather than copying unnecessary private content into generic risk tables. Risk signals may feed temporary restrictions/cases; final irreversible decisions should retain human-review/audit boundaries where practical.

Do not expose the internal risk graph to member APIs.

## Safety/verification model

Verification types are independent. Safety includes reports, risk cases, moderator decisions and appeals with immutable/audited transitions where required.

Selfie verification remains optional/risk-required until an explicit owner-approved launch decision changes that contract.

## Subscription model

Features, plans, entitlements, usage counters/limits, country/platform overrides, user overrides, promotions, trials and percentage rollouts are server-managed.

Store products map to platform billing objects but do not replace Laravel authorization.

## Localization/config model

Member translation catalogs are server-delivered with locale, fallback, direction, version and hash. Flutter may cache disposable catalogs and effective config. Admin stays English-only.

## Operational model

Queues handle provider work and scheduled processes. Health/readiness, request correlation, slow-query warnings, incident reconciliation and backup/restore runbooks support production operation.

## Data design principles

- foreign keys and explicit indexes;
- stable public IDs;
- cursor indexes for growing feeds;
- least-sensitive API responses;
- no arbitrary raw DB editing from admin;
- audit immutable sensitive operator actions;
- idempotency/replay protection at external callback boundaries;
- retention/deletion behavior follows approved policy rather than ad hoc cascades.

## Machine contracts

Use the generated artifacts under `docs/contracts/` for endpoint/model truth. Do not duplicate full endpoint schemas manually in this document.

## Performance-sensitive areas

Discovery candidate lookup, decisions/blocks, matches, notifications, messages, admin member lists, queues and active sessions require index/regression coverage.

## Deferred architecture

V1 intentionally avoids additional real-time/media complexity for chat photos, voice notes and audio/video calling, and does not include visitor/profile-view tracking, boost mechanics or a guardian/chaperone domain.
