import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/core/api_client.dart';
import 'package:soul_member_app/src/core/session_store.dart';
import 'package:soul_member_app/src/core/translation_cache_store.dart';
import 'package:soul_member_app/src/features/bootstrap/bootstrap_repository.dart';

class _TestSessionStore extends SessionStore {
  _TestSessionStore() : super(const FlutterSecureStorage());
}

class _FakeApiClient extends SoulApiClient {
  _FakeApiClient(SessionStore sessions, this.response) : super(sessions);

  final Map<String, dynamic> response;
  Map<String, dynamic>? lastQuery;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    expect(path, 'bootstrap');
    lastQuery = query;
    return response;
  }
}

void main() {
  test('translation cache round-trips outside secure storage', () async {
    final directory = await Directory.systemTemp.createTemp('soul-cache-test-');
    addTearDown(() async {\n      await directory.delete(recursive: true);\n    });

    final store = TranslationCacheStore(
      file: File('${directory.path}/translations.json'),
    );
    final expected = CachedTranslations(
      locale: 'ur',
      version: '18',
      hash: List.filled(64, 'a').join(),
      values: const {'auth.create_account': 'Account banayein'},
    );

    await store.write(expected);
    final loaded = await store.read();

    expect(loaded, isNotNull);
    expect(loaded!.locale, 'ur');
    expect(loaded.version, '18');
    expect(loaded.hash, expected.hash);
    expect(loaded.values, expected.values);
  });

  test('bootstrap reuses cached values when server hash is unchanged', () async {
    final directory = await Directory.systemTemp.createTemp('soul-bootstrap-');
    addTearDown(() async {\n      await directory.delete(recursive: true);\n    });

    final cache = TranslationCacheStore(
      file: File('${directory.path}/translations.json'),
    );
    final hash = List.filled(64, 'b').join();
    await cache.write(
      CachedTranslations(
        locale: 'en',
        version: '18',
        hash: hash,
        values: const {'auth.create_account': 'Create Account'},
      ),
    );

    final sessions = _TestSessionStore();
    final api = _FakeApiClient(sessions, {
      'locale': {
        'resolved': 'en',
        'direction': 'ltr',
      },
      'translations': {
        'version': '18',
        'hash': hash,
        'not_modified': true,
        'values': null,
      },
      'legal': {
        'versions': <String, String>{},
        'commitment_keys': <String>[],
      },
      'supported_languages': <Map<String, dynamic>>[],
      'location_status': 'resolved',
      'location': {
        'city': 'Karachi',
        'country_code': 'PK',
        'is_approximate': true,
      },
      'capabilities': {
        'features': {
          'incognito': true,
        },
      },
    });

    final state = await BootstrapRepository(api, cache).load();

    expect(api.lastQuery?['translations_hash'], hash);
    expect(state.translationHash, hash);
    expect(state.translations['auth.create_account'], 'Create Account');
    expect(state.locationStatus, 'resolved');
    expect(state.location?.city, 'Karachi');
    expect(state.capabilities?['features'], {'incognito': true});
  });

  test('bootstrap stores fresh translations when server hash changes', () async {
    final directory = await Directory.systemTemp.createTemp('soul-bootstrap-');
    addTearDown(() async {\n      await directory.delete(recursive: true);\n    });

    final cache = TranslationCacheStore(
      file: File('${directory.path}/translations.json'),
    );
    final hash = List.filled(64, 'c').join();
    final sessions = _TestSessionStore();
    final api = _FakeApiClient(sessions, {
      'locale': {
        'resolved': 'en',
        'direction': 'ltr',
      },
      'translations': {
        'version': '19',
        'hash': hash,
        'not_modified': false,
        'values': {
          'auth.create_account': 'Create Account',
          'common.continue': 'Continue',
        },
      },
      'legal': {
        'versions': <String, String>{},
        'commitment_keys': <String>[],
      },
      'supported_languages': <Map<String, dynamic>>[],
      'location': null,
    });

    final state = await BootstrapRepository(api, cache).load();
    final persisted = await cache.read();

    expect(state.translationVersion, '19');
    expect(state.translationHash, hash);
    expect(persisted, isNotNull);
    expect(persisted!.hash, hash);
    expect(persisted.values['common.continue'], 'Continue');
  });
}
