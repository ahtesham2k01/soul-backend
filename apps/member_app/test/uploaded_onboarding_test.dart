import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/prototype/uploaded_onboarding/uploaded_profile_onboarding.dart';

void main() {
  testWidgets('owner onboarding continues into required profile flow', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UploadedProfileOnboardingScreen(selectedLanguage: 'English'),
      ),
    );

    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('onboarding completion remains backend-free', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UploadedOnboardingCompleteScreen(
          name: 'Preview',
          city: 'Karachi',
          religion: 'Islam',
          selfieVerified: false,
        ),
      ),
    );

    expect(find.text('You’re ready, Preview'), findsOneWidget);
    expect(find.text('Skipped / optional'), findsOneWidget);
    expect(find.text('Review onboarding again'), findsOneWidget);
  });
}
