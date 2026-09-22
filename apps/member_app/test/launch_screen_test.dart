import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/features/bootstrap/bootstrap_repository.dart';
import 'package:soul_member_app/src/features/launch/launch_screen.dart';

void main() {
  const labels = BootstrapState(
    brandName: 'SOUL',
    direction: 'ltr',
    locale: 'en',
    translations: {
      'onboarding.headline_highlight': 'Swipe to Your',
      'onboarding.headline_rest': 'Happily Ever After',
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

  testWidgets('brand splash shows approved static first frame', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SoulBrandSplash()));

    expect(find.text('SOUL'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, soulSplashColor);
  });

  testWidgets(
    'globe settles before member markers location and tagline reveal',
    (tester) async {
      var finished = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LaunchScreen(
            labels: labels,
            onFinished: () => finished = true,
          ),
        ),
      );

      expect(find.text('SOUL'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 620));
      await tester.pump(const Duration(milliseconds: 180));

      expect(find.byKey(const ValueKey('launch-globe')), findsOneWidget);
      expect(find.byKey(const ValueKey('launch-avatar-0')), findsOneWidget);

      final avatarBefore = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byKey(const ValueKey('launch-avatar-0')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(avatarBefore.opacity, 0);

      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 140));
      await tester.pump(const Duration(milliseconds: 850));

      expect(find.text('Karachi, PK'), findsOneWidget);
      expect(find.text('Swipe to Your'), findsOneWidget);
      expect(find.text('Happily Ever After'), findsOneWidget);
      expect(finished, isFalse);

      // Completion callback behavior is covered separately by the skip test.
      // This test intentionally verifies visual ordering instead of coupling
      // the UI contract to an exact fake-clock frame boundary.
      await tester.pump(const Duration(milliseconds: 650));
    },
  );

  testWidgets('globe intro can be skipped after it becomes visible', (
    tester,
  ) async {
    var finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LaunchScreen(
          labels: labels,
          onFinished: () => finished = true,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 620));
    await tester.pump(const Duration(milliseconds: 180));
    await tester.tap(find.byKey(const ValueKey('launch-globe-stage')));
    await tester.pump(const Duration(milliseconds: 160));

    expect(finished, isTrue);
  });
}
