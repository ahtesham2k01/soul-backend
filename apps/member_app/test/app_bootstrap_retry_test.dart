import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soul_member_app/src/app.dart';
import 'package:soul_member_app/src/app_providers.dart';
import 'package:soul_member_app/src/features/bootstrap/bootstrap_repository.dart';

void main() {
  const labels = BootstrapState(
    direction: 'ltr',
    locale: 'en',
    translations: {
      'error.bootstrap_unavailable': 'Startup temporarily unavailable.',
      'common.retry': 'Try again',
    },
    legalVersions: {},
    commitmentKeys: [],
    supportedLanguages: [],
  );

  testWidgets('startup retry reruns a failed session route', (tester) async {
    var sessionAttempts = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
