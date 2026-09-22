import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CachedTranslations {
  const CachedTranslations({
    this.brandName = 'SOUL',
    this.brandTranslate = false,
    required this.locale,
    required this.version,
    required this.hash,
    required this.values,
    this.direction = 'ltr',
    this.supportedLanguages = const [],
  });

  final String brandName;
  final bool brandTranslate;
  final String locale;
  final String version;
  final String hash;
  final Map<String, String> values;
  final String direction;
  final List<Map<String, dynamic>> supportedLanguages;
}

class TranslationCacheStore {
  TranslationCacheStore({File? file}) : _file = file;

  final File? _file;

  Future<File> _resolvedFile() async {
    final injected = _file;
    if (injected != null) return injected;

    final directory = await getApplicationSupportDirectory();
    return File(
      [
        directory.path,
        'soul_member_translation_cache.json',
      ].join(Platform.pathSeparator),
    );
  }

  Future<CachedTranslations?> read() async {
    try {
      final file = await _resolvedFile();
      if (!await file.exists()) return null;

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        await clear();
        return null;
      }

      final map = Map<String, dynamic>.from(decoded);
      final brandName = map['brand_name']?.toString().trim() ?? 'SOUL';
      final brandTranslate = map['brand_translate'] == true;
      final locale = map['locale']?.toString() ?? '';
      final version = map['version']?.toString() ?? '';
      final hash = map['hash']?.toString().toLowerCase() ?? '';
      final values = map['values'];
      final direction = map['direction']?.toString() ?? 'ltr';
      final rawLanguages = map['supported_languages'];

      final validValues = values is Map &&
          values.entries.every(
            (entry) => entry.key is String && entry.value is String,
          );

      if (brandName != 'SOUL' ||
          brandTranslate ||
          locale.isEmpty ||
          version.isEmpty ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
          !validValues) {
        await clear();
        return null;
      }

      return CachedTranslations(
        brandName: brandName,
        brandTranslate: brandTranslate,
        locale: locale,
        version: version,
        hash: hash,
        values: Map<String, String>.from(values as Map),
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
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> write(CachedTranslations cache) async {
    File? temporary;

    try {
      final file = await _resolvedFile();
      temporary = File('${file.path}.tmp');

      await file.parent.create(recursive: true);
      await temporary.writeAsString(
        jsonEncode({
          'brand_name': cache.brandName,
          'brand_translate': cache.brandTranslate,
          'locale': cache.locale,
          'version': cache.version,
          'hash': cache.hash,
          'values': cache.values,
          'direction': cache.direction,
          'supported_languages': cache.supportedLanguages,
        }),
        flush: true,
      );

      if (await file.exists()) {
        await file.delete();
      }

      await temporary.rename(file.path);
    } catch (_) {
      try {
        if (temporary != null && await temporary.exists()) {
          await temporary.delete();
        }
      } catch (_) {
        // Translation caching is an optimization, never a startup dependency.
      }
    }
  }

  Future<void> clear() async {
    try {
      final file = await _resolvedFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Cache cleanup is best effort.
    }
  }
}
