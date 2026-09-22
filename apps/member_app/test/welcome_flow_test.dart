import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/features/bootstrap/bootstrap_repository.dart';
import 'package:soul_member_app/src/features/onboarding/welcome_flow.dart';

void main() {
  const labels = BootstrapState(
    direction: 'ltr',
    locale: 'en',
    translations: {
      'auth.continue_with_google': 'Continue with Google',
      'auth.continue_with_apple': 'Continue with Apple',
      'auth.create_account': 'Create Account',
      'auth.continue_with_email': 'Continue with Email',
      'auth.already_have_account': 'Already have an account?',
      'auth.log_in': 'Log in',
      'onboarding.headline_highlight': 'Swipe to Your',
      'onboarding.headline_rest': 'Happily Ever After',
      'onboarding.subtitle':
          'Start your journey to meaningful connections and lasting relationships today',
      'language.select': 'Select language',
    },
    legalVersions: {},
    commitmentKeys: [],
    supportedLanguages: [
      SupportedLanguage(
        code: 'en',
        name: 'English',
        nativeName: 'English',
        direction: 'ltr',
        isLaunchReady: true,
      ),
      SupportedLanguage(
        code: 'ur',
        name: 'Urdu',
        nativeName: 'Roman Urdu',
        direction: 'ltr',
        isLaunchReady: true,
      ),
    ],
  );

  Future<void> pumpWelcome(
    WidgetTester tester,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WelcomeFlow(labels: labels),
        ),
      ),
    );
    await tester.pump();
  }

  for (final size in const [Size(360, 640), Size(412, 915)]) {
    testWidgets(
      'welcome composition remains separated at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await pumpWelcome(tester, size);

        final headline = find.text('Happily Ever After');
        final create = find.text('Create Account');
        final email = find.text('Continue with Email');

        expect(headline, findsOneWidget);
        expect(create, findsOneWidget);
        expect(email, findsOneWidget);
        expect(
          find.bySemanticsLabel('Continue with Google'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Continue with Apple'),
          findsOneWidget,
        );

        final headlineRect = tester.getRect(headline);
        final createRect = tester.getRect(create);
        expect(headlineRect.bottom, lessThan(createRect.top));

        expect(tester.takeException(), isNull);
      },
    );
  }
}
