# QA & Release Guide — SOUL V1

> **Authority:** This is a role-specific working guide derived from `docs/SOUL_V1_MASTER_DOCUMENTATION.md`. The master document remains the single product source of truth. If this guide and the master ever disagree, follow the master and update this guide in the same change.

## QA objective

Release quality means correct business rules plus premium member experience. Passing unit tests alone does not make SOUL launch-ready.

## Test layers

Use a combination of:

- PHP unit/feature tests;
- migration/database tests;
- contract/OpenAPI/Postman drift checks;
- Flutter analyzer/widget/integration tests;
- React production build/tests;
- localization audits;
- security/dependency audits;
- synthetic performance/load checks;
- staging smoke tests;
- real-device/provider validation;
- manual premium UX review.

## Critical member journeys

Always validate:

1. cold launch and localization;
2. Email/Apple/Google auth;
3. new onboarding and resume;
4. location permission denial/manual fallback;
5. dynamic religion hierarchy;
6. photo upload/moderation/correction;
7. profile submit/lifecycle/correction;
8. discovery filters and pagination;
9. Like/Pass/withdraw/match;
10. chat send/read/typing/presence/retry;
11. private-photo request/approve/revoke;
12. report/block/unmatch/appeal;
13. verification;
14. notifications;
15. events;
16. subscriptions/purchase/restore;
17. profile/settings/privacy;
18. export/deletion/recovery;
19. device sessions/logout;
20. restricted/blocked/suspended states.

## Premium-state matrix

For each member-facing surface, verify all applicable states:

- initial loading;
- skeleton/progressive loading;
- populated success;
- empty/exhausted;
- offline;
- timeout/provider failure;
- validation failure;
- retry;
- permission denied;
- restricted account;
- session expiry;
- background/resume;
- LTR and RTL;
- large text;
- reduced motion;
- small-screen/safe area;
- keyboard open;
- slow network.

A happy-path screenshot is not enough.

## Visual/interaction QA

Check shared tokens, typography hierarchy, spacing, component consistency, transition timing, haptics, disabled/loading states, bottom sheets/dialogs, back gestures and unsaved-change handling.

A screen that works but visibly feels unfinished fails the quality gate.

## Performance QA

Check for scroll/swipe/chat jank, oversized images, repeated unnecessary requests, cache misuse and long UI-thread tasks. Use repository performance tooling for backend baselines and physical devices for real UI behavior.

## Localization QA

Draft catalog completeness is separate from launch readiness. Validate native wording, truncation, wrapping, punctuation, font fallback, RTL mirroring and text scaling on Android/iOS.

Roman Urdu is LTR.

## Security/privacy QA

Verify that tokens, OTPs, exact coordinates, private-media identifiers and message bodies do not leak into logs, analytics or crash reports. Confirm auth/authorization negative cases and deep-link guards.

## Provider/device release gates

Real launch requires evidence for relevant items such as:

- Apple/Google sign-in;
- APNs/FCM delivery;
- store product purchase/restore/webhooks;
- signing/capabilities;
- Cloudinary behavior;
- GPS reverse geocoding;
- screenshot/capture controls;
- accessibility/RTL on physical devices.

## Regression rule

Do not rerun the entire expensive release suite after every tiny edit. Complete the feature/fix package first, run focused checks during development, then run the appropriate full CI/release gate at the end of the package.

## Release decision

A release candidate may ship only when required CI is green, staging/provider gates are satisfied, critical journeys pass, unresolved severity blockers are zero and the premium UX audit has no unexplained launch-blocking gap.

Voice notes, chat photos, audio/video calls and guardian/chaperone are intentionally deferred and do not fail V1 QA merely by being absent.
