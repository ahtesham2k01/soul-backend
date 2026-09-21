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
    expect(source, contains("case 'interests':"));
    expect(source, contains("case 'personality_traits':"));
    expect(source, contains("common.prefer_not_to_say"));
    expect(source, contains("common.skip"));
  });
}
