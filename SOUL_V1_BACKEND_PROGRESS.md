# SOUL V1 Backend Progress

- [x] Phase 1 — Foundation, localization and bootstrap
- [x] Phase 2 — Authentication and sessions
- [x] Phase 3 — Location resolution
- [x] Phase 4 — Religion taxonomy and selection
- [x] Phase 5 — Onboarding profile drafts
- [x] Phase 6 — Profile photo upload and lifecycle
- [x] Phase 7 — Photo moderation and corrections
- [x] Phase 8 — Submission, readiness, resubmission and audit history
- [x] Phase 9 — Discovery preferences and candidate eligibility
- [x] Phase 10 — Likes, passes and matches
- [x] Phase 11 — Messaging, blocking and reporting
- [x] Phase 12 — Safety, verification and appeals
- [x] Phase 13 — Notifications
- [x] Phase 14 — Custom React admin panel, moderation queues and audit controls
- [x] Phase 15 — Privacy settings, data export and deletion controls
- [x] Phase 16 — Performance, security and V1 release readiness

## Release candidate hardening

- [x] Previously decided profiles excluded from discovery
- [x] Hidden profiles protected from direct decision requests
- [x] Only live profiles can make discovery decisions
- [x] Suspended counterparts removed from matches and messaging
- [x] Candidate lookup query index added
- [x] Production health, cleanup and security controls documented
- [ ] Final PHP/React CI verification for release-candidate head

## Flutter handoff

- [x] Mobile authentication and response-envelope contract
- [x] All named V1 endpoints catalogued by feature
- [x] Cursor, retry, privacy and error-handling guidance
- [x] Cloudinary direct-upload sequence documented
- [x] Stable V1 enums and compatibility rules documented
- [x] Automated route-to-handoff drift test

## Machine-readable client contracts

- [x] OpenAPI 3.1 contract generated from handoff source
- [x] Importable Postman 2.1 collection
- [x] Safe request examples and bearer-token variables
- [x] Automated Laravel-route/OpenAPI/Postman parity tests

## Environment and staging readiness

- [x] Secret-safe configuration validator
- [x] Strict production-mode requirements
- [x] Non-destructive staging smoke command
- [x] Configurable private export storage disk
- [x] CI configuration validation
- [x] Automated command tests and operations runbook
