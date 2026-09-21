import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('optional details expose every documented scalar profile field', () {
    final source = File(
      'lib/src/features/onboarding/optional_profile_details_screen.dart',
    ).readAsStringSync();

    for (final field in [
      'bio',
      'education',
      'height_cm',
      'job_title',
      'employer',
      'grew_up_in',
      'ethnic_origin',
      'religious_practice',
      'prayer',
      'diet',
      'dress',
      'relocation_preference',
      'family_involvement_preference',
    ]) {
      expect(source, contains("'$field'"));
    }
  });

  test('optional details preserve skip and prefer-not-to-say semantics', () {
    final source = File(
      'lib/src/features/onboarding/optional_profile_details_screen.dart',
    ).readAsStringSync();

    expect(source, contains("'prefer_not_to_say_fields': _withheld.toList()"));
    expect(source, contains('_withheld.remove(field)'));
    expect(source, contains('_withheld.add(field)'));
    expect(source, contains("'interests':"));
    expect(source, contains("'personality_traits':"));
    expect(source, contains('if (_interests.length > 15)'));
    expect(source, contains('if (_traits.length > 5)'));
  });

  test('completion keeps optional details non-blocking', () {
    final source = File(
      'lib/src/features/onboarding/onboarding_screen.dart',
    ).readAsStringSync();

    expect(source, contains('Add optional profile details'));
    expect(source, contains('_openOptionalDetails'));
    expect(source, contains('OptionalProfileDetailsScreen('));
  });
}
