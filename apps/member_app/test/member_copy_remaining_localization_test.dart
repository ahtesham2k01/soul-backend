import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remaining shared member copy uses Laravel translation keys', () {
    final notifications = File(
      'lib/src/features/profile/notification_center_screen.dart',
    ).readAsStringSync();
    final edit = File(
      'lib/src/features/profile/profile_edit_screen.dart',
    ).readAsStringSync();
    final settings = File(
      'lib/src/features/profile/settings_screen.dart',
    ).readAsStringSync();
    final safety = File(
      'lib/src/features/safety/safety_screen.dart',
    ).readAsStringSync();

    expect(notifications, contains("'notifications.title'"));
    expect(notifications, contains("'notifications.empty'"));
    expect(edit, contains("'profile.discard_changes'"));
    expect(edit, contains("'common.discard'"));
    expect(settings, contains("'notifications.default_subtitle'"));
    expect(settings, contains("'notifications.safety'"));

    for (final key in [
      'safety.reason.fake_profile',
      'safety.reason.scam',
      'safety.reason.harassment',
      'safety.reason.sexual_content',
      'safety.reason.underage',
      'safety.reason.false_marital_status',
      'safety.block_too',
    ]) {
      expect(safety, contains(key));
    }
  });
}
