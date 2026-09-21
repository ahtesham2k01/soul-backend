import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile surfaces use server translation keys for shared sections', () {
    final profile = File(
      'lib/src/features/profile/profile_screen.dart',
    ).readAsStringSync();
    final edit = File(
      'lib/src/features/profile/profile_edit_screen.dart',
    ).readAsStringSync();

    for (final key in [
      'profile.section_personality',
      'profile.section_background',
      'profile.section_lifestyle',
      'profile.section_future',
    ]) {
      expect(profile, contains(key));
      expect(edit, contains(key));
    }

    expect(profile, contains('profile.section_career'));
    expect(profile, contains('profile.membership_cta'));
    expect(profile, contains('profile.membership_cta_subtitle'));
  });

  test('private photo states use the backend member-copy catalog', () {
    final source = File(
      'lib/src/features/chat/private_photo_viewer_screen.dart',
    ).readAsStringSync();

    for (final key in [
      'private_photos.unable_to_load',
      'private_photos.request_sent',
      'private_photos.access_required',
      'private_photos.request_access',
      'private_photos.no_photos',
      'private_photos.recording_hidden',
      'private_photos.protected_notice',
    ]) {
      expect(source, contains(key));
    }
  });

  test('restricted account and safety forms reuse localized common copy', () {
    final account = File(
      'lib/src/features/profile/account_status_screen.dart',
    ).readAsStringSync();
    final safety = File(
      'lib/src/features/safety/safety_screen.dart',
    ).readAsStringSync();

    expect(account, contains('verification.appeal_hint'));
    expect(account, contains('verification.submit_appeal'));
    expect(account, contains('settings.deletion_scheduled'));
    expect(account, contains('auth.error.account_unavailable'));
    expect(safety, contains('common.optional_details'));
  });
}
