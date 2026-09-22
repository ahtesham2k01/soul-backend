# Operations & DevOps Runbook — SOUL V1

> **Authority:** This is a role-specific working guide derived from `docs/SOUL_V1_MASTER_DOCUMENTATION.md`. The master document remains the single product source of truth. If this guide and the master ever disagree, follow the master and update this guide in the same change.

## Purpose

Provide operators and engineers a safe path to configure, deploy, verify, monitor and recover SOUL without treating a green local test suite as production readiness.

## Environments

Keep local/test, staging and production configuration isolated. Store/provider identifiers and secrets are environment-specific and must never be committed.

Production-like verification should use MySQL/PostgreSQL-compatible settings as configured, Redis for cache/queues, secure session settings and approved provider credentials.

## Pre-deploy

Before a release:

- review migration status;
- run required CI/audits;
- verify generated contracts;
- verify localization checks;
- confirm provider-readiness/config check;
- confirm backup freshness policy;
- review unresolved operational incidents;
- confirm rollback artifact/process.

## Deploy

Typical safe flow:

1. deploy the reviewed artifact;
2. install production dependencies deterministically;
3. run migrations;
4. seed only stable catalog baselines where required;
5. cache Laravel config/routes/views;
6. restart queue workers;
7. confirm scheduler;
8. run readiness/health/smoke checks;
9. validate authenticated critical journeys in staging/controlled production;
10. monitor errors, latency and queue depth.

## Provider gates

Source integration is not equivalent to provider readiness. Explicitly verify relevant:

- Apple/Google identity credentials;
- APNs/FCM;
- email provider;
- Cloudinary signing/moderation;
- GPS reverse geocoding;
- App Store/Play Store billing and callbacks;
- broadcast/realtime transport.

## Database/cache/queues

Migrations must remain reversible/tested as documented. Redis-style cache/queue failures must surface in readiness/ops checks rather than silently degrading critical work.

Do not manually “repair” production data without an approved, auditable procedure.

## Backups and restore

Maintain encrypted backups according to the approved infrastructure policy. Periodically perform isolated restore tests and record evidence externally. A backup that has never been restored is not proven recovery.

## Performance

Use synthetic disposable datasets and the repository performance commands to obtain warmed baselines. Load testing requires explicit staging approval; do not run uncontrolled production load tests during deployment.

## Monitoring

Track at minimum:

- health/readiness;
- API/server errors;
- queue backlog/failures;
- slow queries;
- provider delivery failures;
- critical incidents;
- latency/performance trends;
- store/notification webhook health.

Logs must retain request correlation while redacting member secrets/content.

## Incidents

Warnings/critical conditions are reconciled into durable incidents. Critical incidents require the documented escalation/acknowledgement expectations. Acknowledge/resolve with operational reasons and preserve audit history.

## Rollback

Rollback should use the previous reviewed artifact and a database-safe plan. Never reverse a destructive migration blindly if data compatibility has changed.

## Smoke journeys

Critical smoke coverage includes auth, onboarding, discovery, messaging, moderation/safety and privacy/account paths plus provider-specific checks relevant to the release.

## Release ownership

Engineering may automate checks, but final production release also requires business/legal/store/provider approvals where applicable.

## V1 scope

Operations should not provision or claim support for deferred chat photos, voice notes, audio/video calls or guardian/chaperone features.
