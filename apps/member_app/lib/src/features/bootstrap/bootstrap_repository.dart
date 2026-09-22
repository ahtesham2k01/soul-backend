import '../../core/api_client.dart';
import '../../core/translation_cache_store.dart';

class SupportedLanguage {
  const SupportedLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.direction,
    required this.isLaunchReady,
    this.isLaunchTarget = true,
  });

  final String code;
  final String name;
  final String nativeName;
  final String direction;
  final bool isLaunchTarget;
  final bool isLaunchReady;

  factory SupportedLanguage.fromJson(Map<String, dynamic> json) =>
      SupportedLanguage(
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        nativeName: json['native_name']?.toString() ?? '',
        direction: json['direction']?.toString() == 'rtl' ? 'rtl' : 'ltr',
        // Older cache files predate this flag; every configured locale was a
        // launch target then, so a missing flag remains backward compatible.
        isLaunchTarget: json['is_launch_target'] != false,
        isLaunchReady: json['is_launch_ready'] == true,
      );
}

class BootstrapLocation {
  const BootstrapLocation({
    required this.city,
    required this.countryCode,
    this.country,
    this.region,
    this.isApproximate = true,
  });

  final String city;
  final String countryCode;
  final String? country;
  final String? region;
  final bool isApproximate;

  factory BootstrapLocation.fromJson(Map<String, dynamic> json) =>
      BootstrapLocation(
        city: json['city']?.toString() ?? '',
        countryCode: json['country_code']?.toString().toUpperCase() ?? '',
        country: json['country']?.toString(),
        region: json['region']?.toString(),
        isApproximate: json['is_approximate'] != false,
      );
}

class BootstrapState {
  const BootstrapState({
    this.brandName = 'SOUL',
    this.brandTranslate = false,
    required this.direction,
    required this.locale,
    this.translationVersion = '',
    this.translationHash = '',
    required this.translations,
    required this.legalVersions,
    required this.commitmentKeys,
    required this.supportedLanguages,
    this.locationStatus = 'unavailable',
    this.capabilities,
    this.location,
  });

  final String brandName;
  final bool brandTranslate;
  final String direction;
  final String locale;
  final String translationVersion;
  final String translationHash;
  final Map<String, String> translations;
  final Map<String, String> legalVersions;
  final List<String> commitmentKeys;
  final List<SupportedLanguage> supportedLanguages;
  final String locationStatus;
  final Map<String, dynamic>? capabilities;
  final BootstrapLocation? location;

  String text(String key, String fallback) => translations[key] ?? fallback;

  String format(
    String key,
    String fallback,
    Map<String, Object?> values,
  ) {
    var value = text(key, fallback);
    for (final entry in values.entries) {
      value = value.replaceAll(
        '{${entry.key}}',
        entry.value?.toString() ?? '',
      );
    }
    return value;
  }
}

class BootstrapRepository {
  BootstrapRepository(
    this._api,
    this._cache, {
    this.platform,
  });

  final SoulApiClient _api;
  final TranslationCacheStore _cache;
  final String? platform;

  Future<BootstrapState?> cachedState() async {
    final cached = await _cache.read();
    return cached == null ? null : _offlineState(cached);
  }

  Future<BootstrapState> load() async {
    final cached = await _cache.read();
    late final Map<String, dynamic> data;

    try {
      data = await _api.get(
        'bootstrap',
        query: {
          if (cached != null) 'translations_hash': cached.hash,
          if (platform != null) 'platform': platform,
        },
      );
    } on SoulApiFailure catch (failure) {
      final retryable = failure.statusCode == null ||
          (failure.statusCode != null && failure.statusCode! >= 500);

      if (cached != null && retryable) {
        return _offlineState(cached);
      }

      rethrow;
    }

    final brandData = data['brand'] is Map
        ? Map<String, dynamic>.from(data['brand'] as Map)
        : const <String, dynamic>{};
    final brandName = brandData['name']?.toString().trim() ?? '';
    final brandTranslate = brandData['translate'] == true;

    if (brandName != 'SOUL' || brandTranslate) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_BOOTSTRAP_BRAND',
        message: 'SOUL returned invalid brand configuration.',
      );
    }

    final localeData = data['locale'] is Map
        ? Map<String, dynamic>.from(data['locale'] as Map)
        : const <String, dynamic>{};
    final translationData = data['translations'] is Map
        ? Map<String, dynamic>.from(data['translations'] as Map)
        : const <String, dynamic>{};
    final locale = localeData['resolved']?.toString().trim() ?? '';
    final version = translationData['version']?.toString().trim() ?? '';
    final hash = translationData['hash']?.toString().toLowerCase() ?? '';
    final notModified = translationData['not_modified'] == true;
    final rawValues = translationData['values'];
    final direction = localeData['direction']?.toString() == 'rtl'
        ? 'rtl'
        : 'ltr';
    final supportedLanguages = _decodeSupportedLanguages(
      data['supported_languages'],
    );

    if (locale.isEmpty ||
        version.isEmpty ||
        !RegExp(r'^[a-f0-9]{64}
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_BOOTSTRAP_CONTRACT',
        message: 'SOUL returned invalid startup configuration.',
      );
    }

    Map<String, String> translations;
    if (notModified &&
        cached != null &&
        cached.locale == locale &&
        cached.hash == hash &&
        cached.version == version) {
      translations = cached.values;
    } else if (rawValues is Map &&
        rawValues.entries.every(
          (entry) => entry.key is String && entry.value is String,
        )) {
      translations = Map<String, String>.from(rawValues);
    } else {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_BOOTSTRAP_TRANSLATIONS',
        message: 'SOUL could not load the language catalog.',
      );
    }

    final legalData = data['legal'] is Map
        ? Map<String, dynamic>.from(data['legal'] as Map)
        : const <String, dynamic>{};
    final versions = legalData['versions'];
    final commitments = legalData['commitment_keys'];
    final rawLocation = data['location'];
    final rawCapabilities = data['capabilities'];
    final locationStatus = data['location_status']?.toString();

    if (versions is! Map ||
        versions.entries.any(
          (entry) => entry.key is! String || entry.value is! String,
        ) ||
        commitments is! List ||
        commitments.any((item) => item is! String)) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_BOOTSTRAP_LEGAL',
        message: 'SOUL returned invalid legal startup configuration.',
      );
    }

    if ((locationStatus == 'resolved') != (rawLocation is Map) ||
        (locationStatus != 'resolved' && locationStatus != 'unavailable')) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_BOOTSTRAP_LOCATION',
        message: 'SOUL returned invalid startup location state.',
      );
    }

    final location = rawLocation is Map
        ? BootstrapLocation.fromJson(
            Map<String, dynamic>.from(rawLocation),
          )
        : null;

    if (location != null &&
        (location.city.trim().isEmpty ||
            !RegExp(r'^[A-Z]{2}
        brandName: brandName,
        brandTranslate: brandTranslate,
        locale: locale,
        version: version,
        hash: hash,
        values: translations,
        direction: direction,
        supportedLanguages: supportedLanguages
            .map(
              (language) => <String, dynamic>{
                'code': language.code,
                'name': language.name,
                'native_name': language.nativeName,
                'direction': language.direction,
                'is_launch_target': language.isLaunchTarget,
                'is_launch_ready': language.isLaunchReady,
              },
            )
            .toList(growable: false),
      ),
    );

    return BootstrapState(
      brandName: brandName,
      brandTranslate: brandTranslate,
      direction: direction,
      locale: locale,
      translationVersion: version,
      translationHash: hash,
      translations: translations,
      legalVersions: versions is Map
          ? versions.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const <String, String>{},
      commitmentKeys: commitments is List
          ? commitments.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
      locationStatus: locationStatus!,
      capabilities: rawCapabilities is Map
          ? Map<String, dynamic>.from(rawCapabilities)
          : null,
      location: location,
      supportedLanguages: supportedLanguages,
    );
  }

  BootstrapState _offlineState(CachedTranslations cached) => BootstrapState(
        brandName: cached.brandName,
        brandTranslate: cached.brandTranslate,
        direction: cached.direction,
        locale: cached.locale,
        translationVersion: cached.version,
        translationHash: cached.hash,
        translations: cached.values,
        legalVersions: const {},
        commitmentKeys: const [],
        supportedLanguages: _decodeSupportedLanguages(
          cached.supportedLanguages,
        ),
        locationStatus: 'unavailable',
        capabilities: null,
        location: null,
      );

  List<SupportedLanguage> _decodeSupportedLanguages(Object? raw) =>
      raw is List
          ? raw
              .whereType<Map>()
              .map(
                (item) => SupportedLanguage.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((item) => item.code.isNotEmpty)
              .toList(growable: false)
          : const <SupportedLanguage>[];
}
).hasMatch(hash) ||
        supportedLanguages.isEmpty ||
        !supportedLanguages.any((language) => language.code == locale)) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_BOOTSTRAP_CONTRACT',
        message: 'SOUL returned invalid startup configuration.',
      );
    }

    Map<String, String> translations;
    if (notModified &&
        cached != null &&
        cached.locale == locale &&
        cached.hash == hash &&
        cached.version == version) {
      translations = cached.values;
    } else if (rawValues is Map &&
        rawValues.entries.every(
          (entry) => entry.key is String && entry.value is String,
        )) {
      translations = Map<String, String>.from(rawValues);
    } else {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_BOOTSTRAP_TRANSLATIONS',
        message: 'SOUL could not load the language catalog.',
      );
    }

    final legalData = data['legal'] is Map
        ? Map<String, dynamic>.from(data['legal'] as Map)
        : const <String, dynamic>{};
    final versions = legalData['versions'];
    final commitments = legalData['commitment_keys'];
    final rawLocation = data['location'];
    final rawCapabilities = data['capabilities'];
    final locationStatus = data['location_status']?.toString();

    if ((locationStatus == 'resolved') != (rawLocation is Map) ||
        (locationStatus != 'resolved' && locationStatus != 'unavailable')) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_BOOTSTRAP_LOCATION',
        message: 'SOUL returned invalid startup location state.',
      );
    }

    await _cache.write(
      CachedTranslations(
        brandName: brandName,
        brandTranslate: brandTranslate,
        locale: locale,
        version: version,
        hash: hash,
        values: translations,
        direction: direction,
        supportedLanguages: supportedLanguages
            .map(
              (language) => <String, dynamic>{
                'code': language.code,
                'name': language.name,
                'native_name': language.nativeName,
                'direction': language.direction,
                'is_launch_target': language.isLaunchTarget,
                'is_launch_ready': language.isLaunchReady,
              },
            )
            .toList(growable: false),
      ),
    );

    return BootstrapState(
      brandName: brandName,
      brandTranslate: brandTranslate,
      direction: direction,
      locale: locale,
      translationVersion: version,
      translationHash: hash,
      translations: translations,
      legalVersions: versions is Map
          ? versions.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const <String, String>{},
      commitmentKeys: commitments is List
          ? commitments.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
      locationStatus: locationStatus!,
      capabilities: rawCapabilities is Map
          ? Map<String, dynamic>.from(rawCapabilities)
          : null,
      location: rawLocation is Map
          ? BootstrapLocation.fromJson(
              Map<String, dynamic>.from(rawLocation),
            )
          : null,
      supportedLanguages: supportedLanguages,
    );
  }

  BootstrapState _offlineState(CachedTranslations cached) => BootstrapState(
        brandName: cached.brandName,
        brandTranslate: cached.brandTranslate,
        direction: cached.direction,
        locale: cached.locale,
        translationVersion: cached.version,
        translationHash: cached.hash,
        translations: cached.values,
        legalVersions: const {},
        commitmentKeys: const [],
        supportedLanguages: _decodeSupportedLanguages(
          cached.supportedLanguages,
        ),
        locationStatus: 'unavailable',
        capabilities: null,
        location: null,
      );

  List<SupportedLanguage> _decodeSupportedLanguages(Object? raw) =>
      raw is List
          ? raw
              .whereType<Map>()
              .map(
                (item) => SupportedLanguage.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((item) => item.code.isNotEmpty)
              .toList(growable: false)
          : const <SupportedLanguage>[];
}
).hasMatch(location.countryCode))) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_BOOTSTRAP_LOCATION',
        message: 'SOUL returned incomplete startup location data.',
      );
    }

    await _cache.write(
      CachedTranslations(
        brandName: brandName,
        brandTranslate: brandTranslate,
        locale: locale,
        version: version,
        hash: hash,
        values: translations,
        direction: direction,
        supportedLanguages: supportedLanguages
            .map(
              (language) => <String, dynamic>{
                'code': language.code,
                'name': language.name,
                'native_name': language.nativeName,
                'direction': language.direction,
                'is_launch_target': language.isLaunchTarget,
                'is_launch_ready': language.isLaunchReady,
              },
            )
            .toList(growable: false),
      ),
    );

    return BootstrapState(
      brandName: brandName,
      brandTranslate: brandTranslate,
      direction: direction,
      locale: locale,
      translationVersion: version,
      translationHash: hash,
      translations: translations,
      legalVersions: versions is Map
          ? versions.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const <String, String>{},
      commitmentKeys: commitments is List
          ? commitments.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
      locationStatus: locationStatus!,
      capabilities: rawCapabilities is Map
          ? Map<String, dynamic>.from(rawCapabilities)
          : null,
      location: rawLocation is Map
          ? BootstrapLocation.fromJson(
              Map<String, dynamic>.from(rawLocation),
            )
          : null,
      supportedLanguages: supportedLanguages,
    );
  }

  BootstrapState _offlineState(CachedTranslations cached) => BootstrapState(
        brandName: cached.brandName,
        brandTranslate: cached.brandTranslate,
        direction: cached.direction,
        locale: cached.locale,
        translationVersion: cached.version,
        translationHash: cached.hash,
        translations: cached.values,
        legalVersions: const {},
        commitmentKeys: const [],
        supportedLanguages: _decodeSupportedLanguages(
          cached.supportedLanguages,
        ),
        locationStatus: 'unavailable',
        capabilities: null,
        location: null,
      );

  List<SupportedLanguage> _decodeSupportedLanguages(Object? raw) =>
      raw is List
          ? raw
              .whereType<Map>()
              .map(
                (item) => SupportedLanguage.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((item) => item.code.isNotEmpty)
              .toList(growable: false)
          : const <SupportedLanguage>[];
}
).hasMatch(hash) ||
        supportedLanguages.isEmpty ||
        !supportedLanguages.any((language) => language.code == locale)) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_BOOTSTRAP_CONTRACT',
        message: 'SOUL returned invalid startup configuration.',
      );
    }

    Map<String, String> translations;
    if (notModified &&
        cached != null &&
        cached.locale == locale &&
        cached.hash == hash &&
        cached.version == version) {
      translations = cached.values;
    } else if (rawValues is Map &&
        rawValues.entries.every(
          (entry) => entry.key is String && entry.value is String,
        )) {
      translations = Map<String, String>.from(rawValues);
    } else {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_BOOTSTRAP_TRANSLATIONS',
        message: 'SOUL could not load the language catalog.',
      );
    }

    final legalData = data['legal'] is Map
        ? Map<String, dynamic>.from(data['legal'] as Map)
        : const <String, dynamic>{};
    final versions = legalData['versions'];
    final commitments = legalData['commitment_keys'];
    final rawLocation = data['location'];
    final rawCapabilities = data['capabilities'];
    final locationStatus = data['location_status']?.toString();

    if ((locationStatus == 'resolved') != (rawLocation is Map) ||
        (locationStatus != 'resolved' && locationStatus != 'unavailable')) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_BOOTSTRAP_LOCATION',
        message: 'SOUL returned invalid startup location state.',
      );
    }

    await _cache.write(
      CachedTranslations(
        brandName: brandName,
        brandTranslate: brandTranslate,
        locale: locale,
        version: version,
        hash: hash,
        values: translations,
        direction: direction,
        supportedLanguages: supportedLanguages
            .map(
              (language) => <String, dynamic>{
                'code': language.code,
                'name': language.name,
                'native_name': language.nativeName,
                'direction': language.direction,
                'is_launch_target': language.isLaunchTarget,
                'is_launch_ready': language.isLaunchReady,
              },
            )
            .toList(growable: false),
      ),
    );

    return BootstrapState(
      brandName: brandName,
      brandTranslate: brandTranslate,
      direction: direction,
      locale: locale,
      translationVersion: version,
      translationHash: hash,
      translations: translations,
      legalVersions: versions is Map
          ? versions.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const <String, String>{},
      commitmentKeys: commitments is List
          ? commitments.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
      locationStatus: locationStatus!,
      capabilities: rawCapabilities is Map
          ? Map<String, dynamic>.from(rawCapabilities)
          : null,
      location: rawLocation is Map
          ? BootstrapLocation.fromJson(
              Map<String, dynamic>.from(rawLocation),
            )
          : null,
      supportedLanguages: supportedLanguages,
    );
  }

  BootstrapState _offlineState(CachedTranslations cached) => BootstrapState(
        brandName: cached.brandName,
        brandTranslate: cached.brandTranslate,
        direction: cached.direction,
        locale: cached.locale,
        translationVersion: cached.version,
        translationHash: cached.hash,
        translations: cached.values,
        legalVersions: const {},
        commitmentKeys: const [],
        supportedLanguages: _decodeSupportedLanguages(
          cached.supportedLanguages,
        ),
        locationStatus: 'unavailable',
        capabilities: null,
        location: null,
      );

  List<SupportedLanguage> _decodeSupportedLanguages(Object? raw) =>
      raw is List
          ? raw
              .whereType<Map>()
              .map(
                (item) => SupportedLanguage.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((item) => item.code.isNotEmpty)
              .toList(growable: false)
          : const <SupportedLanguage>[];
}
