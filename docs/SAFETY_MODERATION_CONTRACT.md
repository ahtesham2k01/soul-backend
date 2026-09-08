# Safety, reporting and moderation

This document explains the complete V1 safety flow in simple terms. Laravel is authoritative; Flutter and React render the state returned by the API.

## Reporting from Flutter

The report screen offers two explicit actions:

- `report_only`: submit the report and keep the existing interaction state.
- `report_and_block`: create the report and block the member in one database transaction.

For Report & Block, match closure, private-photo revocation and decision cleanup happen together. Flutter must send one report request; it must not call Report and Block separately.

An `underage` report immediately pauses the reported profile, creates a critical safety case and creates a required identity/age verification case. The reporter receives no private moderation information.

## Risk and moderator flow

Reports enter the React admin queue. A moderator can resolve, dismiss or pause a profile for risk review. A paused report creates a separate safety case so the decision has a durable reason and audit trail.

Open safety cases can be cleared or marked `verification_required`. Clearing the final open case restores a safety-paused profile. Requiring verification keeps it paused and creates an ID/age case. There is deliberately no public fixed report-count threshold.

## Blocked-account appeal

A blocked member may submit exactly one account appeal through the restricted authenticated appeal endpoints. Every normal active-account endpoint remains forbidden. The existing token is retained only to reach this restricted appeal flow; registered push devices are revoked.

Moderators can read the appeal queue. Only a super-admin can accept or reject an appeal, a decision can happen once, and the reason is written to the immutable audit log. Acceptance restores account access; rejection keeps the account blocked.

## Client privacy rules

- Never show reporter identity to the reported member.
- Never expose risk scores, internal IDs, reviewer identity or audit records in Flutter.
- Do not promise a review deadline.
- Keep reporting, blocking and appeals available without subscription checks.
- Treat unavailable profile responses as non-enumerating.
