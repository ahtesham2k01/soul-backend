import '../../core/api_client.dart';

class BootstrapState {
  const BootstrapState({
    required this.direction,
    required this.locale,
    required this.translations,
  });

  final String direction;
  final String locale;
  final Map<String, String> translations;

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
    return BootstrapState(
      direction: localeData['direction']?.toString() ?? 'ltr',
      locale: localeData['resolved']?.toString() ?? 'en',
      translations: values is Map
          ? values.map((key, value) => MapEntry(key.toString(), value.toString()))
          : const <String, String>{},
    );
  }
}
