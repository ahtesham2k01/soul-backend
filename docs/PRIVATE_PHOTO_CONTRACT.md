# SOUL V1 private photos and screenshot protection

This guide explains the private-photo flow in simple client terms. Laravel is the authority for every access decision. Flutter must never guess access from an old local state.

## Product rules

- Photo 1 is always the public cover.
- Photos 2 and 3 may be public or private.
- A private-photo request is available only inside an active mutual match.
- The request button sends no reason or chat message.
- The owner can approve, reject or later revoke.
- Approval unlocks every currently approved private photo owned by that person.
- Unmatch or block revokes pending and approved access immediately.

## Request and approval flow

1. Requester calls `POST /matches/{match}/private-photo-access` with an empty JSON body.
2. Both users can refresh cursor-paginated `GET /private-photo-access`; `direction` is `incoming` or `outgoing`.
3. Owner calls `PUT /private-photo-access/{request}` with `decision: approve` or `reject`.
4. After approval, requester calls `GET /matches/{match}/private-photos`.
5. Flutter loads each returned `content_path` with the same bearer token.
6. Owner calls `DELETE /private-photo-access/{request}` to revoke.

Requests and decisions are retry-safe. A rejected or revoked requester may press Request again, which moves the same request record back to pending. The backend never returns Cloudinary public IDs or direct provider URLs.

## Secure media delivery

Secondary photo upload sessions use Cloudinary `authenticated` delivery. Registration stores the allow-listed provider format required for signed delivery, and the signed moderation webhook can confirm it. Private content is then proxied through an authenticated Laravel endpoint that re-checks the active match and approved grant on every request. Responses use `Cache-Control: private, no-store`.

Older private-marked assets created before authenticated delivery are deliberately not returned. The owner must replace them through a new upload session. This avoids presenting a legacy public provider asset as secure.

## Screenshot protection

`GET /matches/{match}/private-photos` returns a `protection` object. When enabled:

- Android must apply `FLAG_SECURE` to the protected photo screen.
- iOS must detect capture/recording signals where available, mask recording transitions and render `viewer_watermark` visibly over the image.
- Flutter may send a detected signal to `POST /private-photos/{photo}/capture-events` with a client-generated ULID and `screenshot` or `screen_recording`.
- Duplicate signals are idempotent. The owner receives one in-app notification per event ID.

The owner changes `screenshot_protection_enabled` through `PUT /privacy/settings`; it defaults to true and updates existing photos. Operating systems cannot guarantee complete prevention, especially on iOS or when another camera is used. Therefore capture notifications are explicitly best-effort, not proof of every capture.

## Errors Flutter should handle

- `MATCH_NOT_FOUND`: match is missing, ended or not owned by the caller.
- `PRIVATE_PHOTO_ACCESS_REQUIRED`: show the request/pending state instead of photos.
- `PRIVATE_PHOTO_REQUEST_NOT_FOUND`: request is not owned by the acting user.
- `PRIVATE_PHOTO_REQUEST_NOT_PENDING`: requester must send a new request first.
- `PRIVATE_PHOTO_NOT_FOUND`: photo is unavailable, unapproved, insecure legacy media or grant was revoked.
- `MEDIA_PROVIDER_UNAVAILABLE`: keep the approved state and offer Retry; do not request access again.

Never persist private image bytes, provider URLs or watermark-free screenshots to general app caches, logs, analytics or crash reports.
