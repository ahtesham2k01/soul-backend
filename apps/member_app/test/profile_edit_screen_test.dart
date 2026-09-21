import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile edit preserves and updates prefer-not-to-say states', () {
    final source = File(
      'lib/src/features/profile/profile_edit_screen.dart',
    ).readAsStringSync();

    expect(source, contains("p['prefer_not_to_say_fields']"));
    expect(source, contains("'prefer_not_to_say_fields':"));
    expect(source, contains('_withheldFields.remove(field)'));
    expect(source, contains('_withheldFields.add(field)'));
    expect(source, contains("if (field == 'interests')"));
    expect(source, contains("else if (field == 'personality_traits')"));
    expect(source, contains("common.prefer_not_to_say"));
    expect(source, contains("common.skip"));
  });
  test('profile edit protects all required V1 fields before save', () {
    final source = File(
      'lib/src/features/profile/profile_edit_screen.dart',
    ).readAsStringSync();
    final start = source.indexOf('String? _validate()');
    final end = source.indexOf('Map<String, Object?> _payload()', start);
    final validation = source.substring(start, end);

    expect(validation, contains('_city.text.trim().isEmpty'));
    expect(validation, contains("_nationality.text.trim()"));
    expect(validation, contains('_gender == null'));
    expect(validation, contains('_maritalStatus == null'));
    expect(validation, contains('_professionStatus == null'));
    expect(validation, contains('_smoking == null'));
    expect(validation, contains('_alcohol == null'));
    expect(validation, contains('_currentChildren == null'));
    expect(validation, contains('_futureChildren == null'));
    expect(validation, contains('_intentions.isEmpty'));
    expect(validation, contains('_languageCodes.isEmpty'));
  });
  test('profile edit source is not accidentally duplicated', () {
    final source = File(
      'lib/src/features/profile/profile_edit_screen.dart',
    ).readAsStringSync();

    expect(RegExp(r'class _ProfileEditScreenState').allMatches(source).length, 1);
    expect(RegExp(r'Future<void> _save').allMatches(source).length, 1);
    expect(RegExp(r'Map<String, Object\?> _payload\(\)').allMatches(source).length, 1);
    expect(source.split('\n').length, lessThan(1600));
  });


}
