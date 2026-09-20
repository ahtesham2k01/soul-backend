import '../../core/api_client.dart';

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

class BootstrapState {
  const BootstrapState({
    required this.direction,
    required this.locale,
    required this.translations,
    required this.legalVersions,
    required this.commitmentKeys,
    required this.supportedLanguages,
  });

  final String direction;
  final String locale;
  final Map<String, String> translations;
  final Map<String, String> legalVersions;
  final List<String> commitmentKeys;
  final List<SupportedLanguage> supportedLanguages;

  String text(String key, String fallback) => translations[key] ?? fallback;
}

class BootstrapRepository {
  BootstrapRepository(this._api);

  final SoulApiClient _api;

  Future<BootstrapState> load() async {
    final data = await _api.get('bootstrap');
    final localeData = data['locale'] is Map<String, dynamic>
        ? data['locale'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final translationData = data['translations'] is Map<String, dynamic>
        ? data['translations'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final values = translationData['values'];
    final legalData = data['legal'] is Map
        ? Map<String, dynamic>.from(data['legal'] as Map)
        : const <String, dynamic>{};
    final versions = legalData['versions'];
    final commitments = legalData['commitment_keys'];
    return BootstrapState(
      direction: localeData['direction']?.toString() ?? 'ltr',
      locale: localeData['resolved']?.toString() ?? 'en',
      translations: values is Map
          ? values.map((key, value) => MapEntry(key.toString(), value.toString()))
          : const <String, String>{},
      legalVersions: versions is Map
          ? versions.map((key, value) => MapEntry(key.toString(), value.toString()))
          : const <String, String>{},
      commitmentKeys: commitments is List
          ? commitments.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
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
