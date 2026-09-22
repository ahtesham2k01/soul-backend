# Product Requirements — SOUL V1

> **Authority:** This is a role-specific working guide derived from `docs/SOUL_V1_MASTER_DOCUMENTATION.md`. The master document remains the single product source of truth. If this guide and the master ever disagree, follow the master and update this guide in the same change.

## Audience

Product owner, stakeholder, engineering leads, design, QA and anyone deciding what SOUL Version 1 must or must not do.

## Product definition

SOUL is a privacy-conscious global relationship and matchmaking product for adults. Version 1 supports three visible intentions: Marriage, Serious relationship and Casual dating. The product is designed for multiple religions and cultures rather than a single hard-coded community.

The core differentiation is a country-aware religion hierarchy:

`Religion → Sect/Tradition → Sub-sect/School/Movement → Caste/Community`

Levels that do not exist for a member's selected religion/country are skipped dynamically. Version 1 discovery uses religion at the root level; deeper sect/sub-sect/caste ranking is intentionally deferred.

## Product goals

Version 1 must:

- let adults create and safely recover an account using Email, Apple or Google;
- provide resumable onboarding and real city/country resolution with a manual fallback;
- collect required profile information without exposing exact date of birth or exact coordinates;
- support public/private photos, moderation and protected private-photo access after a match;
- provide discovery, filters, Like/Pass, incoming requests, matches and text/emoji chat;
- expose verification, reporting, blocking, appeals and moderation paths;
- support events, notifications, privacy controls and dynamic subscriptions;
- remain multilingual, admin-configurable and globally extensible;
- feel like a polished international consumer app, not a form over a database.

## Required profile information

A profile cannot go live until server readiness confirms the required fields, including name, adult DOB, gender, current city/country, nationality, religion/belief, marital status, intention, profession/status, spoken language, smoking/alcohol/children answers and required photo conditions.

Optional fields support three meaningful states where relevant: unanswered/Skip, answered, and Prefer not to say.

## Discovery rules

- Default audience uses the documented Man/Woman model and opposite-gender matching.
- Default religion mode is My Religion; members may select All Religions.
- Supported filters remain server-authoritative.
- Exact live location is never shown; only permitted distance bands may be returned.
- Passed profiles may resurface after the documented cooling period.
- Incognito and profile pause are supported.
- Inactive accounts are progressively deprioritized/hidden as defined in the master.

## Interaction rules

- Like creates a pending decision unless reciprocity creates a match.
- A pending Like may be withdrawn before match creation.
- Either matched member may start chat.
- Version 1 chat is text/emoji only.
- Read receipts, online/last-seen and typing state are part of V1.
- Unmatch removes the visible conversation for both members and revokes private-photo access.

## Privacy and safety

Core safety actions are never paywalled. Reporting supports the authoritative categories in the master. Risk may pause or hide a profile and escalate to human review. Underage suspicion triggers the age/ID path. Exact coordinates, provider secrets, private media identifiers and sensitive values must never leak to member UI/logs.

## Verification

Email, phone, selfie/face and ID/age verification remain separate states. Optional badges must not be treated as universally mandatory unless a risk/safety case explicitly requires verification.

## Launch-critical trust hardening

Before public launch, SOUL must add proactive abuse defenses beyond ordinary reporting:

- privacy-minimized suspicious account/session/device and behavioral risk signals;
- high-velocity mass-Like/message and repeated-account/ban-evasion detection;
- repeated/reused media checks where technically and legally appropriate;
- non-blocking scam-safety nudges for early off-platform/payment/credential-risk patterns;
- temporary risk restriction/queueing with human review for serious or disputed cases;
- safe moderator evidence, auditability and false-positive recovery.

These controls must not create a public member reputation score or leak exact location/private evidence.

Selfie verification remains **optional/risk-required under the current flow** until the product owner separately approves a mandatory rule. A pre-launch decision on that question is required; this guide does not change it implicitly.

## Subscription

Plans, prices and entitlement allocation are dynamic. Flutter must not hard-code product pricing or paywall decisions. Laravel authorizes the action; the app renders effective capabilities and store-provided pricing.

## Premium experience requirement

Functional correctness alone is not acceptance. Every member-facing feature must satisfy the Premium Product Experience Standard in the master: design consistency, complete states, motion/reduced motion, sensible haptics, perceived performance, accessibility, localization/RTL, keyboard/safe-area behavior, retry/recovery, privacy and product-owner visual review.

## Post-launch priorities — not V1 launch blockers

After launch-critical safety/provider/premium closure, prioritize:

- richer compatibility preferences/soft ranking using existing profile answers;
- profile prompts/icebreakers;
- controlled referral/invite growth;
- optional success/offboarding feedback;
- a Safety Center and optional trusted-person date sharing;
- later notification quiet-hours/digest and conversation-quality nudges.

Privacy-blur/reveal requires a separate product decision because it conflicts with the current public-cover requirement.

## Explicit V1 deferrals

The following are intentionally outside Version 1 and must not be reintroduced accidentally:

- chat photos;
- voice notes;
- audio calls;
- video calls;
- chaperone/guardian functionality;
- deep sect/sub-sect/caste matching and must-have filters;
- public user-created events;
- visitor/profile-view tracking and boost mechanics until separately contracted;
- jurisdiction-specific expansion rules that require legal approval.

## Definition of done

A feature is done only when server rules, client behavior, all important states, permissions, safety/privacy, localization, accessibility, tests, documentation and any required physical-device/provider verification are complete. “It works on the happy path” is not completion.

## Change governance

Any material change to user expectations, sensitive data collection, irreversible moderation policy, pricing, legal wording or deferred V1 scope requires explicit owner approval. Update the master first, then synchronize all affected role guides and machine contracts.
