# SOUL V1 backend scope and status

This document prevents “API exists” from being confused with “the full product requirement is complete.” The confirmed product requirements are authoritative; this matrix records the current implementation boundary and the remaining gap-closure phase.

## Technology and ownership

- Laravel 13 / PHP 8.3 JSON API.
- Sanctum bearer authentication for Flutter; secure same-origin session authentication for the custom React admin.
- Relational database with migrations, foreign keys and indexed cursor feeds.
- Queued jobs for provider cleanup, exports, broadcasts and scheduled deletion.
- Cloudinary direct upload/moderation integration; Cloudflare-aware bootstrap/location boundary.
- Laravel-managed translation catalogs and dynamic configuration.
- OpenAPI 3.1 and Postman contracts generated from the maintained API handoff.

Laravel owns every protected decision. Flutter owns presentation, platform permissions and safe local caching. React admin owns operator workflows but may act only through authorized Laravel endpoints.

## Current implemented foundation

| Area | Implemented now | Remaining V1 scope |
|---|---|---|
| Bootstrap/localization | Locale negotiation, version/hash, direction, 320-key V1 catalog, complete English/Roman Urdu copy and React admin language switching | Human-reviewed copy for remaining configured languages as translation work becomes available |
| Authentication | Email registration/login OTP, Apple, Google, linked social identities, tokens, current user, logout/all | Active-device session listing/remote logout parity and duplicate merge hardening where needed |
| Profile onboarding | Draft save/resume, all required V1 answers, optional details, interests/traits, Skip versus Prefer-not-to-say state, religion selection, readiness/lifecycle | Public full-profile presentation continues with discovery/privacy phases |
| Religion | Future-ready hierarchy, translations, complete-path country validation, saved leaf/root selection, persistent My Religion/All Religions discovery and admin taxonomy | Full-profile detailed-field presentation remains coupled to public-profile/privacy work |
| Photos | Three slots, authenticated secondary uploads, moderation, private access request/approval/revocation, protected no-store delivery, screenshot controls/signals | Provider staging verification and mobile-native protected-view implementation |
| Discovery | Gender/age/religion/intention/location/radius filters, activity ranking, 90-day hiding, safe distance bands, pass resurfacing and likes exclusion | Entitlement-dependent filter limits remain dynamic subscription work |
| Likes/matches/chat | Like/pass, incoming requests, accept/decline/withdraw, matches, summaries, unmatch, text messages, mandatory read receipts, online/last-seen and expiring typing signals | Provider-backed real-time transport may later replace polling without changing the V1 API contract |
| Verification | Separate email, phone, selfie and ID/age states; optional/required semantics; safe public badges; cases, review and one appeal | Underage escalation and broader risk automation (Phase 21) |
| Safety | Atomic Report/Report & Block, underage pause, risk cases, moderator decisions, blocked-account appeal and immutable audit | Provider-assisted risk signals can be added without changing the case contract |
| Notifications | Devices, separate push/email preferences, mandatory safety alerts, in-app feed, idempotent event creation, moderation/verification/account events and admin broadcasts | APNs/FCM and email provider credentials plus staging delivery verification |
| Events | Admin-created online/physical events, localization, publishing, capacity-safe registration, attendee privacy and report moderation | Provider-specific streaming/venue integrations are outside the V1 contract |
| Subscriptions | Dynamic features, plans, limits/counters, country/platform/user overrides, rollouts, trials/promotions and store-product catalog | Apple/Google credentials and server receipt-notification validation are staging/release gates; exact prices and allocations remain launch decisions |
| Privacy/account | Settings, screenshot protection, profile pause, incognito, keyed contact hiding, private export, 30-day deletion recovery, versioned Terms/Privacy/Guidelines and community commitments | Provider/country-specific legal content publication remains a release-owner responsibility |
| Admin | Dashboard, users, reports, safety cases, verification, appeals, admins/roles, taxonomy, broadcasts, events, subscriptions, localization/spoken-language catalogs, privacy/account operations and audit | Provider secrets, raw identity documents, messages and arbitrary database editing are intentionally excluded |
| Operations | Health/readiness, telemetry, security headers, cleanup schedules, CI audits and runbook | Staging/provider credentials, load tests, observability targets and deployment approval |

## Gap-closure phases

- [x] Phase 12 — Core rule corrections
- [x] Phase 13 — Complete English/Roman Urdu localization across mobile API and React admin
- [x] Phase 14 — Required/optional profile-field parity
- [x] Phase 15 — Religion discovery hierarchy and country-rule parity
- [x] Phase 16 — Discovery filters, ranking and distance privacy
- [x] Phase 17 — Public/private photo access and screenshot protection
- [x] Phase 18 — Likes, requests, matches and chat parity
- [x] Phase 19 — Marital-status visibility and rules
- [x] Phase 20 — Verification and badge behavior
- [x] Phase 21 — Safety and moderation completion
- [x] Phase 22 — Notification event/channel coverage
- [x] Phase 23 — Events and admin management
- [x] Phase 24 — Subscription and dynamic entitlements
- [x] Phase 25 — Legal consent and account lifecycle
- [x] Phase 26 — Complete React admin module coverage
- [x] Phase 27 — End-to-end audit and release closure

## API and compatibility policy

- All mobile routes are under `/api/v1`; route names are unique and contract-tested.
- Public ULIDs are stable client identifiers. Internal database IDs and provider asset IDs stay private.
- Additive response fields are backward-compatible. Removing/renaming fields, changing meaning or tightening a previously valid enum requires version/change planning.
- Error codes drive client behavior; prose messages are for display and can be localized.
- Every list expected to grow uses cursor pagination or documents a bounded catalog.
- New protected actions require policies/middleware, validation, rate limits, audit needs and negative authorization tests.
- Generated OpenAPI/Postman files must match Laravel routes before merge.

## Admin scope policy

The custom admin is Laravel + React and has no paid panel dependency. It must eventually expose every genuinely configurable or reviewable V1 domain, but not raw database editing.

Moderator scope: report/verification review and allowed safety actions. Super-admin scope: operator accounts/roles, taxonomy, user account actions, broadcasts and future events/entitlements/configuration. Sensitive changes require a reason, authorization, session protection and immutable audit event.

## Explicitly outside V1

- Chat photos, voice notes, audio/video calls.
- Deep sect/sub-sect/caste matching and must-have filters.
- Chaperone/guardian system.
- Public user-created events.
- Final subscription prices, tiers and allocations until launch decisions are confirmed.
- Country-specific legal expansion that requires jurisdiction review.

## Definition of complete

A phase is checked only when its migrations/models/services, authorized APIs, React administration where applicable, Flutter contract, automated tests, documentation and CI are complete. A local implementation without provider/staging verification is reported separately rather than called production-ready.
