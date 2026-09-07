# SOUL V1 Flutter API handoff

This is the versioned mobile-client contract for the SOUL V1 Laravel API. Mobile code should use public ULIDs from responses and must never depend on database IDs.

## Transport contract

- Base path: `/api/v1`
- Content type: `application/json`; the authorized private-photo content route returns image bytes with its provider MIME type
- Authentication: `Authorization: Bearer <token>` for authenticated mobile routes
- Locale: send `Accept-Language`, or `locale` on bootstrap when the user explicitly selects a language
- Dates: ISO 8601; clients should render them in the device timezone
- Correlation: retain `X-Request-ID` when reporting an API problem
- Pagination: send the opaque `next_cursor` value back as the `cursor` query parameter
- Rate limiting: treat HTTP 429 as retryable and respect `Retry-After` when present

Successful JSON responses use:

```json
{"success":true,"message":"OK","data":{},"meta":{"request_id":"..."}}
```

Error responses use:

```json
{"success":false,"error":{"code":"VALIDATION_ERROR","message":"...","details":{"fields":{}}},"meta":{"request_id":"..."}}
```

Client behavior by status: 401 clears the invalid session, 403 shows account access state, 409 shows the returned correction/state flow, 422 maps field errors, and 429 retries with backoff. Unknown error codes must fall back to the server message without crashing.

## Public and authentication endpoints

| Method | Path | Route contract | Purpose |
|---|---|---|---|
| GET | `/health` | `api.v1.health` | Liveness |
| GET | `/health/ready` | `api.v1.health.ready` | Dependency readiness |
| GET | `/bootstrap` | `api.v1.bootstrap` | Brand, locale, translations and approximate location |
| POST | `/auth/register/request-otp` | `api.v1.auth.register.request-otp` | Request registration OTP |
| POST | `/auth/register/verify-otp` | `api.v1.auth.register.verify-otp` | Verify registration and issue token |
| POST | `/auth/login/request-otp` | `api.v1.auth.login.request-otp` | Request login OTP |
| POST | `/auth/login/verify-otp` | `api.v1.auth.login.verify-otp` | Verify login and issue token |
| POST | `/auth/google` | `api.v1.auth.google` | Google identity sign-in |
| POST | `/auth/apple` | `api.v1.auth.apple` | Apple identity sign-in |
| GET | `/auth/me` | `api.v1.auth.me` | Resume current account |
| POST | `/auth/logout` | `api.v1.auth.logout` | Revoke current token |
| POST | `/auth/logout-all` | `api.v1.auth.logout-all` | Revoke all tokens |
| POST | `/location/resolve` | `api.v1.location.resolve` | Resolve coordinates without inventing a fallback city |

## Onboarding and media endpoints

| Method | Path | Route contract | Purpose |
|---|---|---|---|
| GET | `/onboarding/religion-options` | `api.v1.onboarding.religion-options` | Country-aware religion hierarchy |
| GET | `/onboarding/religion-profile` | `api.v1.onboarding.religion-profile.show` | Resume saved selection |
| PUT | `/onboarding/religion-profile` | `api.v1.onboarding.religion-profile.store` | Save complete hierarchy path |
| GET | `/onboarding/profile` | `api.v1.onboarding.profile.show` | Resume draft profile |
| PUT | `/onboarding/profile` | `api.v1.onboarding.profile.update` | Partially update draft |
| GET | `/onboarding/readiness` | `api.v1.onboarding.readiness.show` | Missing requirements and correction screens |
| POST | `/onboarding/submit` | `api.v1.onboarding.submit` | Submit complete draft |
| GET | `/onboarding/status` | `api.v1.onboarding.status` | Lifecycle and automated-check status |
| POST | `/onboarding/resubmit` | `api.v1.onboarding.resubmit` | Resubmit corrected profile |
| GET | `/onboarding/photos` | `api.v1.onboarding.photos.index` | List photo slots and moderation state |
| POST | `/onboarding/photos/upload-session` | `api.v1.onboarding.photos.upload-session.create` | Create short-lived direct-upload signature |
| PUT | `/onboarding/photos/{position}` | `api.v1.onboarding.photos.register` | Register verified Cloudinary response |
| DELETE | `/onboarding/photos/{position}` | `api.v1.onboarding.photos.delete` | Remove slot and queue provider cleanup |

Photo upload sequence: request a session for position 1–3, upload directly using only returned signed fields, then register the exact response and session token. Position 1 is the public cover. Render moderation and `correction_screen` from the API instead of guessing approval state.

Positions 2 and 3 use authenticated Cloudinary delivery even when currently public, so they can safely change to private later. Send every returned upload parameter, including `type`, unchanged.

## Discovery, matching and messaging endpoints

| Method | Path | Route contract | Purpose |
|---|---|---|---|
| GET | `/discovery/preferences` | `api.v1.discovery.preferences.show` | Resume filters |
| PUT | `/discovery/preferences` | `api.v1.discovery.preferences.update` | Save age, gender and country filters |
| GET | `/discovery/candidates` | `api.v1.discovery.candidates.index` | Cursor-paginated eligible profiles |
| GET | `/profiles/{profile}` | `api.v1.profiles.show` | Safe full public profile with prominent marital status |
| POST | `/profiles/{profile}/decision` | `api.v1.matching.decisions.store` | Idempotent like/pass and mutual match |
| GET | `/likes/received` | `api.v1.likes.received.index` | Cursor-paginated pending incoming Likes |
| PUT | `/profiles/{profile}/like` | `api.v1.likes.update` | Accept or decline a pending Like |
| DELETE | `/profiles/{profile}/like` | `api.v1.likes.destroy` | Withdraw a pending outgoing Like |
| GET | `/matches` | `api.v1.matches.index` | Cursor-paginated active matches |
| DELETE | `/matches/{match}` | `api.v1.matches.destroy` | Idempotent unmatch |
| GET | `/private-photo-access` | `api.v1.private-photo-access.index` | List incoming and outgoing access requests |
| POST | `/matches/{match}/private-photo-access` | `api.v1.private-photo-access.store` | Request access with no message/reason |
| PUT | `/private-photo-access/{accessRequest}` | `api.v1.private-photo-access.update` | Owner approves or rejects |
| DELETE | `/private-photo-access/{accessRequest}` | `api.v1.private-photo-access.destroy` | Owner revokes access |
| GET | `/matches/{match}/private-photos` | `api.v1.private-photos.index` | Approved private-photo metadata and protection contract |
| GET | `/private-photos/{photo}/content` | `api.v1.private-photos.content` | Authorized no-store image bytes |
| POST | `/private-photos/{photo}/capture-events` | `api.v1.private-photos.capture-events.store` | Idempotent best-effort capture signal |
| GET | `/matches/{match}/messages` | `api.v1.messages.index` | Cursor-paginated conversation |
| POST | `/matches/{match}/messages` | `api.v1.messages.store` | Send trimmed non-empty message |
| POST | `/matches/{match}/messages/read` | `api.v1.messages.read` | Mark received messages read and expose receipts |
| GET | `/matches/{match}/presence` | `api.v1.chat.presence.show` | Counterpart online, last-seen and typing state |
| PUT | `/matches/{match}/typing` | `api.v1.chat.typing.update` | Refresh or clear the short-lived typing signal |

Do not cache candidate, match or message pages across users. A 404 for a profile or match is intentionally non-enumerating and can mean unavailable, hidden, blocked, suspended or not owned.

## Safety, notifications and privacy endpoints

| Method | Path | Route contract | Purpose |
|---|---|---|---|
| POST | `/profiles/{profile}/block` | `api.v1.safety.blocks.store` | Block and close interaction |
| POST | `/profiles/{profile}/report` | `api.v1.safety.reports.store` | Submit safe report receipt |
| GET | `/account-appeal` | `api.v1.account-appeal.show` | Resume the blocked-account appeal state |
| POST | `/account-appeal` | `api.v1.account-appeal.store` | Submit the one allowed blocked-account appeal |
| GET | `/verification/cases` | `api.v1.verification.cases.index` | List owned verification cases |
| GET | `/verification/summary` | `api.v1.verification.summary` | Separate account checks and public badge states |
| POST | `/verification/cases` | `api.v1.verification.cases.store` | Request identity/selfie review |
| POST | `/verification/cases/{case}/appeal` | `api.v1.verification.appeals.store` | Submit one eligible appeal |
| POST | `/devices` | `api.v1.devices.store` | Register encrypted iOS/Android push token |
| DELETE | `/devices/{device}` | `api.v1.devices.destroy` | Revoke owned device |
| GET | `/notification-preferences` | `api.v1.notification-preferences.show` | Load separate push/email defaults and locked safety category |
| PUT | `/notification-preferences` | `api.v1.notification-preferences.update` | Partial channel update; marketing opt-in records consent |
| GET | `/notifications` | `api.v1.notifications.index` | Cursor-paginated private feed |
| POST | `/notifications/{notification}/read` | `api.v1.notifications.read` | Idempotent read state |
| GET | `/events` | `api.v1.events.index` | Upcoming published events |
| GET | `/events/{event}` | `api.v1.events.show` | Localized event details; online URL only after joining |
| POST | `/events/{event}/registration` | `api.v1.events.registration.store` | Capacity-safe idempotent join |
| DELETE | `/events/{event}/registration` | `api.v1.events.registration.destroy` | Idempotent leave |
| POST | `/events/{event}/report` | `api.v1.events.reports.store` | Private idempotent event report |
| GET | `/privacy/settings` | `api.v1.privacy.settings.show` | Load privacy defaults |
| PUT | `/privacy/settings` | `api.v1.privacy.settings.update` | Partial privacy update |
| PUT | `/privacy/contacts` | `api.v1.privacy.contacts.update` | Replace privacy-safe contact hashes |
| POST | `/privacy/exports` | `api.v1.privacy.exports.store` | Idempotently request export |
| GET | `/privacy/exports` | `api.v1.privacy.exports.index` | Poll export status |
| GET | `/privacy/exports/{export}/download` | `api.v1.privacy.exports.download` | Owner-only private download |
| POST | `/privacy/deletion` | `api.v1.privacy.deletion.store` | Schedule deletion with confirmation |
| GET | `/privacy/deletion` | `api.v1.privacy.deletion.show` | Resume scheduled-deletion state |
| DELETE | `/privacy/deletion` | `api.v1.privacy.deletion.destroy` | Cancel inside grace period |

Age and read receipts are mandatory V1 behavior and cannot be disabled. Account deletion has a 30-day recovery period. Safety notifications cannot be disabled. The app must not log push tokens, export contents, OTPs, OAuth tokens, message bodies or raw identity-provider payloads.

Verification UI must render the four summary entries independently. Email is an account check. Phone, selfie and identity/age can earn public badges. A user-requested optional check never pauses a live profile; only a server-created risk-required case can return `blocks_profile: true`. Public profiles receive booleans only—never case reasons, reviewer notes or documents.

## Custom React administration endpoints

The React admin uses same-origin secure session cookies, not mobile bearer tokens.

| Method | Path | Route contract | Purpose |
|---|---|---|---|
| GET | `/admin/dashboard` | `api.v1.admin.dashboard` | Queue counts |
| GET | `/admin/reports` | `api.v1.admin.reports.index` | Pending reports |
| PUT | `/admin/reports/{report}` | `api.v1.admin.reports.update` | Moderation decision with reason |
| GET | `/admin/safety-cases` | `api.v1.admin.safety-cases.index` | Risk and underage review queue |
| PUT | `/admin/safety-cases/{case}` | `api.v1.admin.safety-cases.update` | Clear or require verification with audit evidence |
| GET | `/admin/verifications` | `api.v1.admin.verifications.index` | Reviewable verification cases |
| PUT | `/admin/verifications/{case}` | `api.v1.admin.verifications.update` | Verification decision with audit event |
| GET | `/admin/account-appeals` | `api.v1.admin.account-appeals.index` | Pending banned-account appeals |
| PUT | `/admin/account-appeals/{appeal}` | `api.v1.admin.account-appeals.update` | Super-admin accepts or rejects an appeal once |
| GET | `/admin/users` | `api.v1.admin.users.index` | Search and filter user directory |
| GET | `/admin/users/{user}` | `api.v1.admin.users.show` | Inspect account, profile, photo and safety summary |
| PUT | `/admin/users/{user}/status` | `api.v1.admin.users.status.update` | Super-admin suspend, block or restore |
| GET | `/admin/audit-logs` | `api.v1.admin.audit-logs.index` | Filtered immutable operations history |
| GET | `/admin/admins` | `api.v1.admin.admins.index` | Super-admin account directory |
| POST | `/admin/admins` | `api.v1.admin.admins.store` | Create secure moderator or super-admin account |
| PUT | `/admin/admins/{admin}/role` | `api.v1.admin.admins.role.update` | Change another admin role and revoke sessions |
| DELETE | `/admin/admins/{admin}` | `api.v1.admin.admins.destroy` | Remove another admin's access safely |
| GET | `/admin/religion-taxonomy` | `api.v1.admin.religion-taxonomy.index` | Browse the complete taxonomy with translations and country rules |
| POST | `/admin/religion-taxonomy` | `api.v1.admin.religion-taxonomy.store` | Create a localized taxonomy option safely |
| PUT | `/admin/religion-taxonomy/{node}` | `api.v1.admin.religion-taxonomy.update` | Update hierarchy, translations, availability and ordering |
| GET | `/admin/notification-broadcasts` | `api.v1.admin.notification-broadcasts.index` | Browse broadcast lifecycle and delivery/read analytics |
| POST | `/admin/notification-broadcasts` | `api.v1.admin.notification-broadcasts.store` | Create a preference-aware targeted draft with recipient estimate |
| POST | `/admin/notification-broadcasts/{broadcast}/send` | `api.v1.admin.notification-broadcasts.send` | Explicitly confirm and queue an idempotent broadcast |
| GET | `/admin/events` | `api.v1.admin.events.index` | Browse all event states and registration counts |
| POST | `/admin/events` | `api.v1.admin.events.store` | Create localized event draft |
| PUT | `/admin/events/{event}` | `api.v1.admin.events.update` | Update event content and logistics |
| PUT | `/admin/events/{event}/status` | `api.v1.admin.events.status.update` | Publish, return to draft or cancel with audit reason |
| GET | `/admin/event-reports` | `api.v1.admin.event-reports.index` | Private pending event-report queue |
| PUT | `/admin/event-reports/{report}` | `api.v1.admin.event-reports.update` | Resolve, dismiss or cancel event |

## Provider-only endpoint

| Method | Path | Route contract | Purpose |
|---|---|---|---|
| POST | `/webhooks/cloudinary/moderation` | `api.v1.webhooks.cloudinary.moderation` | Ingest signed Cloudinary moderation notification |

This endpoint is for signed Cloudinary notifications only. Flutter must never call it.

## Stable V1 enums

- Gender: `man`, `woman`
- Religion discovery mode: `my_religion`, `all_religions`
- Marital status: `never_married`, `married`, `separated`, `divorced`, `widowed`
- Profession/status: `employed`, `self_employed`, `student`, `homemaker`, `unemployed`, `retired`, `other`
- Smoking/alcohol: `no`, `occasionally`, `yes`, `prefer_not_to_say`
- Current children: `no`, `yes_living_with_me`, `yes_not_living_with_me`, `prefer_not_to_say`
- Future children: `want_children`, `do_not_want_children`, `open_to_children`, `not_sure`, `prefer_not_to_say`
- Profile decision: `like`, `pass`
- Device platform: `ios`, `android`
- Verification type: `identity`, `selfie_review`
- Report category: `fake_profile`, `scam`, `harassment`, `nudity_sexual_content`, `underage`, `false_marital_status`, `other`
- Report action: `report_only`, `report_and_block`
- Profile lifecycle: `draft`, `submitted`, `automated_checks`, `live`, plus correction/paused states returned by the status endpoint

Clients must tolerate additive response fields and new enum values by showing a safe fallback. Removing/renaming fields or changing their meaning requires a new API version.

The complete profile request, optional-field limits and Skip/Prefer-not-to-say behavior are maintained in `PROFILE_INFORMATION_CONTRACT.md`.
Religion root matching, hierarchy and country behavior are maintained in `RELIGION_DISCOVERY_CONTRACT.md`.
Discovery filters, distance bands, activity and privacy behavior are maintained in `DISCOVERY_PRIVACY_CONTRACT.md`.
Private access, authenticated media delivery and platform capture behavior are maintained in `PRIVATE_PHOTO_CONTRACT.md`.
Marital-status visibility and full-profile behavior are maintained in `MARITAL_STATUS_CONTRACT.md`.
