# SOUL V1 Complete-App Flow Execution & Real-Device QA Plan

> **Purpose:** Build and verify SOUL in the actual member journey order, one practical vertical slice at a time. Each slice must keep Flutter, Laravel, contracts/tests and documentation synchronized so the owner can pull the latest `main` on a laptop, run the app on a connected real device, verify the slice, and then move to the next one.
>
> **Authority:** Product behavior comes from `docs/SOUL_V1_MASTER_DOCUMENTATION.md` and generated contracts. `Soul1111.fig.fig` / `Soul1111.fig.pdf` are presentation references only. Figma sample names, cities, prices, religions, wording, or old flow must never override the master product rules.
>
> **Complete-app boundary:** This tracker is not only a member-screen checklist. SOUL V1 is considered fully covered only when **Track A — Member App**, **Track B — React Admin**, and **Track C — Backend / Operations / Providers** are all complete and the FINAL-GATE passes.

---

## 0. V2 coverage lock — what this tracker must cover

This V2 tracker was audited against the master product requirements, QA guide, admin operations guide, security/privacy/safety guide, DevOps runbook and the 188-frame supplied design PDF.

### Three-track completion model

- **Track A — Member App:** every member journey, screen, sheet/dialog, important state, Flutter behavior, member API behavior and real-device check.
- **Track B — React Admin:** every operator/moderator/super-admin workflow that is genuinely part of V1 operations.
- **Track C — Backend / Operations / Providers:** contracts, queues, jobs, security, telemetry, performance, readiness, staging/provider verification, backup/restore and release operations.
- **FINAL-GATE:** may pass only after all applicable A/B/C packets pass. A green mobile build alone is not complete-app completion.

### Member-state rule

Every member packet must explicitly audit all applicable states instead of assuming them:

- loading / skeleton;
- populated success;
- empty / exhausted;
- offline;
- timeout / provider failure;
- validation failure;
- retry;
- permission denied;
- restricted / blocked / suspended / deletion-scheduled account;
- session expiry / re-authentication;
- rapid taps / duplicate callback safety;
- background / resume;
- small screen / safe area / keyboard;
- large text / accessibility;
- LTR / RTL;
- reduced motion;
- slow network.

### Figma/PDF visual-reference map

The supplied 188-frame PDF is a **presentation reference**, not product authority. Known useful reference pages include:

| Area | Known PDF references | Notes |
|---|---|---|
| Splash / launch | p1 | SOUL splash/logo reference |
| Welcome / language | p3–6 | Welcome, language-selection presentation |
| Registration / email / OTP | p7–10 | Name, DOB, email and OTP visual references |
| Basic onboarding | p12–19 | Gender, religion hierarchy, profession, ethnicity, education |
| Notification prompt | p20 | Permission-explanation reference |
| Photos / photo verification | p21–25 | Photo intro/upload/face/verification presentation |
| Remaining onboarding | p27–45 | Intentions, nationality, grew-up-in, height, marital/religious/lifestyle/interests/personality/bio/legal |
| Location permission | p47 | Location-permission presentation |
| Discovery / filters | p48–55 | Candidate and filter presentation references |
| Explore / activity | p93 | Activity/Explore visual reference; ignore deferred visitor/favourite/compliment concepts |
| Chat / chat options | p99–114 | Chat list/thread/options/report/unmatch presentation; ignore deferred audio/video/share/export behavior unless separately contracted |
| Profile hub | p115 | Profile landing reference |
| Full public profile | p117 | Long-form public profile reference; remove non-V1/deferred concepts |
| Membership / profile-edit cluster | p145–150 | Gold/subscription/profile/settings references; prices/features are illustrative only |
| Settings | p148 | Settings presentation; chaperone/passcode/legacy reset concepts do not override V1 |

The exact relevant frame(s) must be re-opened when each FLOW packet is executed. A frame may contain third-party names, Muzz/Faithly wording, fake cities/prices, Muslim-only logic, boosts, favourites, chat-slot limits, calls, voice, chaperone or other non-V1 concepts. Those are **not** silently copied.

### Explicit member coverage that must never remain merely implied

The member flow must explicitly verify:

- current-device logout, logout-all and targeted active-device revocation;
- outgoing Like withdraw / Undo before match;
- Pass resurfacing after the documented cooling period;
- 30-day inactivity ranking reduction and 90-day discovery hiding;
- blocked-profile list plus unblock;
- uploaded-contact hiding plus update/remove behavior;
- notification deep-link route guards;
- session expiry and protected-screen clearing;
- account states: active, blocked, suspended, deletion-scheduled and recovery;
- dynamic capabilities/usage limits/country-platform availability without hard-coded paywall logic;
- analytics/crash/performance telemetry redaction;
- correction/re-consent routes;
- provider and physical-device behavior that source tests cannot prove.

---

## 1. Working model

This plan deliberately avoids both extremes:

- **Not too large:** never ask one chat run to complete an entire major feature or the whole app.
- **Not too small:** do not commit tiny cosmetic edits or single-line fixes as separate work packets.
- **Preferred unit:** one complex screen or two to three tightly connected simple screens, including their backend/API behavior, important states, focused tests, documentation and a clean checkpoint.
- **Full CI/build cadence:** run full Laravel + Flutter analyze/tests + Android build + iOS simulator build at milestone gates, not after every small edit.
- **Real-device cadence:** the owner may pull after every completed flow slice. Milestone gates additionally require a fresh APK/debug run and explicit owner approval.

### Completion vocabulary

- `IMPLEMENTED` = code exists.
- `SOURCE VERIFIED` = relevant source, contracts and focused automated tests pass.
- `DEVICE APPROVED` = owner has tested the slice on a connected real device and approved it.
- `100% COMPLETE` = all applicable functionality, UX, visual polish, states, edge cases, performance, accessibility, localization/RTL, privacy/safety, provider/device checks, automated tests and visual review have passed.

**Never call a slice 100% merely because CI is green.**

---

## 2. Sync protocol

Every work packet follows this exact rhythm:

1. Read current `main` HEAD.
2. Read this document and find the first non-approved packet.
3. Read the relevant master-document section and current Flutter/Laravel implementation.
4. Inspect the matching Figma/PDF frame(s) for presentation only.
5. Audit the complete packet before editing.
6. Implement all clear issues for that packet in one meaningful batch.
7. Recheck the whole packet after edits.
8. Run only the focused tests needed for that packet.
9. Commit/push one meaningful packet commit to `main` unless a conflict or unsafe state prevents it.
10. Update this document's packet status/checkpoint.
11. Stop and tell the owner exactly what to test on the connected phone.
12. Do **not** start the next packet until the owner approves or explicitly says to continue.

### Timeout / new-chat recovery

If a response times out or the chat becomes unusable, the owner only needs to send:

> **Continue FLOW-XX from the repo tracker. Read current main and do not redo completed work.**

The assistant must then read `main`, this tracker and recent commits before changing anything.

### Bug feedback after device testing

The owner can reply:

> **FLOW-XX device test failed: [short description]. Fix only this slice and recheck it.**

The assistant must fix the same packet, update its checkpoint and return it for device QA again. It must not move forward automatically.

---

## 3. Global rules applied to every packet

- Product flow and backend rules come from the master documentation.
- Figma/PDF controls **appearance**, not business logic.
- Use shared Flutter design tokens/components instead of one-off screen styling where practical.
- Do not hard-code member-facing launch copy that belongs in Laravel localization.
- Roman Urdu remains LTR; server-provided direction is authoritative.
- Do not expose exact coordinates, provider secrets, private-media identifiers, OTPs or tokens.
- Do not add V1-deferred features accidentally.
- Loading, empty, offline, retry, permission-denied and restricted states must be considered where applicable even if Figma omits them.
- Keep Android back, iOS navigation, keyboard, safe areas, small screens, text scaling and accessibility in scope.
- No fake/sample Figma city, price, plan or user data may become runtime truth.
- Do not run repeated full CI between tiny edits. Finish the packet first.

---

# FLOW MAP

## Milestone A — Launch, bootstrap and authentication

### FLOW-01 — Splash + cold-start bootstrap shell

**Journey position:** First app frame.

**Presentation reference:** Figma/PDF opening SOUL splash frame.

**Scope**
- SOUL splash presentation.
- No white flash/jarring native-to-Flutter transition.
- Bootstrap kickoff.
- Cached locale/catalog safe startup behavior.
- Safe startup error/retry state.
- Route decision shell only; do not implement later screens in this packet.
- Existing secure session discovery hook.

**Backend/contracts**
- `GET /api/v1/bootstrap`.
- Translation/config version/hash handling.
- Request ID and safe failure envelope.

**Focused checks**
- Cold start.
- Warm resume.
- Network unavailable at launch.
- Backend unavailable.
- Cached catalog available/unavailable.
- No protected content flashes before route resolution.

**Owner real-device test**
- Force-stop app and launch.
- Launch with Wi-Fi/mobile data on.
- Launch once with network off.
- Verify no white flash, clipped logo or visible debug artifacts.
- Verify startup does not hang indefinitely.

**Ready-to-send prompt**

> **Run FLOW-01 only. Read current main, this tracker, the master flow and the actual Flutter/Laravel code. Build the Splash + cold-start bootstrap shell as one production-grade vertical slice. Figma/PDF is visual reference only; master docs remain behavior authority. Audit first, then fix all clear issues in this slice together. Include loading/error/retry/cached-start behavior, safe session discovery and localization bootstrap handling. Do not start Welcome, auth forms or onboarding yet except shared code strictly required by FLOW-01. Run focused tests only, update this tracker with commit SHA and device-QA instructions, then stop for my real-device approval.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-02 — Locale detection + globe/location intro

**Journey position:** Immediately after launch bootstrap, before normal welcome/auth entry where applicable.

**Presentation reference:** Figma/PDF launch/location/globe visual reference. Product behavior must use real resolved location and no hard-coded sample city.

**Scope**
- Device locale detection.
- Laravel-selected locale/fallback/direction.
- Globe/location intro presentation.
- Approximate/bootstrap location where available.
- Native precise location permission path where appropriate.
- `POST /api/v1/location/resolve`.
- Manual fallback when permission/provider fails.
- No fake Multan/Karachi/default city substitution.
- Retry and denied-permission UX.

**Focused checks**
- Location allowed.
- Location denied.
- Location service off.
- Resolver/network failure.
- Manual selection path.
- Roman Urdu LTR / representative RTL direction shell.

**Owner real-device test**
- Location permission allowed.
- Permission denied.
- Phone location turned off.
- Verify actual resolved city/country or manual path.
- Verify no illustrative Figma city leaks into runtime.

**Ready-to-send prompt**

> **Run FLOW-02 only. Continue from approved FLOW-01. Complete locale detection + globe/location intro + real location resolution/manual fallback as one vertical slice. Use server-provided locale/direction and real provider/device location; never use a fake default city. Audit the current Flutter UX and Laravel resolver together, implement all permission/error/retry/manual-selection states, keep visual styling aligned with the supplied design where product rules allow, run focused tests, update the tracker and stop for my real-device approval.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-03 — Welcome + language selector

**Journey position:** First actionable unauthenticated screen.

**Scope**
- Welcome presentation.
- SOUL brand.
- Create Account.
- Already have account / Log in.
- Continue with Google.
- Continue with Apple where platform-supported.
- Continue with Email.
- Language picker entry.
- RTL/LTR-safe layout.
- Provider buttons do not yet need full provider completion beyond safe navigation/availability in this packet.

**Owner real-device test**
- Compare spacing, typography, buttons and hierarchy with Figma.
- Change language and confirm same screen rebuilds without restart/logout.
- Rotate through English/Roman Urdu and one RTL QA locale if exposed in QA build.

**Ready-to-send prompt**

> **Run FLOW-03 only. Complete the Welcome + language-selector slice from current main. Match the supplied Figma presentation closely while keeping the authoritative SOUL auth options and server-driven localization. Cover button hierarchy, safe areas, text scaling, LTR/RTL layout, language switching and navigation entry states. Do not implement the deeper OTP/provider flows yet. Run focused widget/localization tests, update the tracker and stop for my device approval.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-04 — Registration entry: name + DOB + email

**Journey position:** Create Account path.

**Scope**
- Registration-only first-name/name step.
- Adult DOB validation.
- Registration email entry.
- Form validation and keyboard behavior.
- Draft/transient state across back/forward navigation.
- Correct registration OTP request endpoint.
- Do not mix with returning-member login semantics.

**Owner real-device test**
- Invalid/empty name.
- Under-18 DOB.
- Boundary 18-year DOB.
- Bad email.
- Keyboard next/done behavior.
- Back and resume within registration flow.

**Ready-to-send prompt**

> **Run FLOW-04 only. Build the Create Account entry slice: registration name, adult DOB and registration email screens plus the matching Laravel validation/OTP-request behavior. Preserve the current master flow even if Figma wording differs. Make the screens visually consistent with the supplied design, handle keyboard/back/validation states, keep registration separate from returning login, run focused Flutter/Laravel tests, update the tracker and stop for real-device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-05 — Returning member email login

**Journey position:** Log in / Continue with Email path for existing members.

**Scope**
- Returning-member email screen.
- Login OTP request.
- Account-not-found / invalid-state UX.
- Rate limit messaging.
- Back to welcome.
- No registration fields on this path.

**Ready-to-send prompt**

> **Run FLOW-05 only. Complete the returning-member email login entry as a separate flow from registration. Audit Flutter and Laravel together, fix email validation, login OTP request behavior, rate-limit/error states, navigation/back behavior and visual polish. Do not duplicate registration fields. Run focused tests, update the tracker and stop for my device approval.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-06 — OTP verification + resend + expiry

**Journey position:** Shared verification stage for registration/login, with separate backend purposes.

**Scope**
- 6-digit OTP UI.
- Auto-advance/paste where safe.
- Timer.
- Resend.
- Expired/invalid code.
- Rate limiting.
- Purpose separation: register vs login.
- Session/token issue after successful verification.
- Safe storage.
- Route resolution after auth.

**Owner real-device test**
- Correct code.
- Wrong code.
- Expired code where test environment supports it.
- Paste full code.
- Resend.
- Rapid taps.
- Background/resume during countdown.

**Ready-to-send prompt**

> **Run FLOW-06 only. Complete the OTP verification vertical slice for both registration and login while keeping their backend purposes separate. Include paste/entry UX, resend timing, expiry/invalid/rate-limit states, secure token issue/storage and post-auth route resolution. Audit rapid taps and app-resume behavior. Run focused auth tests and Flutter tests, update the tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-07 — Google + Apple native sign-in and account resolution

**Journey position:** Social auth alternatives from Welcome.

**Scope**
- Native credential acquisition.
- Apple nonce handling.
- Google/Apple backend verification.
- Existing-account linking behavior.
- New-account route.
- Blocked/deletion-recovery/suspended account outcomes.
- Provider-cancel UX.
- Provider-unavailable UX.
- Never log provider tokens.

**External caveat**
Real provider/device verification may remain pending until valid production/sandbox credentials are available.

**Ready-to-send prompt**

> **Run FLOW-07 only. Complete the Google + Apple sign-in slice end to end in source: native credential acquisition, Apple nonce protection, Laravel verification, conservative account linking, new/existing account resolution and restricted-account outcomes. Handle cancel/provider failure cleanly and never log provider credentials. Run focused tests. Clearly separate source-complete items from external real-provider QA, update the tracker and stop.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### GATE-A — Launch/Auth milestone

**Purpose**
Full audit of FLOW-01 through FLOW-07 before onboarding begins.

**Run**
- Laravel full tests.
- Flutter analyze.
- Flutter full tests.
- Android debug build.
- iOS simulator build.
- Produce/update debug APK artifact.
- Recheck launch/auth visual consistency and route matrix.
- Owner performs full real-device auth journey.

**Ready-to-send prompt**

> **Run GATE-A only. Re-audit FLOW-01 through FLOW-07 as one launch/auth milestone. Do not add new onboarding functionality. Fix any remaining launch/auth regression first, then run the full Laravel test suite, Flutter analyze/tests, Android debug build and iOS simulator build once. Produce the current APK artifact, update all tracker statuses/checkpoints, and give me one concise real-device test script. Do not call this milestone 100% if any provider/device/polish gap remains.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

## Milestone B — Required onboarding

### FLOW-08 — First name + DOB + gender profile steps

**Journey position:** First onboarding data after authentication for new/incomplete profiles.

**Scope**
- Saved profile draft.
- First name.
- DOB.
- Gender Man/Woman.
- Resume first incomplete step.
- Server-authoritative 18+ validation.

**Ready-to-send prompt**

> **Run FLOW-08 only. Complete onboarding First name + DOB + Gender as one resumable vertical slice using the saved Laravel profile draft. Match the design presentation while keeping master product rules authoritative. Cover validation, save/resume, back navigation, loading/error/offline behavior and accessibility. Run focused tests, update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-09 — Current city/country + nationality

**Scope**
- Resolved current city/country.
- Manual city/country fallback.
- Nationality selection.
- Search lists where applicable.
- Persisted draft.
- No exact coordinate exposure.

**Ready-to-send prompt**

> **Run FLOW-09 only. Complete current city/country plus nationality onboarding. Reuse the real location work from FLOW-02, support manual selection/search, persist the draft, never expose exact coordinates, and cover provider denial/failure/offline states. Keep the UI close to Figma while following the authoritative flow. Run focused tests, update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-10 — Religion → sect → sub-sect → community/caste

**Scope**
- Religion root.
- Fetch children dynamically.
- Auto-skip levels with no children.
- Country-aware validity.
- Optional deeper levels.
- Prefer not to say where allowed.
- Saved public root/leaf selection.
- Localization.
- No hard-coded Muslim-only assumptions.

**Owner real-device test**
Use at least:
- A religion with deeper hierarchy.
- A religion without one of the deeper levels.
- A path where a screen auto-skips.

**Ready-to-send prompt**

> **Run FLOW-10 only. Complete the dynamic religion hierarchy journey: Religion → available Sect/Tradition → available Sub-sect/School/Movement → optional Community/Caste. Screens must be data-driven and automatically skip missing levels. Preserve country-aware Laravel validation and multilingual labels; do not hard-code Muslim-only logic from Figma. Run focused taxonomy/onboarding tests, update tracker and stop for my device QA with at least two contrasting religion paths.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-11 — Marital status + relationship intentions

**Scope**
- Required marital status.
- Marriage / Serious relationship / Casual dating multi-select.
- Persistence.
- Visibility implications are server-owned.
- Married status remains allowed and prominent per master rules.

**Ready-to-send prompt**

> **Run FLOW-11 only. Complete required Marital Status + multi-select Relationship Intentions onboarding. Follow the master rules exactly, including married-member support and the three authoritative intentions. Match the design system, handle validation/save/resume/back states, run focused tests, update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-12 — Profession/status + spoken languages

**Scope**
- Required profession/status.
- Optional job/employer/education entry where the presentation naturally groups them.
- At least one server-provided spoken language.
- Search/list performance.
- No stale embedded language list.

**Ready-to-send prompt**

> **Run FLOW-12 only. Complete Profession/Status + Spoken Languages onboarding, including the closely related optional job/employer/education presentation where appropriate. Languages must come from the Laravel catalog, support search and require at least one selection. Cover save/resume/validation/performance states, run focused tests, update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-13 — Smoking + alcohol + current/future children

**Scope**
- Four required answer groups.
- Explicit Prefer not to say support.
- Correct three-state persistence.
- No accidental clearing on resume/edit.

**Ready-to-send prompt**

> **Run FLOW-13 only. Complete Smoking, Alcohol, Current Children and Future Children onboarding as one coherent lifestyle/family slice. Each required field must support the authoritative answer model including Prefer not to say, persist correctly across resume, and never collapse Skip/withheld semantics incorrectly. Run focused tests, update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

## Milestone C — Optional profile depth + photos + submission

### FLOW-14 — Optional basics: bio + height + grew-up-in + ethnic origin + relocation

**Scope**
- Optional values.
- Skip distinct from Prefer not to say where applicable.
- Text limits/search/selectors.
- Save/resume.

**Ready-to-send prompt**

> **Run FLOW-14 only. Complete the optional-profile basics slice: Bio, Height, Grew up in, Ethnic origin and Relocation preference. Preserve the three-state optional model wherever supported. Match the visual language, handle text/search selectors, validation, save/resume and keyboard behavior, run focused tests, update tracker and stop.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-15 — Interests + personality traits + family/religion-specific optional answers

**Scope**
- Interests max 15.
- Personality max 5.
- Admin-managed catalogs.
- Family involvement.
- Religion-specific practice/prayer/diet/dress only when applicable.
- Do not show irrelevant religion-specific questions.

**Ready-to-send prompt**

> **Run FLOW-15 only. Complete catalog-driven Interests, Personality Traits, Family Involvement and applicable religion-specific optional questions. Enforce max 15 interests / max 5 traits, use Laravel-managed catalogs, dynamically hide irrelevant religion-specific questions and preserve optional-state semantics. Run focused tests, update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-16 — Photo onboarding

**Scope**
- Up to 3 slots.
- Slot 1 public cover.
- Slots 2–3 public/private.
- Clear-face requirement.
- Gallery/camera permissions where implemented.
- Direct upload progress.
- Pending/approved/rejected.
- Replacement/delete.
- Safe failure/retry.
- Cloudinary IDs/secrets never shown.

**Ready-to-send prompt**

> **Run FLOW-16 only. Complete Photo Onboarding as one vertical slice: three slots, required public cover, optional public/private secondary photos, clear-face readiness, direct upload progress, pending/approved/rejected/replacement/delete states and permission/error/retry UX. Keep provider secrets/IDs private and use the signed Laravel/Cloudinary contract. Run focused Flutter/Laravel tests, clearly identify external real-provider/device checks, update tracker and stop.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-17 — Notification permission + categories

**Scope**
- Explanation screen near onboarding end.
- Allow / Not now.
- Native permission only from explicit action.
- Push categories.
- Email preferences separately where appropriate.
- Marketing off by default.
- Denial never blocks onboarding.

**Ready-to-send prompt**

> **Run FLOW-17 only. Complete the onboarding notification explanation + permission/category slice. The OS prompt must occur only after explicit user action; denial must not block onboarding; marketing remains separate and off by default. Sync Flutter preferences with Laravel device/preferences APIs, run focused tests, update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-18 — Legal promises + readiness + submission + lifecycle result

**Scope**
- Current Terms/Privacy/Community versions.
- Neutral commitments.
- Explicit acceptance.
- Readiness.
- Submit.
- Automated checks.
- Live / Changes required / Paused verification / Rejected / Appeal available.
- Correction routing.

**Ready-to-send prompt**

> **Run FLOW-18 only. Complete the onboarding finish: versioned legal promises/consent, readiness, submission, automated-check lifecycle and all correction/restricted outcomes. No profile may become discoverable before Laravel says Live. Implement clear reason/correction routing, focused tests and polished loading/retry states. Update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### GATE-B — Full onboarding milestone

**Ready-to-send prompt**

> **Run GATE-B only. Re-audit FLOW-08 through FLOW-18 end to end on the current main. Do not start discovery. Fix remaining onboarding issues first, then run full Laravel tests, Flutter analyze/tests, Android build and iOS simulator build once. Produce the current APK, update tracker checkpoints, and give me one fresh-install real-device onboarding script covering resume, denied location, dynamic religion skipping, photos, notifications, legal submission and a correction state. Do not mark 100% while any real-provider/device or premium UX gap remains.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

## Milestone D — Main shell and discovery

### FLOW-19 — Main navigation shell + authenticated home states

**Scope**
- Home / Explore / Chat / Profile bottom navigation.
- Correct lifecycle guard.
- Main tab state preservation.
- Back behavior.
- Loading/restricted/session-expired routing.

**Ready-to-send prompt**

> **Run FLOW-19 only. Complete the authenticated main-navigation shell with Home, Explore, Chat and Profile. Preserve tab state, safe back behavior and authoritative lifecycle/session guards. Build polished loading/restricted/session-expired states without implementing later feature depth yet. Run focused tests, update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-20 — Discovery candidate card + Like/Pass

**Scope**
- Candidate feed.
- Approved cover image.
- Age.
- Marital status.
- Intentions.
- Safe distance band.
- Like / Pass.
- Immediate state consistency.
- Pagination/prefetch.
- Loading/empty/exhausted.
- Pause/incognito guidance.
- Passed profiles may resurface only after the documented 30-day cooling period.
- Ranking reduction after 30 inactive days and discovery hiding after 90 inactive days must remain server-authoritative and reflected correctly in client empty/unavailable states.

**Ready-to-send prompt**

> **Run FLOW-20 only. Complete the primary Discovery card + Like/Pass vertical slice. Render only safe public fields, age, required marital status, intentions and server-provided distance band; never exact location. Include pagination/prefetch, image loading, empty/exhausted, paused/incognito, retry and rapid-action consistency. Match the supplied visual reference where compatible. Run focused tests, update tracker and stop.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-21 — Full profile

**Scope**
- Full public profile.
- Public photos.
- Visible intentions/marital status.
- About/details.
- Religion details according to privacy.
- Verification badge booleans.
- Interests/traits.
- Safe location.
- Like/Pass/report/block entry.

**Ready-to-send prompt**

> **Run FLOW-21 only. Complete the Full Profile journey from Discovery. Render authoritative public fields, public media, marital status, intentions, safe religion/profile details, badge booleans, interests/traits and safe distance/location presentation. Add Like/Pass plus report/block entry points without exposing private details. Run focused tests, update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-22 — Discovery filters

**Scope**
- Server-supported V1 filters only.
- Age/radius/location/religion mode/intention and any currently contracted filters.
- Clear all.
- Must not expose deferred deep sect/caste matching.
- Dynamic entitlements where applicable.
- Persistence.

**Ready-to-send prompt**

> **Run FLOW-22 only. Complete Discovery Filters using only currently supported Laravel V1 filters. Match the Figma filter presentation where possible, but do not copy deferred sect/sub-sect/caste must-have logic or fake paid filters. Handle persistence, clear-all, dynamic entitlements, keyboard/sheets, loading/retry and accessibility. Run focused tests, update tracker and stop.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

## Milestone E — Activity, likes and matching

### FLOW-23 — Explore / incoming likes, requests and outgoing-like recovery

**Scope**
- Incoming likes grid/list.
- Pending state.
- Accept.
- Decline.
- Sender withdrawal reflected.
- Outgoing pending Like visibility where exposed by the current contract.
- Withdraw / Undo a non-reciprocal outgoing Like before a Match exists.
- A created Match must not be treated as a withdrawable pending Like.
- Cursor pagination.
- Empty/loading/retry.

**Ready-to-send prompt**

> **Run FLOW-23 only. Complete the Explore incoming Likes/Requests slice with pending, accept, decline, withdrawn and empty/loading/retry states. Keep state server-authoritative and cursor-paginated. Match the visual reference without inventing visitor/boost features. Run focused tests, update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-24 — Mutual match moment + match list

**Scope**
- Reciprocal match transition.
- Tasteful match feedback.
- Match list.
- Cover/avatar.
- latest message summary.
- unread count.
- presence/last seen.
- Unmatch entry.

**Ready-to-send prompt**

> **Run FLOW-24 only. Complete the mutual-match moment plus match list. Make the successful match feel polished without manipulative effects, then show authoritative match summaries, approved cover, unread count and presence/last-seen. Include unmatch entry and state consistency after restart. Run focused tests, update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

## Milestone F — Chat and private photos

### FLOW-25 — Chat thread: history + send + read + typing

**Scope**
- REST history first.
- Authorized private live channel.
- Text/emoji.
- Send state.
- Retry without duplicates.
- Read receipts.
- Typing.
- Presence.
- Reconnect refresh.
- Pagination.
- Keyboard/scroll behavior.
- Offline/error.

**Ready-to-send prompt**

> **Run FLOW-25 only. Complete the text/emoji Chat Thread vertical slice: REST history, authorized private realtime channel, pagination, send/retry without duplicates, read receipts, typing, presence, reconnect recovery, keyboard/scroll behavior and offline/error states. Do not add chat photos, voice notes or calls. Run focused tests, update tracker and stop.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-26 — Private photo request/approval/viewer/revoke

**Scope**
- Request after mutual match.
- Owner approve/reject.
- Current private photos unlock.
- Revoke.
- Auto-revoke on unmatch/block.
- Protected viewer.
- Watermark.
- Android/iOS capture behavior in source.
- Best-effort capture signals.

**Ready-to-send prompt**

> **Run FLOW-26 only. Complete the Private Photo journey: request after match, owner approve/reject, protected viewing, revoke and automatic revoke on unmatch/block. Apply viewer watermark and current Android/iOS capture-protection source behavior without promising impossible prevention. Run focused tests, list real-device capture checks separately, update tracker and stop.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### GATE-C — Discovery/activity/chat milestone

**Ready-to-send prompt**

> **Run GATE-C only. Re-audit FLOW-19 through FLOW-26 as one connected member journey. Fix any state mismatch first, then run full Laravel tests, Flutter analyze/tests, Android build and iOS simulator build once. Produce the current APK and one two-account real-device test script covering discovery, filters, like/request, match, chat, typing/read state, private-photo approval/revoke and unmatch. Update tracker and stop.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

## Milestone G — Profile, settings, verification and safety

### FLOW-27 — My Profile overview + completion

**Scope**
- Authenticated member profile.
- Cover/public media.
- Profile completion.
- Verification summary.
- Entry to edit/photos/settings/subscription.
- Correct lifecycle state.

**Ready-to-send prompt**

> **Run FLOW-27 only. Complete the authenticated My Profile overview and completion guidance. Use authoritative saved data/media/lifecycle state and polished entries to Edit Profile, Photos, Verification, Membership and Settings. Run focused tests, update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-28 — Edit Profile

**Scope**
- All supported editable fields.
- Religion path editing.
- Languages/interests/traits.
- Public/private photo visibility.
- Skip vs Prefer not to say preservation.
- Unsaved change protection.
- Keyboard/small screen.

**Ready-to-send prompt**

> **Run FLOW-28 only. Complete Edit Profile end to end for the currently supported fields. Preserve Skip vs Prefer-not-to-say semantics, religion path, languages/interests/traits and photo visibility. Add unsaved-change protection, robust validation, keyboard/small-screen behavior and server-authoritative save/reload. Run focused tests, update tracker and stop.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-29 — Settings core

**Scope**
- Language.
- Notification preferences.
- Privacy.
- Screenshot protection.
- Pause.
- Incognito.
- Contact hiding.
- Blocked list.
- Help/support entry.
- Membership entry.
- Security/device sessions.
- Current-device logout.
- Logout all devices.
- Targeted remote session revoke with current-device handling.
- Blocked-profile list and unblock.
- Contact import/hiding status, update and removal/unhide behavior where contracted.

**Ready-to-send prompt**

> **Run FLOW-29 only. Complete the Settings core journey: language, notifications, privacy, screenshot protection, pause/incognito/contact hiding, blocked profiles, Help, Membership and Security/device-session entries. Keep each value server-authoritative and immediately consistent after restart. Run focused tests, update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-30 — Verification

**Scope**
- Email state.
- Phone badge.
- Selfie badge.
- ID/age badge.
- Optional vs risk-required.
- Cases.
- Submit/retry/status.
- Appeals where applicable.
- Safe public badge presentation.

**Ready-to-send prompt**

> **Run FLOW-30 only. Complete Verification UI and flows for email, phone, selfie and ID/age as separate authoritative states. Preserve optional versus risk-required behavior, safe public badges, review/correction/status and appeal paths. Do not silently make selfie verification mandatory. Run focused tests, identify external provider/device checks, update tracker and stop.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-31 — Report + block + restricted-account appeal

**Scope**
- Report categories.
- Report only.
- Report & Block atomic behavior.
- Block/unblock.
- Underage report routing.
- Restricted account screen.
- One appeal.
- Appeal status.
- Safety never paywalled.

**Ready-to-send prompt**

> **Run FLOW-31 only. Complete member Safety actions: report categories, Report only, atomic Report & Block, block/unblock, underage-risk routing, restricted-account presentation and one proper appeal/status path. Keep internal risk evidence hidden and safety actions free. Run focused tests, update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

## Milestone H — Notifications, events, support, subscriptions and account lifecycle

### FLOW-32 — Notification center

**Scope**
- Cursor-paginated feed.
- Read state.
- Categories/preferences linkage.
- Empty/error/retry.
- Push deep-link routing with the same lifecycle/auth/restriction guards as normal navigation.
- Push/email preference consistency and mandatory safety-channel behavior.

**Ready-to-send prompt**

> **Run FLOW-32 only. Complete the in-app Notification Center with pagination, read state, preference linkage, empty/error/retry behavior and safe deep-link routing. Do not depend on live APNs/FCM success to fake completion; source and external delivery QA must be reported separately. Run focused tests, update tracker and stop.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-33 — Events

**Scope**
- Browse.
- Detail.
- Online/physical presentation.
- Capacity.
- Join/leave.
- My Events.
- Attendee privacy.
- Report.
- No public member-created events.

**Ready-to-send prompt**

> **Run FLOW-33 only. Complete Events member flow: browse, details, online/physical metadata, capacity-safe join/leave, My Events, attendee privacy and reporting. Use only Laravel data and do not add public member-created events. Run focused tests, update tracker and stop.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-34 — Help & Support

**Scope**
- Settings → Help.
- Private support ticket creation/list/detail/reply as currently contracted.
- Request ID inclusion where useful.
- No sensitive telemetry leakage.

**Ready-to-send prompt**

> **Run FLOW-34 only. Complete the private Help & Support member journey from Settings using the current Laravel support-ticket contract. Include create/list/detail/reply where supported, safe request-ID diagnostics, loading/empty/error states and strict sensitive-data handling. Run focused tests, update tracker and stop.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-35 — Subscription / membership purchase and restore

**Scope**
- Server-authoritative plans/products.
- Store product display.
- Trial/promotion text from authoritative source.
- Purchase.
- Restore.
- Server verification.
- Refresh entitlements.
- Dynamic feature/capability flags, usage limits, country/region/platform availability, promotions, trials, percentage rollouts and individual overrides.
- No hard-coded price/plan allocation.
- No dark patterns.

**Ready-to-send prompt**

> **Run FLOW-35 only. Complete the Membership/Subscription journey in source using server-authoritative capabilities and real store product details: plan display, purchase, restore, server verification and entitlement refresh. Never hard-code illustrative prices/tiers or paywall safety actions. Run focused tests, clearly separate sandbox/real-store QA, update tracker and stop.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-36 — Data export + deletion + 30-day recovery + re-consent

**Scope**
- Data export request/status/download handoff.
- Delete account confirmation.
- Immediate discovery pause.
- 30-day recovery.
- Login for recovery.
- Cancel deletion.
- Policy re-consent without repeating onboarding.
- Retention/legal-hold unresolved decisions remain explicit.

**Ready-to-send prompt**

> **Run FLOW-36 only. Complete account lifecycle UX for data export, deletion scheduling, immediate hide, 30-day recovery/cancel, recovery login routing and future legal re-consent. Preserve any owner/legal retention decisions as explicit external gates rather than inventing policy. Run focused tests, update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### GATE-D — Full app functional milestone

**Ready-to-send prompt**

> **Run GATE-D only. Re-audit FLOW-27 through FLOW-36 and their integration with the earlier app journey. Fix regressions first, then run full Laravel tests, Flutter analyze/tests, Android build and iOS simulator build once. Produce the current APK and a concise real-device script for Profile/Edit/Settings/Verification/Safety/Notifications/Events/Support/Subscription/Deletion recovery. Update tracker and stop.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

# QUALITY CLOSURE

### FLOW-37 — Global localization visual QA

**Scope**
- Launch-ready languages.
- Roman Urdu LTR.
- Representative RTL.
- Truncation/wrapping.
- Font fallback.
- Punctuation/alignment.
- Missing hard-coded member copy.
- Language switching across major routes.

**Ready-to-send prompt**

> **Run FLOW-37 only. Perform the global localization visual-quality closure across the implemented member app. Fix hard-coded member copy, truncation/wrapping, directionality, font fallback and alignment issues for launch-ready languages, with representative RTL QA. Do not mark all 34 languages launch-ready without human/native-language review. Run focused localization tests, update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-38 — Accessibility + text scaling + keyboard + safe-area QA

**Scope**
- Screen reader semantics.
- Logical focus.
- Tap targets.
- Contrast.
- 200%/large text representative flows.
- Keyboard avoidance.
- iOS/Android navigation gestures.
- Safe areas.
- Reduced motion.

**Ready-to-send prompt**

> **Run FLOW-38 only. Perform accessibility and device-layout closure across the implemented app: semantics, focus order, tap targets, contrast, high text scaling, keyboard avoidance, safe areas, Android back/iOS navigation behavior and reduced-motion support. Fix all source-proven issues, add representative tests, update tracker and stop for physical-device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-39 — Performance + resilience + state consistency

**Scope**
- Startup/perceived performance.
- Image sizing/cache.
- Bounded pagination/prefetch.
- Offline/retry.
- Rapid taps/idempotency.
- Background/resume.
- Crash-safe routing.
- Session expiry.
- No stale client-only truth.
- Analytics, crash and performance telemetry must redact tokens, OTPs, exact coordinates, message bodies and private-media values.
- Error funnels and repeated API failures should remain observable without sensitive-content logging.

**Ready-to-send prompt**

> **Run FLOW-39 only. Perform performance/resilience closure across the member app. Audit startup, image/cache behavior, pagination/prefetch, offline/retry, rapid taps/idempotency, background/resume, session expiry and stale-state risks. Fix measurable/source-proven issues, add tests where practical, update tracker and stop for device QA.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-40 — Premium visual polish audit

**Scope**
- Whole app visual consistency.
- Design tokens.
- Typography.
- Spacing.
- Radius.
- Icons.
- Sheets/dialogs.
- Motion.
- Haptics.
- Loading/empty/restricted states.
- High-value moments.
- Compare implementation with Figma presentation frame by frame where relevant.
- Do not copy outdated/incorrect product logic.

**Ready-to-send prompt**

> **Run FLOW-40 only. Perform the premium visual-polish closure across every implemented member journey. Compare current Flutter screens with the supplied Figma/PDF presentation references, while preserving the master product flow. Fix design-token inconsistency, typography, spacing, radius, iconography, motion/haptics, loading/empty/restricted states and visible rough edges. Do not modify product rules just to imitate an old Figma frame. Update tracker and stop for my visual approval.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-41 — Trust & abuse hardening

**Scope**
- Privacy-minimized risk signals.
- Suspicious velocity.
- Ban evasion.
- Repeated media evidence where approved.
- Chat safety nudges.
- False-positive recovery.
- Moderator evidence boundaries.
- Regression tests.
- No public risk score.

**Ready-to-send prompt**

> **Run FLOW-41 only. Complete the documented launch trust/abuse hardening without changing confirmed member report categories or exposing a public risk score. Implement privacy-minimized suspicious-velocity/ban-evasion controls, approved repeated-media evidence, safe chat nudges, moderator evidence boundaries and false-positive recovery with regression tests. Update tracker and stop.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FLOW-42 — External provider + physical-device verification

**Scope**
This packet is a checklist/runbook, not a claim that source code alone can prove production behavior.

- Google sign-in real device.
- Apple sign-in real device.
- Live precise GPS/reverse geocoding.
- Cloudinary upload/moderation.
- APNs/FCM.
- Email provider.
- Private realtime broadcast transport.
- App Store / Google Play purchase + restore.
- Android screenshot secure window.
- iOS capture/recording behavior.
- RTL/accessibility on physical devices.
- Signing/capabilities.
- Production-like staging health.

**Ready-to-send prompt**

> **Run FLOW-42 only. Read current provider readiness and generate the exact external verification checklist for my available staging credentials/devices. Execute only checks possible through connected tooling; do not fake physical-device/provider success. For each item mark PASS, FAIL or OWNER ACTION REQUIRED with the smallest safe next step. Update tracker.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

# TRACK B — REACT ADMIN EXECUTION

The member app can be device-approved while the product is still incomplete. These packets close the English-only Laravel + React operations surface. No arbitrary database editor is permitted.

### ADMIN-01 — Admin authentication, session security and role shell

**Scope**
- Same-origin admin login/session behavior.
- CSRF/session security.
- Moderator vs super-admin authorization.
- Unauthorized/expired-session routing.
- Responsive navigation shell.
- No member bearer-token auth in admin.

**Ready-to-send prompt**

> **Run ADMIN-01 only. Audit and complete the React admin authentication/session/role shell using the master and Admin Operations Guide. Cover moderator vs super-admin authorization, CSRF/session expiry, unauthorized routing, responsive navigation and negative tests. Do not start operational modules yet. Update tracker and stop.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### ADMIN-02 — Dashboard, health and operational incidents

**Scope**
- Dashboard summary.
- Safe provider/readiness indicators.
- Warning/critical incidents.
- Acknowledge/resolve with reason.
- No secret values in UI/logs.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### ADMIN-03 — Members, account detail and lifecycle actions

**Scope**
- Search/filter user directory.
- Account/profile/photo/safety summary.
- Suspend/block/restore where authorized.
- Immediate token revocation/discovery pause.
- Deletion/recovery/export support operations exposed by contract.
- Immutable audit reasons.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### ADMIN-04 — Reports, safety cases and abuse-risk review

**Scope**
- Report queues.
- Risk/safety case detail.
- Privacy-minimized evidence.
- Underage escalation.
- Moderator decisions with written reasons.
- No reporter disclosure, raw secrets, exact-location history or unnecessary chat content.
- False-positive recovery path.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### ADMIN-05 — Verification review

**Scope**
- Email/phone/selfie/ID-age separation.
- Review queues/cases.
- Optional vs risk-required semantics.
- Approve/reject/request-correction.
- Minimum necessary evidence.
- Audit trail.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### ADMIN-06 — Appeals

**Scope**
- Eligible blocked/banned account appeal queue.
- One proper appeal lifecycle.
- Super-admin decision where required.
- Written reason and immutable audit.
- Member recovery/status synchronization.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### ADMIN-07 — Religion taxonomy + profile catalogs

**Scope**
- Religion → sect/tradition → sub-sect/school/movement → community/caste.
- Country/rule relationships.
- Translations.
- Activation/deactivation.
- Interests/traits.
- Spoken-language catalogs.
- Validation that taxonomy changes do not create broken onboarding paths.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### ADMIN-08 — Localization management

**Scope**
- Member translation catalog editing/review.
- Admin remains English-only.
- Locale direction/status.
- Draft vs launch-ready state.
- Version/hash invalidation behavior.
- Prevent marking languages launch-ready without required review process.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### ADMIN-09 — Broadcasts and notification operations

**Scope**
- Broadcast creation.
- Transactional/safety vs marketing distinction.
- Consent/category enforcement.
- Delivery summary/failure visibility.
- No provider secrets.
- Audit.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### ADMIN-10 — Events management

**Scope**
- Create/edit/publish/unpublish.
- Online/physical metadata.
- Date/time/location/capacity.
- Localized content.
- Attendee privacy.
- Reports/moderation.
- No public member-created event workflow in V1.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### ADMIN-11 — Subscription, features and entitlement operations

**Scope**
- Plans.
- Features/capabilities.
- Limits/counters policy.
- Store-product mappings.
- Country/platform overrides.
- User overrides.
- Promotions/trials.
- Rollouts.
- Scheduled activation.
- Protected safety/privacy/account capabilities can never be paywalled.
- No fake store products/prices.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### ADMIN-12 — Admin users/roles, privacy operations and audit browser

**Scope**
- Admin account management.
- Role assignment.
- Least privilege.
- Privacy/account operational actions.
- Immutable filtered audit browser.
- Sensitive action reasons.
- No provider-secret/raw-message/arbitrary-database-edit exposure.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### GATE-ADMIN — Complete React admin milestone

**Run**
- React production build/tests.
- Laravel admin authorization/feature tests.
- Responsive operator workflow audit.
- Negative permission tests.
- Audit-log verification.
- Product-owner/operator review.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

# TRACK C — BACKEND / OPERATIONS / PROVIDERS

These packets close non-screen work required for a real production product. They must not be skipped because the app UI looks complete.

### OPS-01 — API/contract/version compatibility

**Scope**
- Laravel routes vs OpenAPI/Postman parity.
- Generated Flutter contracts.
- Stable enums/errors/cursors.
- Public IDs only.
- Backward-compatible additive response policy.
- Admin browser-session schemes remain separate from mobile bearer auth.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### OPS-02 — Database, migrations, indexes and data integrity

**Scope**
- MySQL production-like migration reset/reapply.
- Foreign keys/indexes/cursors.
- Rollback methods.
- Duplicate identity/account merge integrity.
- No unapproved retention/legal-hold schema assumptions.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### OPS-03 — Cache, queues, scheduler and cleanup jobs

**Scope**
- Redis cache/queue connectivity.
- Worker restart/runbook.
- Scheduler.
- Expired sessions/OTPs.
- Export jobs.
- Broadcast jobs.
- Scheduled deletion/recovery jobs.
- Failed-job visibility.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### OPS-04 — Security hardening

**Scope**
- Rate limits.
- Auth negative cases.
- Replay resistance.
- Provider webhook authentication.
- Security headers.
- CSRF/session rules.
- Secret/content redaction.
- Deep-link/navigation guards.
- Dependency audits.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### OPS-05 — Privacy, deletion, retention and legal-hold policy gate

**Scope**
- Export completeness.
- 30-day deletion recovery.
- Permanent deletion/anonymization implementation only after approved policy.
- Safety/legal evidence retention boundary.
- Legal-hold decision explicitly recorded.
- No invented retention duration.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### OPS-06 — Notifications, email and realtime transport

**Scope**
- FCM/APNs workers.
- Email provider.
- Device token lifecycle.
- Delivery retries/idempotency.
- Authorized private realtime chat channels.
- Reconnect recovery.
- Provider health/failure monitoring.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### OPS-07 — Media, geolocation and store providers

**Scope**
- Cloudinary signing/upload/moderation/delivery.
- Precise GPS reverse geocoder.
- Cloudflare approximate location.
- Apple/Google identity credentials.
- App Store / Play billing, receipt verification and callbacks.
- Provider secrets never exposed.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### OPS-08 — Performance, load and observability

**Scope**
- Synthetic performance baselines.
- Approved staging load tests.
- API latency/slow-query monitoring.
- Queue depth/failures.
- Crash/ANR/performance telemetry.
- Provider/webhook health.
- Request correlation with sensitive-value redaction.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### OPS-09 — Backup, restore, incident and rollback readiness

**Scope**
- Backup policy/recency.
- Isolated restore test evidence.
- Incident acknowledgment/resolution.
- Previous-artifact rollback path.
- Database-safe rollback planning.
- No blind destructive rollback.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### OPS-10 — Staging smoke + provider readiness

**Scope**
- Production config validator.
- Health/readiness.
- Auth/onboarding/discovery/chat/safety/privacy smoke.
- Apple/Google sign-in.
- APNs/FCM/email.
- Cloudinary.
- GPS resolver.
- App Store/Play purchase/restore/webhooks.
- Realtime broadcast.
- Signing/capabilities.
- Physical-device evidence linked to FLOW-42.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### GATE-OPS — Production operations milestone

**Run**
- Production config check.
- MySQL/Redis suite.
- Dependency/security audits.
- Contract parity.
- Queue/scheduler/readiness checks.
- Staging smoke evidence.
- Backup/restore/rollback evidence where owner infrastructure allows.
- No unresolved critical incident.

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

### FINAL-GATE — Release candidate 100% audit

**Scope**
- Re-read every Track A FLOW/GATE packet, every Track B ADMIN packet and every Track C OPS packet.
- GATE-A/B/C/D, GATE-ADMIN and GATE-OPS must be satisfied where applicable.
- No unchecked applicable gap.
- Full automated suite.
- Android build.
- iOS simulator build.
- Production config validator.
- Contract parity.
- Security/privacy review.
- Final APK.
- Owner final device sign-off.
- Any owner/legal/provider unresolved item keeps overall status below 100%.

**Ready-to-send prompt**

> **Run FINAL-GATE only. Treat this as the strict SOUL V1 release-candidate audit. Read every FLOW packet and current main. Fix only clear remaining implementation regressions; do not invent owner/legal decisions. Run full Laravel tests, MySQL/Redis checks, contract audits, Flutter analyze/tests, Android build and iOS simulator build, production config validation and final documentation sync. Produce the final debug/release-candidate artifact available in this environment. Report every remaining external/owner action explicitly. A complete mobile UI with incomplete Admin/Ops/Provider work is **not** complete-app 100%. Mark 100% only if every applicable Track A + Track B + Track C strict completion gate is actually passed.**

**Status:** ⬜ NOT STARTED  
**Checkpoint:** —

---

# 4. Live progress board

Update this table after every completed packet.

| Packet | Journey | Source status | Device status | Commit | Notes |
|---|---|---|---|---|---|
| FLOW-01 | Splash + bootstrap | ⬜ | ⬜ | — | — |
| FLOW-02 | Locale + globe/location | ⬜ | ⬜ | — | — |
| FLOW-03 | Welcome + language | ⬜ | ⬜ | — | — |
| FLOW-04 | Registration entry | ⬜ | ⬜ | — | — |
| FLOW-05 | Returning email login | ⬜ | ⬜ | — | — |
| FLOW-06 | OTP | ⬜ | ⬜ | — | — |
| FLOW-07 | Google + Apple | ⬜ | ⬜ | — | — |
| GATE-A | Launch/Auth milestone | ⬜ | ⬜ | — | — |
| FLOW-08 | Name/DOB/Gender | ⬜ | ⬜ | — | — |
| FLOW-09 | Location/Nationality | ⬜ | ⬜ | — | — |
| FLOW-10 | Religion hierarchy | ⬜ | ⬜ | — | — |
| FLOW-11 | Marital/Intentions | ⬜ | ⬜ | — | — |
| FLOW-12 | Profession/Languages | ⬜ | ⬜ | — | — |
| FLOW-13 | Lifestyle/Children | ⬜ | ⬜ | — | — |
| FLOW-14 | Optional basics | ⬜ | ⬜ | — | — |
| FLOW-15 | Interests/Traits/Religion optional | ⬜ | ⬜ | — | — |
| FLOW-16 | Photos | ⬜ | ⬜ | — | — |
| FLOW-17 | Notification permission | ⬜ | ⬜ | — | — |
| FLOW-18 | Legal/Submission/Lifecycle | ⬜ | ⬜ | — | — |
| GATE-B | Onboarding milestone | ⬜ | ⬜ | — | — |
| FLOW-19 | Main navigation | ⬜ | ⬜ | — | — |
| FLOW-20 | Discovery card | ⬜ | ⬜ | — | — |
| FLOW-21 | Full profile | ⬜ | ⬜ | — | — |
| FLOW-22 | Filters | ⬜ | ⬜ | — | — |
| FLOW-23 | Incoming likes | ⬜ | ⬜ | — | — |
| FLOW-24 | Match moment/list | ⬜ | ⬜ | — | — |
| FLOW-25 | Chat | ⬜ | ⬜ | — | — |
| FLOW-26 | Private photos | ⬜ | ⬜ | — | — |
| GATE-C | Discovery/Chat milestone | ⬜ | ⬜ | — | — |
| FLOW-27 | My Profile | ⬜ | ⬜ | — | — |
| FLOW-28 | Edit Profile | ⬜ | ⬜ | — | — |
| FLOW-29 | Settings | ⬜ | ⬜ | — | — |
| FLOW-30 | Verification | ⬜ | ⬜ | — | — |
| FLOW-31 | Safety/Appeal | ⬜ | ⬜ | — | — |
| FLOW-32 | Notifications center | ⬜ | ⬜ | — | — |
| FLOW-33 | Events | ⬜ | ⬜ | — | — |
| FLOW-34 | Help/Support | ⬜ | ⬜ | — | — |
| FLOW-35 | Subscription | ⬜ | ⬜ | — | — |
| FLOW-36 | Export/Delete/Recovery/Re-consent | ⬜ | ⬜ | — | — |
| GATE-D | Full functional milestone | ⬜ | ⬜ | — | — |
| FLOW-37 | Localization visual QA | ⬜ | ⬜ | — | — |
| FLOW-38 | Accessibility/device layout | ⬜ | ⬜ | — | — |
| FLOW-39 | Performance/resilience | ⬜ | ⬜ | — | — |
| FLOW-40 | Premium visual polish | ⬜ | ⬜ | — | — |
| FLOW-41 | Trust/abuse hardening | ⬜ | ⬜ | — | — |
| FLOW-42 | External provider/device QA | ⬜ | ⬜ | — | — |
| ADMIN-01 | Admin auth/roles | ⬜ | ⬜ | — | — |
| ADMIN-02 | Dashboard/incidents | ⬜ | ⬜ | — | — |
| ADMIN-03 | Members/lifecycle | ⬜ | ⬜ | — | — |
| ADMIN-04 | Reports/safety risk | ⬜ | ⬜ | — | — |
| ADMIN-05 | Verification review | ⬜ | ⬜ | — | — |
| ADMIN-06 | Appeals | ⬜ | ⬜ | — | — |
| ADMIN-07 | Taxonomy/catalogs | ⬜ | ⬜ | — | — |
| ADMIN-08 | Localization admin | ⬜ | ⬜ | — | — |
| ADMIN-09 | Broadcasts | ⬜ | ⬜ | — | — |
| ADMIN-10 | Events admin | ⬜ | ⬜ | — | — |
| ADMIN-11 | Subscription operations | ⬜ | ⬜ | — | — |
| ADMIN-12 | Admin roles/privacy/audit | ⬜ | ⬜ | — | — |
| GATE-ADMIN | Admin milestone | ⬜ | ⬜ | — | — |
| OPS-01 | Contracts/versioning | ⬜ | ⬜ | — | — |
| OPS-02 | Database/integrity | ⬜ | ⬜ | — | — |
| OPS-03 | Cache/queues/scheduler | ⬜ | ⬜ | — | — |
| OPS-04 | Security hardening | ⬜ | ⬜ | — | — |
| OPS-05 | Privacy/retention policy | ⬜ | ⬜ | — | — |
| OPS-06 | Notifications/email/realtime | ⬜ | ⬜ | — | — |
| OPS-07 | Media/location/store providers | ⬜ | ⬜ | — | — |
| OPS-08 | Performance/observability | ⬜ | ⬜ | — | — |
| OPS-09 | Backup/restore/rollback | ⬜ | ⬜ | — | — |
| OPS-10 | Staging/provider readiness | ⬜ | ⬜ | — | — |
| GATE-OPS | Operations milestone | ⬜ | ⬜ | — | — |
| FINAL-GATE | Strict complete-app V1 release audit | ⬜ | ⬜ | — | — |

---

# 5. Owner command shortcuts

Normal next step (Track A starts first):

> **Run FLOW-01.**

Admin packet example:

> **Run ADMIN-01.**

Operations packet example:

> **Run OPS-01.**

Continue after timeout:

> **Continue FLOW-01 from repo tracker.**

Approve a device test:

> **FLOW-01 device approved. Update tracker and run FLOW-02.**

Report a device issue:

> **FLOW-01 device issue: [problem]. Fix the same flow only.**

Run a milestone:

> **Run GATE-A.**

Ask for current status:

> **Read the flow tracker and tell me exactly where we are, what is approved, what is source-complete, and what I need to test next.**

---

# 6. Why this plan is the source of execution truth

The master documentation remains the **product truth**. This file is the **execution truth** for the order in which we implement and verify the **complete V1 product: member app, admin operations and production/backend operations**.

If a future product decision changes the master flow, update the master first, then update the affected FLOW packets before continuing work.

Do not skip ahead merely because later code already exists. Existing code is audited when its FLOW packet is reached. A packet may therefore result in:
- no code change because it already passes;
- targeted fixes;
- a larger refactor if the existing implementation fails the current product/quality contract.

That keeps the repository, the assistant, the owner and the real-device build synchronized even across timeouts or new chats.
