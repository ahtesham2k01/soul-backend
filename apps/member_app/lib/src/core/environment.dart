abstract final class SoulEnvironment {
  /// Do not point a release build at an unencrypted endpoint.
  static const apiOrigin = String.fromEnvironment(
    'SOUL_API_ORIGIN',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static Uri get apiBaseUri => Uri.parse('$apiOrigin/api/v1/');
}
