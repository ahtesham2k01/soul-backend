import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/features/launch/launch_screen.dart';

void main() {
  testWidgets('brand splash shows approved static first frame', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SoulBrandSplash()));

    expect(find.text('SOUL'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, soulSplashColor);
  });

  testWidgets('launch screen hands off after the minimum splash hold', (
    tester,
  ) async {
    var finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LaunchScreen(onFinished: () => finished = true),
      ),
    );

    await tester.pump(const Duration(milliseconds: 899));
    expect(finished, isFalse);

    await tester.pump(const Duration(milliseconds: 1));
    expect(finished, isTrue);
  });
}
