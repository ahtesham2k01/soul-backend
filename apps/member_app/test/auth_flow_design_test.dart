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

  test('OTP entry is digit-only, auto-submits and rate-limits resend', () {
    final source = File(
      'lib/src/features/auth/auth_screen.dart',
    ).readAsStringSync();

    expect(source, contains('FilteringTextInputFormatter.digitsOnly'));
    expect(source, contains('value.length == 6 && !_busy'));
    expect(source, contains('Timer.periodic(const Duration(seconds: 1)'));
    expect(source, contains('_resendSeconds = 30;'));
    expect(source, contains("const ValueKey('auth-resend-code')"));
    expect(source, contains('liveRegion: true'));
  });

  test('auth and onboarding fields support keyboard and autofill flow', () {
    final auth = File(
      'lib/src/features/auth/auth_screen.dart',
    ).readAsStringSync();
    final onboarding = File(
      'lib/src/features/onboarding/onboarding_screen.dart',
    ).readAsStringSync();
    final design = File(
      'lib/src/core/soul_design.dart',
    ).readAsStringSync();

    expect(auth, contains('AutofillHints.oneTimeCode'));
    expect(auth, contains('AutofillHints.birthday'));
    expect(auth, contains('onSubmitted:'));
    expect(onboarding, contains('AutofillHints.addressCity'));
    expect(onboarding, contains('TextInputAction.done'));
    expect(onboarding, contains('liveRegion: true'));
    expect(design, contains('FocusManager.instance.primaryFocus?.unfocus()'));
    expect(design, contains('resizeToAvoidBottomInset: true'));
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
    expect(source, contains("'auth.log_out'"));
    expect(source, contains("'common.revoke'"));
  });

}
