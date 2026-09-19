# SOUL member app

The Flutter Android/iOS member application lives here. It uses the Laravel member API only; React-admin routes and provider webhooks are intentionally excluded.

`lib/src/generated/` is an exact checked-in copy of the backend-generated member contract. CI rejects drift between it and `docs/contracts/`.

## Local bootstrap

Install Flutter stable, then run the following once from this folder to generate the native Android and iOS runners without changing the Dart package name:

```bash
flutter create --platforms=android,ios --org com.soul .
flutter pub get
flutter run --dart-define=SOUL_API_ORIGIN=http://10.0.2.2:8000
```

Use an HTTPS API origin for release builds. Apple/Google identity setup, APNs/FCM credentials and store signing remain environment/account work; do not commit them here.
