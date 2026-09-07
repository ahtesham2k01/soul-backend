# SOUL V1 release closure

This checklist separates completed software from work that can only happen in staging or production. No production deployment is authorized by this document.

## Completed release-candidate evidence

- All 23 numbered PRD sections have an explicit implementation or deliberate-deferment row.
- Laravel routes, Flutter handoff, OpenAPI and Postman contracts are synchronized by automated tests.
- Mobile actions use Laravel authorization and validation; React administration uses role-protected same-origin sessions.
- Database changes are versioned migrations with rollback methods.
- Sensitive provider identifiers, secrets, identity evidence and private export paths are excluded from public contracts.
- PHP tests, React production build, Composer validation and dependency audits run in CI.
- Operations include readiness checks, cleanup scheduling, queue jobs, security headers and a non-destructive smoke command.

## Staging gates before approval

- [ ] Configure MySQL, Redis, durable private storage, HTTPS, queue workers and scheduler.
- [ ] Configure Cloudinary uploads, moderation callbacks and authenticated private delivery.
- [ ] Configure Google and Apple sign-in credentials and verify real-device flows.
- [ ] Configure APNs/FCM and transactional email; test delivery, retry and deduplication.
- [ ] Configure Apple/Google store products and receipt/server-notification verification.
- [ ] Publish jurisdiction-reviewed Terms, Privacy Policy and Community Guidelines versions.
- [ ] Run `php artisan soul:config-check --production` with staging-equivalent secrets.
- [ ] Run `php artisan soul:smoke --base-url=<staging-url>` and the authenticated manual journeys below.
- [ ] Perform load tests, backup restore test and rollback rehearsal.
- [ ] Obtain product, security and deployment approval.

## Authenticated staging journeys

1. Create account, verify OTP, accept current legal documents and finish onboarding.
2. Upload/moderate photos, submit the profile and confirm correction and live states.
3. Exercise discovery filters, Like acceptance, match, message, read receipt and unmatch.
4. Request/revoke private-photo access and verify protected media behavior on Android and iOS.
5. Report/block a member and complete moderation, verification and appeal paths in React admin.
6. Join/leave and report an event; publish/cancel it from React admin.
7. Validate plan entitlements, counters and store receipt notifications in sandbox stores.
8. Request a private export and schedule/cancel account deletion inside the recovery window.

## Release decision

The repository is a V1 software release candidate when CI is green. It becomes launch-ready only when every staging gate above has evidence and the release owner approves deployment. Exact pricing, production secrets and jurisdiction-specific legal approval remain outside source-code assumptions.
