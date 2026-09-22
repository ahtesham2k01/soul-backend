# Design & UX System — SOUL V1

> **Authority:** This is a role-specific working guide derived from `docs/SOUL_V1_MASTER_DOCUMENTATION.md`. The master document remains the single product source of truth. If this guide and the master ever disagree, follow the master and update this guide in the same change.

## Design objective

SOUL should feel calm, premium, trustworthy and international. The experience should communicate that this is a serious consumer product, not a generic template or a local form-based matrimonial app.

Competitors may be studied for quality expectations, but SOUL must not copy proprietary layouts, brand language, motion, artwork or interaction patterns.

## Source priority

The master product flow and contracts define what the product does. Figma defines visual intent only after it has been reconciled with the product rules.

If a required state is absent from Figma, design it rather than omitting it.

## Design tokens

Maintain centralized tokens for:

- brand/semantic colors;
- typography;
- spacing;
- radii;
- elevation;
- icon sizes;
- control heights;
- motion durations/easing;
- breakpoints/safe layout constraints.

Avoid screen-local magic numbers unless truly exceptional and documented.

## Visual hierarchy

Photos and primary member identity should lead discovery. Secondary profile detail belongs progressively deeper in the profile. Use whitespace and hierarchy rather than borders/dividers everywhere.

Keep one obvious primary action where possible.

## Components

Buttons, fields, chips, cards, sheets, dialogs, badges, list rows, navigation, loaders, empty states and error surfaces must be reusable components with consistent interaction states.

Every interactive component needs normal, pressed/focused, disabled and loading behavior where applicable.

## Motion

Motion should clarify state and create restrained delight. Use subtle transitions for navigation, Like/Pass feedback, matches, verification, profile completion and purchase success.

Respect reduced-motion settings. Motion must never block the next action or feel like a game/casino mechanic.

## Haptics

Use sparingly for decisive actions, match/success feedback and important warnings where platform conventions support it. Do not vibrate on every tap.

## Loading and empty states

Prefer skeleton/content placeholders for structured content when useful. Do not flash full-screen spinners for short operations.

Empty states should explain a useful next action. Discovery exhaustion may suggest valid filter/distance changes rather than a dead-end.

## Error/recovery

Use calm, human language. Never show raw provider/HTTP/exception text. Preserve form/upload progress when safe. Give a clear retry or correction path.

## Accessibility

Design for:

- meaningful screen-reader semantics;
- color-independent status meaning;
- WCAG AA contrast where applicable;
- large text/dynamic type;
- logical focus order;
- ~44pt iOS / 48dp Android practical touch targets;
- reduced motion;
- RTL.

## Localization/RTL

Design must survive text expansion. Do not shorten good translations to rescue a rigid layout.

Mirror appropriate navigation/layout in RTL while keeping media/content that has natural orientation unchanged. Roman Urdu remains LTR.

## Keyboard/safe areas

Inputs must remain visible above the keyboard. Sheets/dialogs/navigation must account for display cutouts, gesture areas and small screens. Android back and iOS swipe-back cannot silently discard meaningful unsaved work.

## Trust design

Verification, report/block, private photos, incognito, location privacy, deletion and permission explanations must be understandable and discoverable.

Do not visually subordinate safety/privacy controls to premium upsells.

## Subscription UX

Show paywalls at meaningful entitlement boundaries. Do not use fake scarcity, misleading countdowns, preselected expensive plans, hidden close affordances or punishment loops.

Let users experience product value before repeated monetization prompts.

## Emotional moments

Match, verification, profile completion and purchase success should feel distinct and rewarding without excessive confetti, streaks or manipulative gamification.

Negative/correction/safety states also require thoughtful premium design.

## Design acceptance

A high-visibility feature is not complete until product/Flutter/design review:

- token consistency;
- happy and unhappy states;
- motion/reduced motion;
- text scale;
- LTR/RTL;
- safe areas/keyboard;
- loading/performance perception;
- accessibility;
- trust/safety clarity.

## V1 boundary

Do not design production flows implying chat photos, voice notes, audio/video calls or chaperone/guardian functionality are available in V1.
