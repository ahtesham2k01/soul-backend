import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';
import 'core/soul_theme.dart';
import 'features/launch/launch_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/welcome_flow.dart';

class SoulApp extends ConsumerStatefulWidget {
  const SoulApp({super.key});

  @override
  ConsumerState<SoulApp> createState() => _SoulAppState();
}

class _SoulAppState extends ConsumerState<SoulApp> {
  bool _launchFinished = false;

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(bootstrapProvider);
    final sessionRoute = ref.watch(sessionRouteProvider);
    return bootstrap.when(
      data: (state) => MaterialApp(
        title: 'SOUL',
        debugShowCheckedModeBanner: false,
        theme: soulTheme(),
        home: Directionality(
          textDirection: state.direction == 'rtl'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: sessionRoute.when(
            data: (route) {
              if (!_launchFinished) {
                return LaunchScreen(
                  onFinished: () => setState(() => _launchFinished = true),
                );
              }
              if (route == 'auth') return WelcomeFlow(labels: state);
              if (route == 'onboarding') return OnboardingScreen(labels: state);
              return const _SignedInShell();
            },
            error: (_, __) => const _BootstrapErrorScreen(),
            loading: () => const _LaunchScreen(),
          ),
        ),
      ),
      error: (_, __) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _BootstrapErrorScreen(),
      ),
      loading: () => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _LaunchScreen(),
      ),
    );
  }
}

class _LaunchScreen extends StatelessWidget {
  const _LaunchScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Text('SOUL', style: TextStyle(fontSize: 36)), SizedBox(height: 20), CircularProgressIndicator()],
          ),
        ),
      );
}

class _BootstrapErrorScreen extends ConsumerWidget {
  const _BootstrapErrorScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('SOUL', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 16),
                const Text('Unable to load SOUL right now.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(bootstrapProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SignedInShell extends StatelessWidget {
  const _SignedInShell();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('SOUL')),
        body: const Center(child: Text('Your SOUL home will appear here.')),
      );
}
