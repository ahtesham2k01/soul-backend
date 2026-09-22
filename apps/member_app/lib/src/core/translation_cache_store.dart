import 'dart:convert';
import 'dart:io';

class CachedTranslations {
  const CachedTranslations({
    required this.locale,
    required this.version,
    required this.hash,
    required this.values,
    this.direction = 'ltr',
    this.supportedLanguages = const [],
  });

  final String locale;
  final String version;
  final String hash;
  final Map<String, String> values;
  final String direction;
  final List<Map<String, dynamic>> supportedLanguages;
}

class TranslationCacheStore {
  TranslationCacheStore({File? file})
      : _file = file ??
            File(
              [
                Directory.systemTemp.path,
                'soul_member_translation_cache.json',
              ].join(Platform.pathSeparator),
            );

  final File _file;

  Future<CachedTranslations?> read() async {
    if (!await _file.exists()) return null;

    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is! Map) return null;

      final map = Map<String, dynamic>.from(decoded);
      final locale = map['locale']?.toString() ?? '';
      final version = map['version']?.toString() ?? '';
      final hash = map['hash']?.toString() ?? '';
      final values = map['values'];
      final direction = map['direction']?.toString() ?? 'ltr';
      final rawLanguages = map['supported_languages'];

      if (locale.isEmpty ||
          version.isEmpty ||
          hash.length != 64 ||
          values is! Map) {
        return null;
      }

      return CachedTranslations(
        locale: locale,
        version: version,
        hash: hash,
        values: values.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
        direction: direction == 'rtl' ? 'rtl' : 'ltr',
        supportedLanguages: rawLanguages is List
            ? rawLanguages
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList(growable: false)
            : const <Map<String, dynamic>>[],
      );
    } on FormatException {
      await clear();
      return null;
    } on FileSystemException {
      return null;
    }
  }

  Future<void> write(CachedTranslations cache) async {
    final temporary = File('${_file.path}.tmp');

    try {
      await _file.parent.create(recursive: true);
      await temporary.writeAsString(
        jsonEncode({
          'locale': cache.locale,
          'version': cache.version,
          'hash': cache.hash,
          'values': cache.values,
          'direction': cache.direction,
          'supported_languages': cache.supportedLanguages,
        }),
        flush: true,
      );

      if (await _file.exists()) {
        await _file.delete();
      }

      await temporary.rename(_file.path);
    } on FileSystemException {
      try {
        if (await temporary.exists()) {
          await temporary.delete();
        }
      } on FileSystemException {
        // Translation caching is an optimization, never a startup dependency.
      }
    }
  }

  Future<void> clear() async {
    try {
      if (await _file.exists()) {
        await _file.delete();
      }
    } on FileSystemException {
      // Cache cleanup is best effort.
    }
  }
}
