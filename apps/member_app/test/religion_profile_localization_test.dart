import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile religion path prefers localized API labels', () {
    final source = File(
      'lib/src/features/profile/profile_screen.dart',
    ).readAsStringSync();

    expect(source, contains("item['label']"));
    expect(source, contains("item['slug']"));
  });
}
