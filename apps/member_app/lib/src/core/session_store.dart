import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStore {
  SessionStore(this._storage);

  static const _tokenKey = 'soul.member.access_token';
  static const _localeKey = 'soul.member.locale';
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

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
