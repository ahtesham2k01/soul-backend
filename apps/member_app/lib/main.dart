import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/prototype/uploaded_onboarding/uploaded_onboarding_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const prototypeMode = bool.fromEnvironment(
    'SOUL_PROTOTYPE_MODE',
    defaultValue: false,
  );
  runApp(
    prototypeMode
        ? const SoulOnboardingPreviewApp()
        : const ProviderScope(child: SoulApp()),
  );
}
