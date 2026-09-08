# Device sessions and remote logout

SOUL treats each Sanctum access token as one login session. Session responses use a public ULID and never expose the bearer token, token hash or database ID.

## Flutter flow

1. Call `GET /auth/devices` when the user opens Settings → Security → Logged-in devices.
2. Show `device_name`, `last_used_at`, `created_at` and `expires_at`.
3. Mark the record with `is_current: true` as “This device”.
4. Call `DELETE /auth/devices/{session}` after explicit confirmation.
5. If `was_current` is true, immediately remove the local bearer token and return to login.

Expired sessions are not returned. A user cannot discover or revoke another user's session; an unknown or foreign public ID returns the same `DEVICE_SESSION_NOT_FOUND` response.

## Logout choices

- `POST /auth/logout` signs out the current token.
- `DELETE /auth/devices/{session}` signs out one selected session.
- `POST /auth/logout-all` signs out every session, including the caller.

Never send or store the session ULID as authentication. It is only an identifier for the owner-authorized revocation endpoint.
