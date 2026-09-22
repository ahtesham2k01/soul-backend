# Localization, Content & Analytics Guide — SOUL V1

> **Authority:** This is a role-specific working guide derived from `docs/SOUL_V1_MASTER_DOCUMENTATION.md`. The master document remains the single product source of truth. If this guide and the master ever disagree, follow the master and update this guide in the same change.

## Scope

This guide governs member-language delivery, product copy quality and privacy-safe analytics. The React admin remains English-only.

## Localization architecture

Laravel is the source of truth for member translation catalogs. Bootstrap returns requested/matched/resolved locale, fallback, direction, version/hash and effective values as documented.

Flutter caches catalogs by version/hash and keeps the last valid catalog for safe startup.

## Language rules

- SOUL brand name is never translated.
- Roman Urdu uses Latin script and LTR.
- Arabic, Persian and Hebrew are RTL.
- Direction always comes from server metadata; do not hard-code language-name rules.
- Draft translation coverage is not the same as launch-ready/native-reviewed quality.

## Translation quality

Launch-ready copy must be naturally written for the target audience, not word-for-word machine language.

Review:

- grammar/tone;
- culturally awkward phrases;
- gender/context ambiguity;
- punctuation;
- interpolation variables;
- truncation/wrapping;
- font fallback;
- text expansion;
- RTL ordering;
- accessibility with large text.

Do not shorten a correct translation merely to fit a poorly designed control.

## Product voice

Member copy should be concise, respectful, calm and human.

Avoid:

- developer/internal terminology;
- manipulative urgency;
- shame-based language;
- excessive exclamation marks;
- accusatory safety wording beyond confirmed facts;
- clickbait notifications.

Safety/correction messages should explain the next valid action.

## Notification content

Transactional/safety and marketing communication are different. Marketing starts from explicit consent rules and must not imitate a safety/system alert.

Do not repeatedly manufacture “someone is waiting” urgency to force opens.

## Subscription content

Use clear benefit/limit/trial/renewal wording. Price and billing period should come from store/server truth, not Figma examples.

## Analytics objectives

Measure product health such as:

- onboarding funnel and drop-off;
- profile completion;
- discovery engagement;
- Like → match;
- match → conversation;
- retention;
- verification completion;
- report/safety funnels;
- subscription conversion/retention;
- error/retry funnels;
- performance regressions.

## Analytics privacy

Do not send unnecessary sensitive profile answers, message bodies, exact coordinates, OTPs, tokens, identity evidence or private-media values to analytics/crash systems.

Prefer stable event names and coarse context needed for product decisions.

## Event governance

New analytics events require:

- a clear product question;
- minimal payload;
- privacy review;
- documented naming;
- no duplicate competing event names for the same action.

## Experimentation

Feature rollouts may be percentage/country/platform controlled through server configuration. Experiments must not weaken safety/privacy, deceive users or create inconsistent legal/consent behavior.

## Quality feedback loop

Use analytics to identify high-abandonment steps, recurring errors, slow screens and weak conversion, then combine metrics with user/support feedback. Do not optimize a single metric at the expense of trust or long-term retention.
