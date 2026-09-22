import '../../core/api_client.dart';
import '../../core/session_store.dart';

class SupportedLanguage {
  const SupportedLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.direction,
    required this.isLaunchReady,
  });

  final String code;
  final String name;
  final String nativeName;
  final String direction;
  final bool isLaunchReady;

  factory SupportedLanguage.fromJson(Map<String, dynamic> json) =>
      SupportedLanguage(
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        nativeName: json['native_name']?.toString() ?? '',
        direction: json['direction']?.toString() ?? 'ltr',
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
    required this.direction,
    required this.locale,
    this.translationVersion = '',
    this.translationHash = '',
    required this.translations,
    required this.legalVersions,
    required this.commitmentKeys,
    required this.supportedLanguages,
    this.location,
  });

  final String direction;
  final String locale;
  final String translationVersion;
  final String translationHash;
  final Map<String, String> translations;
  final Map<String, String> legalVersions;
  final List<String> commitmentKeys;
  final List<SupportedLanguage> supportedLanguages;
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
  BootstrapRepository(this._api, this._sessions);

  final SoulApiClient _api;
  final SessionStore _sessions;

  Future<BootstrapState> load() async {
    final cached = await _sessions.readTranslations();
    final data = await _api.get(
      'bootstrap',
      query: {
        if (cached != null) 'translations_hash': cached.hash,
      },
    );
    final localeData = data['locale'] is Map<String, dynamic>
        ? data['locale'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final translationData = data['translations'] is Map<String, dynamic>
        ? data['translations'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final locale = localeData['resolved']?.toString() ?? 'en';
    final version = translationData['version']?.toString() ?? '';
    final hash = translationData['hash']?.toString() ?? '';
    final notModified = translationData['not_modified'] == true;
    final rawValues = translationData['values'];

    Map<String, String> translations;
    if (notModified &&
        cached != null &&
        cached.locale == locale &&
        cached.hash == hash &&
        cached.version == version) {
      translations = cached.values;
    } else if (rawValues is Map) {
      translations = rawValues.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );

      if (hash.length == 64 && version.isNotEmpty) {
        await _sessions.saveTranslations(
          CachedTranslations(
            locale: locale,
            version: version,
            hash: hash,
            values: translations,
          ),
        );
      }
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
    return BootstrapState(
      direction: localeData['direction']?.toString() ?? 'ltr',
      locale: locale,
      translationVersion: version,
      translationHash: hash,
      translations: translations,
      legalVersions: versions is Map
          ? versions.map((key, value) => MapEntry(key.toString(), value.toString()))
          : const <String, String>{},
      commitmentKeys: commitments is List
          ? commitments.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
      location: rawLocation is Map
          ? BootstrapLocation.fromJson(
              Map<String, dynamic>.from(rawLocation),
            )
          : null,
      supportedLanguages: data['supported_languages'] is List
          ? (data['supported_languages'] as List)
              .whereType<Map>()
              .map((item) => SupportedLanguage.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((item) => item.code.isNotEmpty)
              .toList(growable: false)
          : const <SupportedLanguage>[],
    );
  }
}
