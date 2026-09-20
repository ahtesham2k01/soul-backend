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
      ReceivedLikesScreen(
        repository: discovery,
        labels: labels,
        onStartDiscovering: () => setState(() => _index = 0),
      ),
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
      extendBody: true,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _SoulBottomBar(
        selectedIndex: _index,
        dark: _index == 0,
        labels: [
          labels.text('nav.home', 'Home'),
          labels.text('nav.explore', 'Explore'),
          labels.text('nav.chat', 'Chat'),
          labels.text('nav.profile', 'Profile'),
        ],
        onSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _SoulBottomBar extends StatelessWidget {
  const _SoulBottomBar({
    required this.selectedIndex,
    required this.dark,
    required this.labels,
    required this.onSelected,
  });

  final int selectedIndex;
  final bool dark;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  static const _icons = <IconData>[
    Icons.home_rounded,
    Icons.favorite_rounded,
    Icons.chat_bubble_outline_rounded,
    Icons.person_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 10),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: dark ? const Color(0xaa1c1c1c) : Colors.white,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: dark ? Colors.white24 : SoulColors.line,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(dark ? 0.16 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                _icons.length,
                (index) => _BottomBarItem(
                  icon: _icons[index],
                  label: labels[index],
                  selected: index == selectedIndex,
                  dark: dark,
                  onTap: () => onSelected(index),
                ),
              ),
            ),
          ),
        ),
      );
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Material(
            color: selected
                ? SoulColors.limeLight
                : dark
                    ? const Color(0x22ffffff)
                    : Colors.white,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 104 : 52,
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: selected
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 23,
                            color: SoulColors.ink,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: const TextStyle(
                                color: SoulColors.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Icon(
                        icon,
                        size: 25,
                        color: dark ? Colors.white : SoulColors.ink,
                      ),
              ),
            ),
          ),
        ),
      );
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
