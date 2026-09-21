# SOUL member app

The Flutter Android/iOS member application lives here. It uses the Laravel member API only; React-admin routes and provider webhooks are intentionally excluded.

`lib/src/generated/` is an exact checked-in copy of the backend-generated member contract. CI rejects drift between it and `docs/contracts/`.

## Local bootstrap

Android and iOS runners are version-controlled. Do **not** run `flutter create` over this directory: it can overwrite reviewed native permissions, entitlements and release configuration.

From this folder:

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=SOUL_API_ORIGIN=http://10.0.2.2:8000
```

Use an HTTPS API origin for release builds.

## Native/provider release gates

Source integration for Apple/Google sign-in, APNs/FCM, store purchases and protected-photo handling is checked in and covered by CI. Real release verification still requires the owner's provider accounts, credentials, signing and physical devices.

Before production release, follow the Production readiness and Release closure chapters in `docs/SOUL_V1_MASTER_DOCUMENTATION.md` and run the documented production configuration checks. Never commit provider secrets.
