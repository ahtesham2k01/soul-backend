import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('signed-in launch never requests notification permission by itself', () {
    final source = File(
      'lib/src/core/push_registration_service.dart',
    ).readAsStringSync();

    final synchronizeStart = source.indexOf('Future<void> synchronize()');
    final explicitStart =
        source.indexOf('Future<bool> requestPermissionAndSynchronize()');

    expect(synchronizeStart, greaterThanOrEqualTo(0));
    expect(explicitStart, greaterThan(synchronizeStart));

    final synchronizeBody =
        source.substring(synchronizeStart, explicitStart);
    expect(
      synchronizeBody,
      contains('getNotificationSettings()'),
    );
    expect(
      synchronizeBody,
      isNot(contains('requestPermission(')),
    );
  });

  test('onboarding offers Allow and Not now before legal submission', () {
    final notification = File(
      'lib/src/features/onboarding/notification_permission_screen.dart',
    ).readAsStringSync();
    final onboarding = File(
      'lib/src/features/onboarding/onboarding_screen.dart',
    ).readAsStringSync();

    expect(
      notification,
      contains("'notifications.allow'"),
    );
    expect(
      notification,
      contains("'common.not_now'"),
    );
    expect(
      notification,
      contains('requestPermissionAndSynchronize()'),
    );

    final prompt = onboarding.indexOf('NotificationPermissionScreen(');
    final legal = onboarding.indexOf('LegalSubmissionScreen(');
    expect(prompt, greaterThanOrEqualTo(0));
    expect(legal, greaterThan(prompt));
  });
}
