# Notification contract

This guide explains how Flutter should handle SOUL V1 notifications.

## Onboarding permission prompt

Near the end of onboarding, explain why notifications help, then let the member choose **Allow** or **Not now**. A denied operating-system permission must never block profile completion. Register a device token only after permission is granted.

## Preference channels

`GET /api/v1/notification-preferences` returns separate `push` and `email` objects. Update only changed values with `PUT`; omitted values stay unchanged.

| Category | Push default | Email default | Member can disable? |
|---|---:|---:|---:|
| New matches | On | On | Yes |
| New messages | On | Off | Yes |
| Private photos | On | Off | Yes |
| Verification | On | On | Yes, unless a safety action requires it |
| Account | On | On | Yes |
| Marketing | Off | Off | Yes; explicit opt-in is recorded |
| Safety | On | On | No |

Every event is kept in the in-app feed even when optional push/email channels are disabled. This prevents a settings choice from hiding important history.

## Client behavior

- Render the in-app feed from `GET /notifications`; `delivery_channels` explains which channels were selected when the event was created.
- Mark an event read with `POST /notifications/{id}/read`. Repeating the request is safe.
- Do not retry device-token registration with a different token unless the provider actually rotated it.
- The backend deduplicates event retries. Flutter must also avoid showing two local banners for the same notification `id`.
- Safety notifications contain actions, not reporter identity or private moderation evidence.

## Event families

Match and message events use their matching preferences. Private-photo requests/decisions use `private_photos`. Verification review results use `verification`. Appeal/account decisions use `account`. Underage, risk and moderation enforcement uses mandatory `safety` delivery.

Actual APNs/FCM and email provider credentials are environment configuration. Missing production provider credentials are a release blocker, not a reason to expose secrets to Flutter.
