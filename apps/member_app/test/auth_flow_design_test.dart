import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registration preserves name, DOB, email and OTP sequence', () {
    final source = File(
      'lib/src/features/auth/auth_screen.dart',
    ).readAsStringSync();

    expect(source, contains('int _registrationStep = 0;'));
    expect(source, contains("if (_registrationStep == 0) return 'What should we call you?'"));
    expect(source, contains("return 'What’s your DOB ?';"));
    expect(source, contains("return 'What’s your email address?';"));
    expect(source, contains("if (_challenge != null) return 'Enter Your OTP';"));
    expect(source, contains("'first_name': _name.text.trim()"));
    expect(source, contains("'date_of_birth': dob"));
  });

  test('registration and onboarding use shared SOUL design primitives', () {
    final auth = File(
      'lib/src/features/auth/auth_screen.dart',
    ).readAsStringSync();
    final onboarding = File(
      'lib/src/features/onboarding/onboarding_screen.dart',
    ).readAsStringSync();

    for (final source in [auth, onboarding]) {
      expect(source, contains("core/soul_design.dart"));
      expect(source, contains('SoulStepScaffold('));
      expect(source, contains('SoulPrimaryButton('));
      expect(source, contains('SoulPageTitle('));
    }
  });
}
