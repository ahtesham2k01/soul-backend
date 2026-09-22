
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/core/soul_theme.dart';
import 'package:soul_member_app/src/prototype/prototype_app.dart';
import 'package:soul_member_app/src/prototype/prototype_home.dart';
import 'package:soul_member_app/src/prototype/prototype_models.dart';

void main() {
  test('prototype matching stays local and creates a conversation', () {
    final controller = PrototypeController();
    final mutual = controller.profiles.firstWhere(
      (profile) => profile.mutualLike,
    );

    expect(controller.like(mutual), isTrue);
    expect(
      controller.conversations.any(
        (conversation) => conversation.profile.id == mutual.id,
      ),
      isTrue,
    );

    controller.dispose();
  });

  testWidgets('email prototype advances without a backend', (tester) async {
    final controller = PrototypeController()
      ..registration = true
      ..stage = PrototypeStage.auth;

    await tester.pumpWidget(
      MaterialApp(
        theme: soulTheme(),
        home: PrototypeEmailAuthScreen(controller: controller),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('prototype-email-field')),
      'preview@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('prototype-auth-continue')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('prototype-otp-field')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('prototype-otp-field')),
      '123456',
    );
    await tester.tap(find.byKey(const ValueKey('prototype-auth-continue')));
    await tester.pump();

    expect(controller.stage, PrototypeStage.onboarding);
    controller.dispose();
  });

  testWidgets('prototype home exposes the documented four primary tabs', (
    tester,
  ) async {
    final controller = PrototypeController()
      ..city = 'Preview City'
      ..stage = PrototypeStage.home;

    await tester.pumpWidget(
      MaterialApp(
        theme: soulTheme(),
        home: PrototypeMainShell(controller: controller),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Ayla, 27'), findsOneWidget);

    controller.dispose();
  });
}
