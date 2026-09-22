# Backend Engineering Guide — SOUL V1

> **Authority:** This is a role-specific working guide derived from `docs/SOUL_V1_MASTER_DOCUMENTATION.md`. The master document remains the single product source of truth. If this guide and the master ever disagree, follow the master and update this guide in the same change.

## Stack and ownership

SOUL uses Laravel 13 / PHP 8.3 with a relational database, Redis-backed production-style cache/queues, Cloudinary media integration, provider-backed notifications/store flows and a custom React admin.

Laravel is authoritative for eligibility, visibility, moderation, entitlements, profile lifecycle and protected actions. Client-hidden UI is never authorization.

## API policy

The mobile API uses the stable `/api/v1` namespace. Public ULIDs are client identifiers; internal numeric IDs and provider secrets remain private.

Backward-compatible additive fields are allowed. Removing/renaming fields, changing meaning or narrowing a previously valid contract requires explicit compatibility planning.

Every growing feed must use cursor pagination or document a deliberate bounded catalog.

## Domain boundaries

Primary domains include:

- bootstrap/localization/config;
- authentication/sessions;
- profile/onboarding;
- religion taxonomy;
- location/discovery;
- photos/private access;
- likes/matches/chat;
- verification;
- safety/moderation/appeals;
- trust/abuse risk;
- notifications;
- events;
- subscriptions/entitlements;
- privacy/export/deletion;
- administration/operations.

Prefer domain services/policies over controller-embedded business logic.

## Authentication and authorization

Use Sanctum bearer auth for Flutter and secure same-origin session auth for React admin. Protected writes require validation, authorization, appropriate rate limiting and negative authorization tests.

Never return tokens from session-listing APIs. Sensitive account recovery paths must remain narrowly scoped.

## Location/privacy

Exact coordinates may be used internally when needed for discovery calculations but never returned to clients. Return only permitted bands. Rate-limit resolution and redact exact location from logs/telemetry.

## Media

Issue short-lived signed upload sessions. Flutter uploads directly to the provider and registers the signed result. Provider secrets and asset internals never enter member responses.

Private media access is server-authorized by match/access state and must be revoked on unmatch/block.

## Discovery

Candidate eligibility, activity handling, religion mode, filtering, prior decisions, blocks and distance rules belong on the server. Index queries that sit on hot discovery paths.

Do not implement deferred sect/sub-sect/caste ranking as an accidental side effect.

## Abuse/risk hardening

Add a dedicated risk layer without turning individual heuristics into final truth:

- privacy-minimized account/session/device/coarse-network features;
- velocity/rate-pattern detection for account recreation, Likes and unsolicited messaging;
- enforcement-linked repeat-account signals;
- safe media fingerprint/perceptual-similarity evidence where approved;
- explainable internal reason codes for moderator review;
- temporary action/profile restrictions with bounded expiry/review;
- false-positive recovery and immutable decision audit.

Any message-content safety classification must be narrowly scoped to abuse prevention. Raw messages must not flow into generic analytics/logging. Chat safety nudges should be idempotent/rate-limited so one conversation does not spam the member.

Do not silently enforce universal selfie verification; expose any future requirement through an explicit server capability/state after the product decision is approved.

## Messaging

V1 chat is text/emoji. Preserve idempotent writes/retries where the contract supports them. Read state, presence and typing must never weaken authorization. Safety/audit retention can outlive user-visible conversation state where documented.

## Verification and moderation

Keep email, phone, selfie and ID/age verification independent. Risk-required cases may pause a profile; optional badge requests do not universally gate live status.

Moderation decisions require authorization, reason/audit and clear appeal semantics.

## Subscriptions

Entitlements, limits, country/platform overrides, trials/promotions and rollout rules are dynamic. Laravel makes the authorization decision even if Flutter hides a control.

Store callbacks must be authenticated/reverified, replay-resistant and idempotent.

## Reliability

Queues/jobs require bounded execution, retries and fail-on-timeout behavior. Provider failures should degrade predictably without exposing secrets or leaving ambiguous member state.

Use request IDs, security headers, readiness checks, slow-query telemetry and operations incidents as defined in the master.

## Performance

Maintain indexes for discovery, decisions/blocks, matches, notifications, messages, sessions and admin feeds. Validate with the repository's synthetic performance tooling and approved staging load testing rather than assuming local latency equals production capacity.

## Testing expectations

Changes should include appropriate feature/unit/contract tests for:

- authorization failures;
- validation/error codes;
- pagination/cursor behavior;
- idempotency/replay boundaries;
- privacy redaction;
- migrations/indexes;
- provider webhook admission;
- localization/config contract drift;
- abuse-risk false positives and recovery.

## Documentation contract

When a backend behavior changes, update the master and generated contracts in the same feature package. Do not create undocumented “temporary” behavior for Flutter.

## Explicit non-goals for V1

Do not add chat photos, voice notes, audio/video calls, chaperone/guardian features, visitor/profile-view tracking, boost mechanics or deep sect/caste matchmaking unless the product owner explicitly changes V1 scope.
