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

Map<String, dynamic> _bootstrapPayload({
  required String version,
  required String hash,
  required Map<String, String>? values,
  bool notModified = false,
  String locale = 'en',
  String direction = 'ltr',
  Object? location,
  String locationStatus = 'unavailable',
  Object? capabilities,
}) =>
    {
      'brand': {
        'name': 'SOUL',
        'translate': false,
      },
      'locale': {
        'requested': locale,
        'matched': locale,
        'resolved': locale,
        'fallback': 'en',
        'direction': direction,
      },
      'translations': {
        'version': version,
        'hash': hash,
        'not_modified': notModified,
        'values': values,
      },
      'legal': {
        'versions': <String, String>{},
        'commitment_keys': <String>[],
      },
      'supported_languages': [
        {
          'code': locale,
          'name': locale == 'ur' ? 'Roman Urdu' : 'English',
          'native_name': locale == 'ur' ? 'Roman Urdu' : 'English',
          'direction': direction,
          'is_launch_target': true,
          'is_launch_ready': true,
        },
      ],
      'location_status': locationStatus,
      'location': location,
      'capabilities': capabilities,
    };

void main() {
  test('translation cache round-trips startup configuration outside secure storage',
      () async {
    final directory = await Directory.systemTemp.createTemp('soul-cache-test-');
    addTearDown(() async {
      await directory.delete(recursive: true);
    });

    final store = TranslationCacheStore(
      file: File('${directory.path}/translations.json'),
    );
    final expected = CachedTranslations(
      brandName: 'SOUL',
      brandTranslate: false,
      locale: 'ur',
      version: '20',
      hash: List.filled(64, 'a').join(),
      values: const {'auth.create_account': 'Account banayein'},
      direction: 'ltr',
      supportedLanguages: const [
        {
          'code': 'ur',
          'name': 'Roman Urdu',
          'native_name': 'Roman Urdu',
          'direction': 'ltr',
          'is_launch_target': true,
          'is_launch_ready': true,
        },
      ],
    );

    await store.write(expected);
    final loaded = await store.read();

    expect(loaded, isNotNull);
    expect(loaded!.brandName, 'SOUL');
    expect(loaded.brandTranslate, isFalse);
    expect(loaded.locale, 'ur');
    expect(loaded.fallbackLocale, 'en');
    expect(loaded.version, '20');
    expect(loaded.hash, expected.hash);
    expect(loaded.values, expected.values);
    expect(loaded.direction, 'ltr');
    expect(loaded.supportedLanguages.single['is_launch_target'], isTrue);
  });

  test('bootstrap reuses cached values and sends mobile platform', () async {
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
        version: '20',
        hash: hash,
        values: const {'auth.create_account': 'Create Account'},
        supportedLanguages: const [
          {
            'code': 'en',
            'name': 'English',
            'native_name': 'English',
            'direction': 'ltr',
            'is_launch_target': true,
            'is_launch_ready': true,
          },
        ],
      ),
    );

    final sessions = _TestSessionStore();
    final api = _FakeApiClient(
      sessions,
      _bootstrapPayload(
        version: '20',
        hash: hash,
        notModified: true,
        values: null,
        locationStatus: 'resolved',
        location: {
          'city': 'Karachi',
          'country_code': 'PK',
          'is_approximate': true,
        },
        capabilities: {
          'incognito': {'enabled': true},
        },
      ),
    );

    final state = await BootstrapRepository(
      api,
      cache,
      platform: 'ios',
    ).load();

    expect(api.lastQuery?['translations_hash'], hash);
    expect(api.lastQuery?['platform'], 'ios');
    expect(state.brandName, 'SOUL');
    expect(state.translationHash, hash);
    expect(state.translations['auth.create_account'], 'Create Account');
    expect(state.locationStatus, 'resolved');
    expect(state.location?.city, 'Karachi');
    expect(state.capabilities?['incognito'], {'enabled': true});
    expect(state.supportedLanguages.single.isLaunchTarget, isTrue);
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
    final api = _FakeApiClient(
      _TestSessionStore(),
      _bootstrapPayload(
        version: '20',
        hash: hash,
        values: const {'common.continue': 'Continue'},
      ),
    );

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
        locale: 'ur',
        version: '20',
        hash: hash,
        values: const {
          'error.bootstrap_unavailable': 'SOUL abhi load nahi ho saka.',
          'common.retry': 'Dobara try karein',
        },
        direction: 'ltr',
        supportedLanguages: const [
          {
            'code': 'ur',
            'name': 'Roman Urdu',
            'native_name': 'Roman Urdu',
            'direction': 'ltr',
            'is_launch_target': true,
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

    final repository = BootstrapRepository(api, cache);
    final cached = await repository.cachedState();
    final state = await repository.load();

    expect(cached, isNotNull);
    expect(cached!.locale, 'ur');
    expect(state.locale, 'ur');
    expect(state.brandName, 'SOUL');
    expect(state.translationHash, hash);
    expect(state.supportedLanguages.single.code, 'ur');
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
        version: '20',
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
    final api = _FakeApiClient(
      _TestSessionStore(),
      _bootstrapPayload(
        version: '20',
        hash: hash,
        values: const {
          'auth.create_account': 'Create Account',
          'common.continue': 'Continue',
        },
      ),
    );

    final state = await BootstrapRepository(api, cache).load();
    final persisted = await cache.read();

    expect(state.translationVersion, '20');
    expect(state.translationHash, hash);
    expect(persisted, isNotNull);
    expect(persisted!.hash, hash);
    expect(persisted.values['common.continue'], 'Continue');
  });

  test('semantically corrupt cache is discarded instead of retried forever',
      () async {
    final directory = await Directory.systemTemp.createTemp('soul-corrupt-');
    addTearDown(() async {
      await directory.delete(recursive: true);
    });

    final file = File('${directory.path}/translations.json');
    final corruptHash = List.filled(64, 'a').join();
    await file.writeAsString(
      '{"locale":"en","version":"20","hash":"$corruptHash","values":{"bad":{"nested":true}}}',
    );

    final store = TranslationCacheStore(file: file);

    expect(await store.read(), isNull);
    expect(await file.exists(), isFalse);
  });
  test('legacy cached languages without launch-target flag remain usable',
      () async {
    final directory = await Directory.systemTemp.createTemp('soul-legacy-');
    addTearDown(() async {
      await directory.delete(recursive: true);
    });

    final cache = TranslationCacheStore(
      file: File('${directory.path}/translations.json'),
    );
    await cache.write(
      CachedTranslations(
        locale: 'en',
        version: '20',
        hash: List.filled(64, '9').join(),
        values: const {'common.retry': 'Retry'},
        supportedLanguages: const [
          {
            'code': 'en',
            'name': 'English',
            'native_name': 'English',
            'direction': 'ltr',
            'is_launch_ready': true,
          },
        ],
      ),
    );

    final state = await BootstrapRepository(
      _FailingApiClient(
        _TestSessionStore(),
        const SoulApiFailure(
          statusCode: null,
          code: 'NETWORK_ERROR',
          message: 'Offline',
        ),
      ),
      cache,
    ).load();

    expect(state.supportedLanguages.single.isLaunchTarget, isTrue);
  });

  test('invalid legal startup contract is rejected', () async {
    final directory = await Directory.systemTemp.createTemp('soul-legal-');
    addTearDown(() async {
      await directory.delete(recursive: true);
    });

    final hash = List.filled(64, '8').join();
    final payload = _bootstrapPayload(
      version: '20',
      hash: hash,
      values: const {'common.retry': 'Retry'},
    );
    payload['legal'] = const <String, dynamic>{};

    await expectLater(
      BootstrapRepository(
        _FakeApiClient(_TestSessionStore(), payload),
        TranslationCacheStore(
          file: File('${directory.path}/translations.json'),
        ),
      ).load(),
      throwsA(
        isA<SoulApiFailure>().having(
          (failure) => failure.code,
          'code',
          'INVALID_BOOTSTRAP_LEGAL',
        ),
      ),
    );
  });

  test('resolved startup location requires a real city and country code',
      () async {
    final directory = await Directory.systemTemp.createTemp('soul-location-');
    addTearDown(() async {
      await directory.delete(recursive: true);
    });

    final hash = List.filled(64, '7').join();

    await expectLater(
      BootstrapRepository(
        _FakeApiClient(
          _TestSessionStore(),
          _bootstrapPayload(
            version: '20',
            hash: hash,
            values: const {'common.retry': 'Retry'},
            locationStatus: 'resolved',
            location: {
              'city': '',
              'country_code': 'PK',
            },
          ),
        ),
        TranslationCacheStore(
          file: File('${directory.path}/translations.json'),
        ),
      ).load(),
      throwsA(
        isA<SoulApiFailure>().having(
          (failure) => failure.code,
          'code',
          'INVALID_BOOTSTRAP_LOCATION',
        ),
      ),
    );
  });

  test('translated or renamed bootstrap brand is rejected', () async {
    final directory = await Directory.systemTemp.createTemp('soul-brand-');
    addTearDown(() async {
      await directory.delete(recursive: true);
    });

    final payload = _bootstrapPayload(
      version: '20',
      hash: List.filled(64, '6').join(),
      values: const {'common.retry': 'Retry'},
    );
    payload['brand'] = {
      'name': 'OTHER',
      'translate': false,
    };

    await expectLater(
      BootstrapRepository(
        _FakeApiClient(_TestSessionStore(), payload),
        TranslationCacheStore(
          file: File('${directory.path}/translations.json'),
        ),
      ).load(),
      throwsA(
        isA<SoulApiFailure>().having(
          (failure) => failure.code,
          'code',
          'INVALID_BOOTSTRAP_BRAND',
        ),
      ),
    );
  });

}
