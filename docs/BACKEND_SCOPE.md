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
| Bootstrap/localization | Locale negotiation, version/hash, direction, 282-key V1 catalog, complete English/Roman Urdu copy and React admin language switching | Human-reviewed copy for remaining configured languages as translation work becomes available |
| Authentication | Email registration/login OTP, Apple, Google, linked social identities, tokens, current user, logout/all | Active-device session listing/remote logout parity and duplicate merge hardening where needed |
| Profile onboarding | Draft save/resume, all required V1 answers, optional details, interests/traits, Skip versus Prefer-not-to-say state, religion selection, readiness/lifecycle | Public full-profile presentation continues with discovery/privacy phases |
| Religion | Future-ready hierarchy, translations, country rules, saved selection, admin taxonomy | Discovery-mode and display/privacy parity (Phase 15) |
| Photos | Three slots, signed upload sessions, moderation webhook, replacement/deletion cleanup, clear-face readiness | Private access grants and full screenshot contracts (Phase 17) |
| Discovery | Preferences, live eligibility, candidates, pass resurfacing, likes exclusion | Radius/locations, intentions, religion mode, incognito, contacts, inactivity and distance bands (Phase 16) |
| Likes/matches/chat | Like/pass, mutual match, matches, unmatch, text messages, mandatory read receipts | Like withdrawal, request acceptance semantics, presence/typing and private-photo revocation integration (Phase 18) |
| Verification | Cases, review states and one appeal | Separate badge/risk semantics and underage escalation parity (Phases 19–20) |
| Safety | Block, report categories, moderation queues and account actions | Report & Block transaction, risk cases, ban appeal and complete moderator tools (Phase 21) |
| Notifications | Devices, push preferences, feed, match/message events and admin broadcasts | Push/email separation and complete event coverage (Phase 22) |
| Privacy/account | Settings, private export, 30-day deletion recovery | Pause, incognito/contact privacy, detailed religion privacy and screenshot setting parity |
| Admin | Dashboard, users, reports, verification, admins/roles, taxonomy, broadcasts, audit | Events, entitlements, configuration, localization and remaining domain management (Phase 26) |
| Operations | Health/readiness, telemetry, security headers, cleanup schedules, CI audits and runbook | Staging/provider credentials, load tests, observability targets and deployment approval |

## Gap-closure phases

- [x] Phase 12 — Core rule corrections
- [x] Phase 13 — Complete English/Roman Urdu localization across mobile API and React admin
- [x] Phase 14 — Required/optional profile-field parity
- [ ] Phase 15 — Religion discovery hierarchy and country-rule parity
- [ ] Phase 16 — Discovery filters, ranking and distance privacy
- [ ] Phase 17 — Public/private photo access and screenshot protection
- [ ] Phase 18 — Likes, requests, matches and chat parity
- [ ] Phase 19 — Marital-status visibility and rules
- [ ] Phase 20 — Verification and badge behavior
- [ ] Phase 21 — Safety and moderation completion
- [ ] Phase 22 — Notification event/channel coverage
- [ ] Phase 23 — Events and admin management
- [ ] Phase 24 — Subscription and dynamic entitlements
- [ ] Phase 25 — Legal consent and account lifecycle
- [ ] Phase 26 — Complete React admin module coverage
- [ ] Phase 27 — End-to-end audit and release closure

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
