import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/prototype/uploaded_onboarding/uploaded_onboarding_app.dart';
import 'package:soul_member_app/src/prototype/uploaded_onboarding/uploaded_splash_screen.dart';
import 'package:soul_member_app/src/prototype/uploaded_onboarding/uploaded_welcome_screen.dart';

void main() {
  testWidgets('approved splash is exact, clean and spinner-free', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: UploadedSplashScreen()),
    );

    expect(find.byKey(const ValueKey('opening-splash')), findsOneWidget);
    expect(find.bySemanticsLabel('SOUL'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, soulLime);
    expect(soulLime, const Color(0xFFB3D63B));
  });

  testWidgets(
    'globe keeps avatars hidden until after spin and never invents location',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UploadedGlobeIntroScreen(
            copy: openingCopyFor('en'),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('opening-globe')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('opening-location-chip')),
        findsNothing,
      );

      final avatarBefore = tester.widget<Opacity>(
        find.byKey(const ValueKey('opening-avatar-0')),
      );
      expect(avatarBefore.opacity, 0);

      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 2300),
      );

      final avatarAfter = tester.widget<Opacity>(
        find.byKey(const ValueKey('opening-avatar-0')),
      );
      expect(avatarAfter.opacity, greaterThan(0));
    },
  );

  testWidgets('authoritative location is shown only when supplied', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UploadedGlobeIntroScreen(
          copy: openingCopyFor('en'),
          resolvedLocationLabel: 'Karachi, PK',
        ),
      ),
    );

    await tester.pump();
    await tester.pump(
      const Duration(milliseconds: 2600),
    );

    expect(find.text('Karachi, PK'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('opening-location-chip')),
      findsOneWidget,
    );
  });

  testWidgets('intro copy is real text and globe can be skipped', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UploadedGlobeIntroScreen(
          copy: openingCopyFor('en'),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('opening-globe')));
    await tester.pumpAndSettle();

    expect(find.byType(UploadedWelcomeScreen), findsOneWidget);
    expect(find.text('Swipe to Your'), findsOneWidget);
    expect(find.text('True Soul Match'), findsOneWidget);
  });

  testWidgets('Roman Urdu selection updates member-facing opening copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UploadedWelcomeScreen(initialLanguageCode: 'en'),
      ),
    );

    await tester.tap(find.byIcon(Icons.language_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roman Urdu').first);
    await tester.pumpAndSettle();

    expect(find.text('Swipe karke Apna'), findsOneWidget);
    expect(find.text('Sacha Soul Match Paayein'), findsOneWidget);
    expect(find.text('Account Banayein'), findsOneWidget);
    expect(find.text('Email se Login karein'), findsOneWidget);
  });

  testWidgets('welcome exposes all three slides and stays in opening scope', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: UploadedWelcomeScreen()),
    );
    await tester.pump();

    final pageView = tester.widget<PageView>(
      find.byKey(const ValueKey('opening-welcome-pages')),
    );
    expect(pageView.childrenDelegate.estimatedChildCount, 3);

    await tester.tap(find.byKey(const ValueKey('opening-create-account')));
    await tester.pump();

    expect(find.byType(UploadedWelcomeScreen), findsOneWidget);
    expect(
      find.text(
        'Opening preview ends here — account flow is intentionally not included.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('canonical welcome hands every entry action to production', (
    tester,
  ) async {
    var google = 0;
    var apple = 0;
    var create = 0;
    var login = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: UploadedWelcomeScreen(
          onGoogle: () => google++,
          onApple: () => apple++,
          onCreateAccount: () => create++,
          onEmailLogin: () => login++,
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Continue with Google'));
    await tester.tap(find.bySemanticsLabel('Continue with Apple'));
    await tester.tap(find.byKey(const ValueKey('opening-create-account')));
    await tester.tap(find.text('Continue with Email'));

    expect((google, apple, create, login), (1, 1, 1, 1));
    expect(find.textContaining('preview ends here'), findsNothing);
  });

  testWidgets('opening survives a small screen and large text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: UploadedWelcomeScreen(initialLanguageCode: 'en'),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('True Soul Match'), findsOneWidget);
    expect(find.byKey(const ValueKey('opening-create-account')), findsOneWidget);
  });

  testWidgets('reduced motion reaches a static premium globe state', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: UploadedGlobeIntroScreen(
          copy: openingCopyFor('en'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(OpeningMotion.reducedReveal);

    expect(find.text('Swipe to Your'), findsOneWidget);
    expect(find.text('Happily Ever After'), findsOneWidget);
  });

  testWidgets('preview app starts with the approved opening splash', (
    tester,
  ) async {
    await tester.pumpWidget(const SoulOnboardingPreviewApp());
    expect(find.byKey(const ValueKey('opening-splash')), findsOneWidget);
  });
}
