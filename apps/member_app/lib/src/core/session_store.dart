import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CachedTranslations {
  const CachedTranslations({
    required this.locale,
    required this.version,
    required this.hash,
    required this.values,
  });

  final String locale;
  final String version;
  final String hash;
  final Map<String, String> values;
}

class SessionStore {
  SessionStore(this._storage);

  static const _tokenKey = 'soul.member.access_token';
  static const _localeKey = 'soul.member.locale';
  static const _pushDeviceIdKey = 'soul.member.push_device_id';
  static const _translationCacheKey = 'soul.member.translation_cache';
  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) => _storage.write(
        key: _tokenKey,
        value: token,
      );

  Future<String?> readLocale() => _storage.read(key: _localeKey);

  Future<void> saveLocale(String locale) => _storage.write(
        key: _localeKey,
        value: locale,
      );

  Future<CachedTranslations?> readTranslations() async {
    final raw = await _storage.read(key: _translationCacheKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final map = Map<String, dynamic>.from(decoded);
      final locale = map['locale']?.toString() ?? '';
      final version = map['version']?.toString() ?? '';
      final hash = map['hash']?.toString() ?? '';
      final values = map['values'];

      if (locale.isEmpty ||
          version.isEmpty ||
          hash.length != 64 ||
          values is! Map) {
        return null;
      }

      return CachedTranslations(
        locale: locale,
        version: version,
        hash: hash,
        values: values.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTranslations(CachedTranslations cache) =>
      _storage.write(
        key: _translationCacheKey,
        value: jsonEncode({
          'locale': cache.locale,
          'version': cache.version,
          'hash': cache.hash,
          'values': cache.values,
        }),
      );

  Future<String?> readPushDeviceId() =>
      _storage.read(key: _pushDeviceIdKey);

  Future<void> savePushDeviceId(String deviceId) => _storage.write(
        key: _pushDeviceIdKey,
        value: deviceId,
      );

  Future<void> clearPushDeviceId() =>
      _storage.delete(key: _pushDeviceIdKey);

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
