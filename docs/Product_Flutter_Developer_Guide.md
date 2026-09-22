# Flutter Developer Guide — SOUL V1

> **Authority:** This is a role-specific working guide derived from `docs/SOUL_V1_MASTER_DOCUMENTATION.md`. The master document remains the single product source of truth. If this guide and the master ever disagree, follow the master and update this guide in the same change.

## Source priority

When implementing the member app, use this order:

1. master product documentation;
2. generated member contracts in `docs/contracts/`;
3. this Flutter guide;
4. Figma/PDF handoff as presentation reference only.

Illustrative Figma names, locations, prices, Muslim-only wording, filters or screen logic must never override the product contract.

## App location

The member app lives in `apps/member_app`.

## Core architecture

Recommended modules remain auth, onboarding, discovery, activity, matches, chat, photos, verification, safety, notifications, events, subscription and settings. Networking must use typed DTOs/contracts rather than passing raw JSON maps through widgets.

Core concerns include:

- bearer session handling and expiry;
- request/error envelope parsing;
- localization/catalog caching;
- secure Keychain/Keystore token storage;
- safe navigation guards from authoritative account/profile state;
- media upload/delivery;
- retry/idempotency boundaries.

## Cold start

On launch:

1. load safe cached localization/config where available;
2. call bootstrap when required;
3. apply server-returned locale direction before rendering;
4. inspect secure session;
5. validate/refresh authoritative account state;
6. route to auth, onboarding/correction, legal re-consent or main app.

Never deep-link around onboarding, legal, subscription or safety authorization.

## Authentication

Email OTP, Google and Apple are supported. Native provider credentials are obtained on device and sent to Laravel for verification/session issuance. Do not log identity tokens, OTPs or bearer tokens.

## Onboarding

Persist each step through the backend and resume from the saved draft. Server readiness determines completion.

Religion screens are data-driven. Fetch child options and skip levels with no children. Never hard-code sect/caste screens or static country/religion lists.

Location uses the native permission flow plus the backend resolver. Permission denial must preserve manual city/country selection and must never substitute a fake default city.

## Photos

The app uses the signed upload-session flow and direct Cloudinary upload. Show progress, pending, approved, rejected and replacement states. Slot 1 remains the public cover. Never expose provider secrets or reconstruct private URLs.

Private-photo viewing is match-bound, server-authorized and stricter than public image caching.

## Discovery and activity

Render only filters supported by the backend contract. Use server-provided distance bands and never exact coordinates. Like, Pass, withdraw pending Like and reciprocal match feedback must remain state-consistent after restart/resume.

Pagination should prefetch before a hard stop where practical.

## Chat

V1 supports text/emoji, read receipts, presence/last seen and typing state. Preserve stable scroll position and clear send/retry state; avoid duplicate visible messages.

Chat photos, voice notes and audio/video calls are intentionally deferred.

## Trust and scam-safety UX

Flutter must render server-authoritative risk/correction states without inventing its own bans or hidden eligibility rules.

- Show concise, non-accusatory, non-blocking safety nudges when Laravel indicates an early-conversation scam/off-platform/payment/credential-risk pattern.
- A safety nudge should explain a safer action and allow normal conversation unless the backend has separately restricted the account/action.
- Do not duplicate the same nudge repeatedly in one conversation.
- Risk/correction screens must provide the authoritative verification, support or appeal route.
- Do not display internal risk scores, device/network evidence or exact reasons that would help attackers bypass detection.
- Selfie verification stays optional/risk-required until bootstrap/account state explicitly says otherwise after an approved product decision.

## Subscription

Do not hard-code plan names, prices, entitlement limits or country availability. Use effective capabilities from Laravel and localized product details from the stores. Paywalls must not trap the user or obscure free safety/privacy actions.

## Localization

- Bootstrap direction is authoritative.
- Roman Urdu is LTR.
- Arabic, Persian, Hebrew and any future RTL locale must render from server metadata, not language-name conditionals.
- Cache catalogs by version/hash with safe fallback.
- No member-facing hard-coded English on launch-ready localized journeys except approved brand/product terms.

## Premium UI standard

Use shared design tokens/components for typography, spacing, radius, icons, elevation, control sizes and motion. Add loading, empty, retry, offline, permission-denied, restricted-account and accessibility states even if Figma omits them.

Target smooth 60 fps interaction on the supported baseline device class. Keep expensive work off the UI thread. Use appropriately sized CDN images, bounded prefetch/cache, skeleton placeholders where useful and reduced-motion support.

Haptics should be deliberate, not global tap noise.

## Mobile polish

Test keyboard avoidance, safe areas, Android back, iOS swipe-back, bottom sheets, dialogs, small screens, text scaling and unsaved-change protection. Tap targets should follow platform accessibility expectations.

## Safety/privacy

Do not cache or log exact location, OTPs, tokens, message bodies or private-media values in crash/analytics telemetry. Screenshot/capture protection is platform-dependent and must not promise impossible guarantees.

Guardian/chaperone functionality is deferred from V1.

## Testing

At minimum cover:

- route guards and resume;
- bootstrap/localization;
- onboarding draft/readiness;
- upload registration and recovery;
- discovery pagination and decisions;
- chat send/read/retry;
- trust/safety nudge deduplication and risk/correction routing;
- blocked/restricted/deletion recovery states;
- paywall capability rendering;
- RTL/text-scaling representative widgets;
- offline/error behavior.

Physical-device QA remains mandatory for signing/provider behavior, notifications, purchases, accessibility, RTL typography and screenshot/capture behavior.
