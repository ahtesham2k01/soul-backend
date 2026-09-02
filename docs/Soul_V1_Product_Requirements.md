# SOUL — Version 1 Product Requirements

**Status:** Confirmed product direction  
**Platform:** Flutter (Android/iOS)  
**Backend:** Laravel APIs  
**Product type:** Global multi-religion marriage and dating application

## 1. Product scope

SOUL supports three visible, multi-select intentions:

- Marriage
- Serious relationship
- Casual dating

Intentions are always visible on the profile. Discovery does not require matching intentions, although users may filter them.

The minimum age is 18 worldwide. Exact date of birth remains private; calculated age is always visible.

## 2. Authentication and accounts

- Supported sign-in methods: Apple, Google and Email.
- One user account may link Apple, Google and Email identities.
- Verified email or phone may be used to detect and safely link/merge duplicate accounts.
- Users can view active login devices and remotely sign out.
- Account deletion has a 30-day recovery period, followed by permanent deletion.
- Users can request/download their account data.

## 3. Localization and brand

- Language is detected on first launch and can be changed by the user.
- UI translations are delivered by Laravel rather than bundled as the source of truth in Flutter.
- SOUL brand name/logo is never translated.
- RTL/LTR direction is returned by the bootstrap API.
- Location shown in onboarding must come from the real resolved location; no hard-coded default city/country.

## 4. Required profile information

The following are required before a profile can go live:

- First name
- Date of birth and age eligibility
- Gender: Man or Woman
- Current city and country of residence
- Nationality
- Religion/belief
- Marital status
- At least one intention
- Profession/status
- At least one spoken language
- Smoking answer (including Prefer not to say)
- Alcohol answer (including Prefer not to say)
- Current-children answer (including Prefer not to say)
- Future-children answer (including Prefer not to say)
- One public cover photo
- At least one clear-face photo among uploaded photos; it may be private

Current city is required. If GPS permission is denied, the user manually selects it.

## 5. Optional profile information

- Bio
- Education
- Height
- Job title and employer
- Grew up in
- Ethnic origin
- Sect/tradition
- Sub-sect, school or movement
- Caste/community
- Religion-specific practice, prayer, diet and dress answers
- Relocation preference
- Interests (maximum 15)
- Personality traits (maximum 5)
- Family-involvement preference

Optional fields support both:

- **Skip:** not answered yet
- **Prefer not to say:** intentionally withheld

Detailed religion fields are shown by default on the full profile when answered, with a privacy option to hide them.

## 6. Religion taxonomy and Version 1 discovery

The database stores a future-ready hierarchy:

`Religion → Sect/Tradition → Sub-sect/School/Movement → Caste/Community`

Version 1 discovery uses religion level only:

- Default: **My Religion**
- Optional filter: **All Religions**
- A Muslim user sees all Muslim profiles by default; the equivalent applies to every religion/belief.
- Sect, sub-sect and caste are displayed on the full profile but do not affect Version 1 ranking or filtering.
- The selected religion mode persists until changed.

Deep sect-tree ranking, sect preferences and must-have religious filters are reserved for a later version.

## 7. Discovery

- Default discovery is opposite-gender matching based on the registered Man/Woman gender model.
- Core ranking may use age, location, activity and basic compatibility.
- Users may search by radius and by selected locations, including Anywhere.
- Passed profiles may appear again after 30 days.
- A Like may be withdrawn before a Match is created.
- Favourite and Compliment features are not included.
- Incognito mode is supported: only people liked by the user can discover that user.
- A user may pause their profile; existing matches/chats remain while the profile disappears from discovery.
- Users may hide accounts matching uploaded phone contacts.
- After 30 inactive days ranking is reduced; after 90 inactive days the profile is hidden from discovery.

## 8. Distance privacy

Exact coordinates, live location, exact feet and exact metres are never exposed.

Free display examples:

- Less than 1 km
- About 2 km
- About 5 km

Paid/narrow-range examples may begin at:

- Within 500 m
- 500 m–1 km
- 1–2 km
- 2–5 km
- 5–10 km
- 10+ km

Distance is rounded/cached to reduce movement tracking. The backend may calculate exact distance internally but must only return the permitted band.

## 9. Photos

- Maximum total: 3 photos.
- Photo 1 is the required public cover photo.
- Photos 2 and 3 are optional and may be public or private.
- At least one uploaded photo must contain a clear identifiable face.
- The clear-face photo may be private.
- If the cover does not pass the clear-face check, an additional clear-face photo is required before going live.
- Photos support upload progress, moderation pending, rejection reason, replacement and ordering within the permitted structure.

## 10. Private photos

- Private-photo access can only be requested after a mutual Match.
- The request is a single button with no separate reason/message field.
- The owner approves or rejects the request.
- Approval unlocks all of that owner's currently private photos for the requester.
- The owner may revoke access at any time.
- Access is automatically revoked on unmatch or block.

## 11. Screenshot protection

- The photo owner has a Screenshot Protection control, default ON.
- Private photos receive the maximum available protection.
- Android should block capture on protected screens where supported.
- iOS should use available capture detection, screen-recording masking, warnings and viewer-identifying watermarking; it must not promise technically impossible prevention.
- Screenshot notifications are best-effort only where the operating system exposes reliable signals.

## 12. Likes, requests, matches and chat

- A user can Like a profile.
- Normal chat becomes available when the recipient accepts the request/Like, creating a Match.
- After matching, either user can send the first message.
- Pending chat requests do not expire.
- Version 1 chat is text and emoji only.
- Chat photos, voice notes, audio calls and video calls are not included in Version 1.
- Read receipts are always visible.
- Online/last-seen status is visible.
- Typing indicator is enabled, with a Snapchat-like live typing experience where feasible.
- Active chats are not limited by product logic.
- Unmatching removes the conversation from both users and revokes private-photo access.

## 13. Marital status

- Marital status is required and cannot be hidden.
- A married user's status appears on both the discovery card and full profile.
- Married users may select Marriage, Serious relationship and/or Casual dating.
- Married users can be shown to unmarried users; their status remains prominent.
- Partner-consent and polygamy questions are not included.

## 14. Verification

Verification types remain separate:

- Email verification
- Phone verification (optional badge)
- Selfie/face verification (optional badge)
- ID/age verification (optional or risk/region dependent)

Phone and face verification do not block a normal profile from going live unless a safety/risk flow specifically requires verification. Underage suspicion immediately pauses the profile and requests age/ID verification.

## 15. Safety, reporting and moderation

Report categories include:

- Fake profile
- Scam
- Harassment
- Nudity/sexual content
- Underage
- False marital status
- Other

Rules:

- Reporting offers **Report only** and **Report & Block**.
- Risk scoring may temporarily hide a profile pending review; no simplistic public fixed-report threshold is required.
- Automated checks handle initial screening; serious or disputed cases go to a human moderator.
- Banned users receive one proper appeal path.
- Nudity and sexual content are prohibited in public and private profile photos.
- Screenshot/profile capture warnings are best-effort and platform-dependent.

## 16. Notifications

- Near the end of onboarding, explain push notifications and offer Allow / Not now.
- Denial does not block onboarding.
- Users choose notification categories during setup.
- Email notification categories can be controlled separately.
- Marketing consent is separate, optional and off by default.

## 17. Events

Events are included in Version 1:

- Online and physical events
- Admin-approved event publishing initially
- Event details, date, city, capacity and join/leave registration
- Attendee privacy and event reporting
- Public user-created events are deferred until moderation controls are mature

## 18. Subscription and dynamic entitlements

Version 1 supports subscription, but exact plans, prices and feature allocation will be finalized near launch.

Free/paid behavior must not be hard-coded in Flutter. Admin-configurable capabilities include:

- Feature enabled/disabled
- Free, paid or universally available
- Daily/monthly limits
- Country/region/platform availability
- Plan entitlements
- Trials and promotions
- Individual user overrides
- Scheduled start/end dates
- Percentage rollouts

Backend domains:

- Features
- Subscription plans
- Plan entitlements
- Usage limits/counters
- User entitlement overrides
- Country overrides
- Promotions
- Feature rollouts

The bootstrap/config response returns the authenticated user's effective capabilities and limits. Laravel remains authoritative for action authorization; Flutter uses the response for UI visibility and paywall presentation.

Store pricing remains mapped to valid Apple App Store and Google Play products.

These safety/account capabilities may never be paywalled:

- Block
- Report
- Account deletion
- Core privacy protection
- Safety appeals/support

## 19. Legal promise and consent

The user agrees to neutral global commitments:

- Respect everyone
- Provide identity and marital status honestly
- No harassment, scams or inappropriate behavior
- Follow Community Guidelines
- Accept Terms and Privacy Policy

Backend records document version, acceptance timestamp and appropriate IP/device context.

## 20. Profile lifecycle

Core lifecycle:

`Draft → Submitted → Automated checks → Live`

Alternative states include:

- Changes required
- Photo rejected
- More information required
- Profile paused for verification
- Profile rejected
- Appeal available

The user receives a specific reason and a link to the relevant correction screen. Human moderation is used for risk, reports and disputed cases rather than mandatory review of every profile.

## 21. Main navigation

Bottom navigation:

1. Home / Discovery
2. Explore / Activity
3. Chat
4. Profile

Supporting modules include filters, full profiles, likes/visitors, matches/chat, block/report, editing, verification, subscription/boosts, events, settings/privacy and help/support.

## 22. Explicitly deferred decisions

- Exact subscription tiers, prices, limits and paid-feature allocation
- Chat photos, audio messages and calling
- Deep sect/sub-sect/caste matching and filters
- Chaperone/guardian system (not planned for Version 1)
- Public user-created events
- Country-specific expansion details requiring legal review

## 23. Implementation principles

- Laravel is authoritative for eligibility, visibility, moderation and entitlements.
- Flutter must not rely on hidden UI as authorization.
- Every protected action is rechecked server-side.
- Configuration responses are versioned and cached with safe fallbacks for old app versions.
- Taxonomy and catalog labels are multilingual and admin-configurable.
- Privacy and safety defaults take priority over monetization.

