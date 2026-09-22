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
  _FakeApiClient(super.sessions, this.response);

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


class _FailingApiClient extends SoulApiClient {
  _FailingApiClient(super.sessions, this.failure);

  final SoulApiFailure failure;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    throw failure;
  }
}

void main() {
  test('translation cache round-trips outside secure storage', () async {
    final directory = await Directory.systemTemp.createTemp('soul-cache-test-');
    addTearDown(() async {
      await directory.delete(recursive: true);
    });

    final store = TranslationCacheStore(
      file: File('${directory.path}/translations.json'),
    );
    final expected = CachedTranslations(
      locale: 'ur',
      version: '18',
      hash: List.filled(64, 'a').join(),
      values: const {'auth.create_account': 'Account banayein'},
      direction: 'ltr',
      supportedLanguages: const [
        {
          'code': 'ur',
          'name': 'Roman Urdu',
          'native_name': 'Roman Urdu',
          'direction': 'ltr',
          'is_launch_ready': true,
        },
      ],
    );

    await store.write(expected);
    final loaded = await store.read();

    expect(loaded, isNotNull);
    expect(loaded!.locale, 'ur');
    expect(loaded.version, '18');
    expect(loaded.hash, expected.hash);
    expect(loaded.values, expected.values);
    expect(loaded.direction, 'ltr');
    expect(loaded.supportedLanguages.single['code'], 'ur');
  });

  test('bootstrap reuses cached values when server hash is unchanged', () async {
    final directory = await Directory.systemTemp.createTemp('soul-bootstrap-');
    addTearDown(() async {
      await directory.delete(recursive: true);
    });

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


  test('cache write failure never blocks fresh bootstrap data', () async {
    final directory = await Directory.systemTemp.createTemp('soul-cache-fail-');
    addTearDown(() async {
      await directory.delete(recursive: true);
    });

    final blocker = File('${directory.path}/not-a-directory');
    await blocker.writeAsString('blocked');
    final cache = TranslationCacheStore(
      file: File('${blocker.path}/translations.json'),
    );
    final hash = List.filled(64, 'd').join();
    final api = _FakeApiClient(_TestSessionStore(), {
      'locale': {'resolved': 'en', 'direction': 'ltr'},
      'translations': {
        'version': '20',
        'hash': hash,
        'not_modified': false,
        'values': {'common.continue': 'Continue'},
      },
      'legal': {
        'versions': <String, String>{},
        'commitment_keys': <String>[],
      },
      'supported_languages': <Map<String, dynamic>>[],
      'location_status': 'unavailable',
      'location': null,
      'capabilities': null,
    });

    final state = await BootstrapRepository(api, cache).load();

    expect(state.translationVersion, '20');
    expect(state.translations['common.continue'], 'Continue');
  });



  test('network bootstrap failure uses the last valid catalog safely', () async {
    final directory = await Directory.systemTemp.createTemp('soul-offline-');
    addTearDown(() async {
      await directory.delete(recursive: true);
    });

    final cache = TranslationCacheStore(
      file: File('${directory.path}/translations.json'),
    );
    final hash = List.filled(64, 'e').join();
    await cache.write(
      CachedTranslations(
        locale: 'ar',
        version: '21',
        hash: hash,
        values: const {
          'error.bootstrap_unavailable': 'تعذر تحميل SOUL الآن.',
          'common.retry': 'إعادة المحاولة',
        },
        direction: 'rtl',
        supportedLanguages: const [
          {
            'code': 'ar',
            'name': 'Arabic',
            'native_name': 'العربية',
            'direction': 'rtl',
            'is_launch_ready': true,
          },
        ],
      ),
    );

    final api = _FailingApiClient(
      _TestSessionStore(),
      const SoulApiFailure(
        statusCode: null,
        code: 'NETWORK_ERROR',
        message: 'Offline',
      ),
    );

    final state = await BootstrapRepository(api, cache).load();

    expect(state.locale, 'ar');
    expect(state.direction, 'rtl');
    expect(state.translationHash, hash);
    expect(state.supportedLanguages.single.code, 'ar');
    expect(state.locationStatus, 'unavailable');
    expect(state.location, isNull);
    expect(state.capabilities, isNull);
    expect(state.legalVersions, isEmpty);
  });

  test('non-retryable bootstrap failure is not hidden by cached data', () async {
    final directory = await Directory.systemTemp.createTemp('soul-offline-');
    addTearDown(() async {
      await directory.delete(recursive: true);
    });

    final cache = TranslationCacheStore(
      file: File('${directory.path}/translations.json'),
    );
    await cache.write(
      CachedTranslations(
        locale: 'en',
        version: '18',
        hash: List.filled(64, 'f').join(),
        values: const {'common.retry': 'Retry'},
      ),
    );

    final api = _FailingApiClient(
      _TestSessionStore(),
      const SoulApiFailure(
        statusCode: 422,
        code: 'INVALID_BOOTSTRAP',
        message: 'Invalid bootstrap request.',
      ),
    );

    await expectLater(
      BootstrapRepository(api, cache).load(),
      throwsA(
        isA<SoulApiFailure>().having(
          (failure) => failure.statusCode,
          'statusCode',
          422,
        ),
      ),
    );
  });

  test('bootstrap stores fresh translations when server hash changes', () async {
    final directory = await Directory.systemTemp.createTemp('soul-bootstrap-');
    addTearDown(() async {
      await directory.delete(recursive: true);
    });

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
