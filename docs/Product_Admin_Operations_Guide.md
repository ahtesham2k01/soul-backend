# Admin & Moderation Operations Guide — SOUL V1

> **Authority:** This is a role-specific working guide derived from `docs/SOUL_V1_MASTER_DOCUMENTATION.md`. The master document remains the single product source of truth. If this guide and the master ever disagree, follow the master and update this guide in the same change.

## Audience

Super-admins, moderators, support operators and operational owners using the custom Laravel + React administration interface.

The admin UI is intentionally English-only even though member content/catalogs are multilingual.

## Principles

- Admin is a controlled operational surface, not arbitrary database editing.
- Access follows roles and least privilege.
- Sensitive changes require a reason where defined and produce immutable audit records.
- Provider secrets, raw tokens, message bodies and unnecessary identity-document data must not be exposed in general admin views.

## Main operational areas

The admin covers:

- dashboard/operations health;
- member accounts and lifecycle;
- reports and safety cases;
- verification review;
- appeals;
- admin users/roles;
- religion taxonomy;
- interests/traits and spoken-language catalogs;
- localization;
- broadcasts/notifications;
- events;
- subscriptions/features/entitlements;
- privacy/account operations;
- audit history.

## Moderator responsibilities

Moderators handle allowed report, safety, verification and appeal decisions. They must use evidence available in the authorized workflow, record accurate reasons and avoid off-platform/unlogged account manipulation.

A moderator must never disclose reporter identity or private internal risk data to members unless a specific product/legal flow authorizes it.

## Super-admin responsibilities

Super-admins manage operator roles, taxonomy/configuration, broadcasts, events, subscription configuration, localization and sensitive account operations exposed by the product.

Changes to pricing, legal wording, jurisdiction policy, irreversible moderation behavior or sensitive data collection remain owner/legal decisions even if a configuration screen technically exists.

## Safety cases

Use the documented categories and case state. Underage suspicion follows the age/ID escalation path. Serious/disputed cases receive human review. Blocking/reporting/appeals are never paywalled.

Do not invent fixed public report thresholds or disclose risk-scoring implementation to members.

## Verification

Treat email, phone, selfie and ID/age verification as separate states. Review only the evidence needed by the active case. Optional verification requests should not be converted into universal mandatory requirements.

## Taxonomy

Religion, sect/tradition, sub-sect/school/movement and community/caste are data-driven. Maintain country/rule relationships carefully. A taxonomy edit can change onboarding behavior, so validate its child hierarchy and translations before activation.

## Localization

Member catalogs may be edited/reviewed while admin remains English. Do not mark a language launch-ready merely because machine/draft coverage is complete; native review and visual/device QA are release requirements.

## Subscriptions

Plans/features/limits/rollouts/promotions are dynamic. Never hide or paywall the protected safety/privacy/account capabilities listed in the master.

Store product mappings must correspond to real Apple/Google products before launch.

## Broadcasts

Broadcasts must respect category/consent policy. Safety/transactional communication and marketing are not interchangeable. Avoid spammy or deceptive notification copy.

## Events

Version 1 events are admin-approved. Confirm date/time, location/online mode, capacity, localized content and attendee-privacy expectations before publishing.

## Account/privacy operations

Use the supported export, deletion/recovery, blocking and device/session workflows. Do not manually edit database rows to “fix” a member unless an engineering runbook explicitly provides an audited repair procedure.

## Operational incidents

Use the Operations surface for warnings/critical incidents, acknowledgement and resolution with reasons. Provider credentials themselves must never appear in the UI; readiness should expose safe status/missing-variable information only.

## Escalate instead of guessing

Escalate to engineering/product/legal when a case requires an unavailable action, contradicts policy, involves jurisdiction-specific retention/legal hold, or could materially change member rights.
