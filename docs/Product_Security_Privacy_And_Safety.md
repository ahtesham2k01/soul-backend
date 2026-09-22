# Security, Privacy & Safety — SOUL V1

> **Authority:** This is a role-specific working guide derived from `docs/SOUL_V1_MASTER_DOCUMENTATION.md`. The master document remains the single product source of truth. If this guide and the master ever disagree, follow the master and update this guide in the same change.

## Security goals

Protect member identity, exact location, private media, account access and safety workflows while keeping controls understandable to normal users.

## Authentication

Flutter uses bearer sessions; React admin uses secure same-origin sessions. Apple/Google identity tokens are verified server-side. Email OTPs and tokens must be rate-limited and redacted from logs.

Members can view active devices and revoke sessions.

## Authorization

Every protected backend action must re-check authorization. Hiding a Flutter button is never sufficient.

Negative authorization tests are required for sensitive routes.

## Sensitive data

Never expose or log unnecessarily:

- bearer/session tokens;
- OTPs;
- provider secrets;
- exact coordinates;
- raw private-media/provider identifiers;
- identity review material beyond authorized workflows;
- message bodies in general telemetry/crash reports.

## Location privacy

The backend may calculate exact distance internally, but members receive only allowed bands. Never present SOUL as live-location tracking.

## Photos/private media

Slot and clear-face rules are server enforced. Private-photo access requires the documented match/request/approval path and is revoked on unmatch/block.

Android/iOS screenshot/capture protection is best-effort and platform-dependent. Product copy must never promise impossible prevention.

## Verification

Keep Email, Phone, Selfie/Face and ID/Age separate. Optional badge verification does not automatically block a profile. Risk-required verification may pause access as documented.

## Reporting and blocking

Supported reporting categories come from the product contract. Report & Block is available. Blocking stops discovery/interaction. Safety actions are never paywalled.

## Underage/safety escalation

Underage suspicion pauses the relevant profile and invokes the age/ID path. Serious/disputed cases go to human moderation. Avoid simplistic public report thresholds.

## Appeals

Eligible banned/blocked-account decisions have one proper appeal path. Appeals and safety support remain accessible even when normal product access is denied where the master specifies recovery routing.

## Admin security

Use least privilege. Sensitive operator actions require authorization, reasons where defined and immutable audit. General admins must not see provider secrets, arbitrary message content or database editing tools.

## Abuse/fraud controls

Rate-limit login, messaging, reports, purchases, uploads and other sensitive paths according to risk. Use replay resistance for provider callbacks and safe idempotency for repeated events.

## Privacy/account lifecycle

Members may pause/incognito, hide contact matches, export data and schedule deletion with the documented recovery period. Final anonymization/legal-hold/evidence retention must follow approved policy rather than assumptions.

## Telemetry

Analytics should collect product behavior, not unnecessary private content. Redact exact location, messages, tokens, OTPs and private media values.

## Security testing

Include dependency audits, auth negative cases, replay tests, webhook authentication, privacy redaction, headers, rate limits, session expiry and deep-link guard tests.

## Incident response

Operational warnings/critical incidents should map to runbook codes and auditable acknowledgement/resolution. Secrets must not be copied into incident records.

## V1 boundary

Voice notes, chat photos, audio/video calling and guardian/chaperone are not V1 features; do not add new sensitive media/data collection for them without a product/security review.
