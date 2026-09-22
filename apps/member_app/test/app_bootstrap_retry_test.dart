import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/app.dart';
import 'package:soul_member_app/src/app_providers.dart';
import 'package:soul_member_app/src/features/bootstrap/bootstrap_repository.dart';

void main() {
  const labels = BootstrapState(
    brandName: 'SOUL',
    direction: 'ltr',
    locale: 'en',
    translations: {
      'error.bootstrap_unavailable': 'Startup temporarily unavailable.',
      'common.retry': 'Try again',
      'onboarding.headline_highlight': 'Cached startup',
      'onboarding.headline_rest': 'Ready immediately',
    },
    legalVersions: {},
    commitmentKeys: [],
    supportedLanguages: [],
  );

  const refreshedLabels = BootstrapState(
    brandName: 'SOUL',
    direction: 'ltr',
    locale: 'en',
    translations: {
      'error.bootstrap_unavailable': 'Startup temporarily unavailable.',
      'common.retry': 'Try again',
      'onboarding.headline_highlight': 'Cached startup',
      'onboarding.headline_rest': 'Ready immediately',
    },
    legalVersions: {},
    commitmentKeys: [],
    supportedLanguages: [],
    locationStatus: 'resolved',
    location: BootstrapLocation(
      city: 'Karachi',
      countryCode: 'PK',
    ),
  );

  testWidgets('cached bootstrap renders while network refresh is still pending',
      (tester) async {
    final fresh = Completer<BootstrapState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapCacheProvider.overrideWith((ref) async => labels),
          bootstrapProvider.overrideWith((ref) => fresh.future),
          sessionRouteProvider.overrideWith((ref) async => 'auth'),
        ],
        child: const SoulApp(),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('SOUL'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(fresh.isCompleted, isFalse);

    fresh.complete(refreshedLabels);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Continue with Email'), findsOneWidget);
  });

  testWidgets('startup retry reruns a failed session route', (tester) async {
    var sessionAttempts = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapCacheProvider.overrideWith((ref) async => null),
          bootstrapProvider.overrideWith((ref) async => labels),
          sessionRouteProvider.overrideWith((ref) async {
            sessionAttempts++;
            if (sessionAttempts == 1) {
              throw Exception('temporary session route failure');
            }
            return 'auth';
          }),
        ],
        child: const SoulApp(),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Startup temporarily unavailable.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(sessionAttempts, 1);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(sessionAttempts, 2);
  });
}
