import '../../core/api_client.dart';

class BootstrapState {
  const BootstrapState({
    required this.direction,
    required this.locale,
    required this.translations,
    required this.legalVersions,
    required this.commitmentKeys,
  });

  final String direction;
  final String locale;
  final Map<String, String> translations;
  final Map<String, String> legalVersions;
  final List<String> commitmentKeys;

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
    );
  }
}
