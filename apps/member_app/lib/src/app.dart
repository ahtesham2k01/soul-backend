import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';
import 'core/soul_theme.dart';
import 'features/bootstrap/bootstrap_repository.dart';
import 'features/discovery/discovery_screen.dart';
import 'features/launch/launch_screen.dart';
import 'features/likes/received_likes_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/legal_submission_screen.dart';
import 'features/onboarding/onboarding_repository.dart';
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
              if (route == 'legal') {
                return LegalReconsentScreen(
                  repository: OnboardingRepository(ref.read(apiClientProvider)),
                  labels: state,
                  onAccepted: () => ref.invalidate(sessionRouteProvider),
                );
              }
              return _SignedInShell(labels: state);
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

class _SignedInShell extends ConsumerStatefulWidget {
  const _SignedInShell({required this.labels});

  final BootstrapState labels;

  @override
  ConsumerState<_SignedInShell> createState() => _SignedInShellState();
}

class _SignedInShellState extends ConsumerState<_SignedInShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final discovery = ref.watch(discoveryRepositoryProvider);
    final pages = <Widget>[
      DiscoveryScreen(repository: discovery, labels: labels),
      ReceivedLikesScreen(repository: discovery, labels: labels),
      _ComingSoon(
        icon: Icons.chat_bubble_outline_rounded,
        title: labels.text('nav.chat', 'Chat'),
      ),
      _ComingSoon(
        icon: Icons.person_outline_rounded,
        title: labels.text('nav.profile', 'Profile'),
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.favorite_outline_rounded),
            selectedIcon: const Icon(Icons.favorite_rounded),
            label: labels.text('nav.home', 'Home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome_rounded),
            label: labels.text('nav.explore', 'Explore'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: const Icon(Icons.chat_bubble_rounded),
            label: labels.text('nav.chat', 'Chat'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: labels.text('nav.profile', 'Profile'),
          ),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      );
}
