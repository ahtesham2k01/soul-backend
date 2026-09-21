import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile completion mirrors V1 required readiness fields', () {
    final source = File(
      'lib/src/features/profile/profile_screen.dart',
    ).readAsStringSync();
    final start = source.indexOf('int get _completionPercent');
    final end = source.indexOf('bool _filled', start);
    final completion = source.substring(start, end);

    for (final field in [
      'first_name',
      'date_of_birth',
      'gender',
      'city_name',
      'country_code',
      'nationality_country_code',
      'marital_status',
      'intentions',
      'profession_status',
      'spoken_languages',
      'smoking',
      'alcohol',
      'current_children',
      'future_children',
    ]) {
      expect(completion, contains(field));
    }

    expect(completion, contains("religionPath is List"));
    expect(completion, contains("moderationStatus == 'approved'"));
    expect(completion, contains("visibility == 'public'"));
    expect(completion, contains('faceDetected == true'));
    expect(completion, isNot(contains("profile['bio']")));
  });
}
