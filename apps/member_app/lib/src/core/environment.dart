abstract final class SoulEnvironment {
  /// Do not point a release build at an unencrypted endpoint.
  static const apiOrigin = String.fromEnvironment(
    'SOUL_API_ORIGIN',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static Uri get apiBaseUri => Uri.parse('$apiOrigin/api/v1/');

  static const firebaseApiKey = String.fromEnvironment('SOUL_FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('SOUL_FIREBASE_APP_ID');
  static const firebaseMessagingSenderId =
      String.fromEnvironment('SOUL_FIREBASE_MESSAGING_SENDER_ID');
  static const firebaseProjectId =
      String.fromEnvironment('SOUL_FIREBASE_PROJECT_ID');
  static const firebaseIosBundleId =
      String.fromEnvironment('SOUL_FIREBASE_IOS_BUNDLE_ID');

  static bool get hasFirebaseConfiguration =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;
}
