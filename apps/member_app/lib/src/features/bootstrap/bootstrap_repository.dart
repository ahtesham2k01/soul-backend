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
        code: json['code']?.toString().trim() ?? '',
        name: json['name']?.toString().trim() ?? '',
        nativeName: json['native_name']?.toString().trim() ?? '',
        direction: json['direction']?.toString() == 'rtl' ? 'rtl' : 'ltr',
        // Older cache files predate this flag. A missing value is therefore
        // treated as targeted, while an explicit false remains authoritative.
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
        city: json['city']?.toString().trim() ?? '',
        countryCode: json['country_code']?.toString().trim().toUpperCase() ?? '',
        country: json['country']?.toString(),
        region: json['region']?.toString(),
        isApproximate: json['is_approximate'] != false,
      );
}

class BootstrapState {
  const BootstrapState({
    this.brandName = 'SOUL',
    this.brandTranslate = false,
    this.requestedLocale,
    this.matchedLocale = '',
    this.fallbackLocale = 'en',
    required this.direction,
    required this.locale,
    this.translationVersion = '',
    this.translationHash = '',
    required this.translations,
    required this.legalVersions,
    required this.commitmentKeys,
    required this.supportedLanguages,
    this.legal = const <String, dynamic>{},
    this.locationStatus = 'unavailable',
    this.capabilities,
    this.location,
  });

  final String brandName;
  final bool brandTranslate;
  final String? requestedLocale;
  final String matchedLocale;
  final String fallbackLocale;
  final String direction;
  final String locale;
  final String translationVersion;
  final String translationHash;
  final Map<String, String> translations;
  final Map<String, String> legalVersions;
  final List<String> commitmentKeys;
  final List<SupportedLanguage> supportedLanguages;
  final Map<String, dynamic> legal;
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
    final requestedRaw = localeData['requested'];
    final requestedLocale = requestedRaw == null
        ? null
        : requestedRaw is String
            ? requestedRaw
            : null;
    final matchedLocale = localeData['matched']?.toString().trim() ?? '';
    final locale = localeData['resolved']?.toString().trim() ?? '';
    final fallbackLocale = localeData['fallback']?.toString().trim() ?? '';
    final rawDirection = localeData['direction']?.toString();
    final direction = rawDirection == 'rtl' ? 'rtl' : 'ltr';

    final translationData = data['translations'] is Map
        ? Map<String, dynamic>.from(data['translations'] as Map)
        : const <String, dynamic>{};
    final version = translationData['version']?.toString().trim() ?? '';
    final hash = translationData['hash']?.toString().toLowerCase() ?? '';
    final notModified = translationData['not_modified'] == true;
    final rawValues = translationData['values'];

    final supportedLanguages = _decodeSupportedLanguages(
      data['supported_languages'],
    );
    final languageCodes =
        supportedLanguages.map((language) => language.code).toList();

    if ((requestedRaw != null && requestedRaw is! String) ||
        matchedLocale.isEmpty ||
        locale.isEmpty ||
        fallbackLocale.isEmpty ||
        (rawDirection != 'ltr' && rawDirection != 'rtl') ||
        version.isEmpty ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
        supportedLanguages.isEmpty ||
        languageCodes.toSet().length != languageCodes.length ||
        supportedLanguages.any(
          (language) =>
              language.name.isEmpty ||
              language.nativeName.isEmpty,
        ) ||
        !languageCodes.contains(locale)) {
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
      if (rawValues != null) {
        throw const SoulApiFailure(
          statusCode: null,
          code: 'INVALID_BOOTSTRAP_TRANSLATIONS',
          message: 'SOUL returned an inconsistent language catalog.',
        );
      }
      translations = cached.values;
    } else if (!notModified &&
        rawValues is Map &&
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

    if (translations.isEmpty) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_BOOTSTRAP_TRANSLATIONS',
        message: 'SOUL returned an empty language catalog.',
      );
    }

    final legalData = data['legal'] is Map
        ? Map<String, dynamic>.from(data['legal'] as Map)
        : const <String, dynamic>{};
    final versions = legalData['versions'];
    final commitments = legalData['commitment_keys'];

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

    final legalVersions = Map<String, String>.from(versions);
    final commitmentKeys =
        List<String>.unmodifiable(commitments.cast<String>());

    final rawLocation = data['location'];
    final locationStatus = data['location_status']?.toString();

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
        (location.city.isEmpty ||
            !RegExp(r'^[A-Z]{2}$').hasMatch(location.countryCode))) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_BOOTSTRAP_LOCATION',
        message: 'SOUL returned incomplete startup location data.',
      );
    }

    final rawCapabilities = data['capabilities'];
    if (rawCapabilities != null && rawCapabilities is! Map) {
      throw const SoulApiFailure(
        statusCode: null,
        code: 'INVALID_BOOTSTRAP_CAPABILITIES',
        message: 'SOUL returned invalid capability configuration.',
      );
    }
    final capabilities = rawCapabilities is Map
        ? Map<String, dynamic>.from(rawCapabilities)
        : null;

    await _cache.write(
      CachedTranslations(
        brandName: brandName,
        brandTranslate: brandTranslate,
        locale: locale,
        fallbackLocale: fallbackLocale,
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
      requestedLocale: requestedLocale,
      matchedLocale: matchedLocale,
      fallbackLocale: fallbackLocale,
      direction: direction,
      locale: locale,
      translationVersion: version,
      translationHash: hash,
      translations: translations,
      legalVersions: legalVersions,
      commitmentKeys: commitmentKeys,
      legal: legalData,
      locationStatus: locationStatus!,
      capabilities: capabilities,
      location: location,
      supportedLanguages: supportedLanguages,
    );
  }

  BootstrapState _offlineState(CachedTranslations cached) => BootstrapState(
        brandName: cached.brandName,
        brandTranslate: cached.brandTranslate,
        matchedLocale: cached.locale,
        fallbackLocale: cached.fallbackLocale,
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
