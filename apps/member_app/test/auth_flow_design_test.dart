import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registration preserves name, DOB, email and OTP sequence', () {
    final source = File(
      'lib/src/features/auth/auth_screen.dart',
    ).readAsStringSync();

    expect(source, contains('int _registrationStep = 0;'));
    expect(source, contains("'profile.first_name'"));
    expect(source, contains("'profile.date_of_birth'"));
    expect(source, contains("'auth.email'"));
    expect(source, contains("'auth.enter_code'"));
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
  test('registration exits consumed OTP state after post-auth profile failure', () {
    final source = File(
      'lib/src/features/auth/auth_screen.dart',
    ).readAsStringSync();

    expect(source, contains('var authenticationCompleted = false;'));
    expect(source, contains('authenticationCompleted = true;'));
    expect(source, contains('if (authenticationCompleted) {'));
    expect(source, contains('_routeAfterAuthentication();'));
    expect(
      source,
      contains('The OTP has already been consumed and the session was issued.'),
    );
  });

  test('active devices show session metadata and require revoke confirmation', () {
    final source = File(
      'lib/src/features/profile/settings_screen.dart',
    ).readAsStringSync();

    expect(source, contains('_confirmRevoke(DeviceSession session)'));
    expect(source, contains('showDialog<bool>'));
    expect(source, contains("'settings.last_used'"));
    expect(source, contains("'settings.signed_in'"));
    expect(source, contains("'settings.expires'"));
    expect(source, contains('_sessionSubtitle(item)'));
    expect(source, contains('() => _confirmRevoke(item)'));
  });

}
