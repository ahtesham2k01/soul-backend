import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/prototype/uploaded_onboarding/uploaded_welcome_screen.dart';

void main() {
  testWidgets('owner welcome preview stays within the requested visual scope', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: UploadedWelcomeScreen()),
    );
    await tester.pump();

    expect(find.byType(PageView), findsOneWidget);
    expect(find.bySemanticsLabel('Create Account'), findsOneWidget);
    expect(
      find.text('Already have an account? Continue with Email'),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Create Account'));
    await tester.pump();

    expect(find.byType(UploadedWelcomeScreen), findsOneWidget);
    expect(
      find.text(
        'Opening preview ends here — account flow is intentionally not included.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('welcome preview exposes all three owner-provided slides', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: UploadedWelcomeScreen()),
    );
    await tester.pump();

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.childrenDelegate.estimatedChildCount, 3);
  });
}
