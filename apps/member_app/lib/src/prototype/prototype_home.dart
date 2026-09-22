// ignore_for_file: prefer_interpolation_to_compose_strings


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/soul_theme.dart';
import 'prototype_models.dart';
import 'prototype_profile.dart';

class PrototypeMainShell extends StatefulWidget {
  const PrototypeMainShell({
    required this.controller,
    super.key,
  });

  final PrototypeController controller;

  @override
  State<PrototypeMainShell> createState() => _PrototypeMainShellState();
}

class _PrototypeMainShellState extends State<PrototypeMainShell> {
  int index = 0;

  PrototypeController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_refresh);
  }

  @override
  void dispose() {
    c.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      PrototypeDiscoveryView(
        controller: c,
        onOpenChats: () => setState(() => index = 2),
      ),
      PrototypeLikesView(
        controller: c,
        onOpenChats: () => setState(() => index = 2),
      ),
      PrototypeChatListView(controller: c),
      PrototypeProfileView(controller: c),
    ];

    return Scaffold(
      backgroundColor: index == 0 ? SoulColors.forestDeep : Colors.white,
      extendBody: true,
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: index == 0
                ? const Color(0xee132308)
                : Colors.white.withValues(alpha: .96),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: index == 0 ? Colors.white24 : SoulColors.line,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .12),
                blurRadius: 24,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              _navItem(0, Icons.home_rounded, c.t('nav.home')),
              _navItem(1, Icons.favorite_rounded, c.t('nav.explore')),
              _navItem(2, Icons.chat_bubble_outline_rounded, c.t('nav.chat')),
              _navItem(3, Icons.person_outline_rounded, c.t('nav.profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int value, IconData icon, String label) {
    final selected = index == value;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => index = value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected ? SoulColors.limeLight : Colors.transparent,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 23,
                  color: selected
                      ? SoulColors.ink
                      : index == 0
                          ? Colors.white
                          : SoulColors.muted,
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: const TextStyle(
                        color: SoulColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PrototypeDiscoveryView extends StatefulWidget {
  const PrototypeDiscoveryView({
    required this.controller,
    required this.onOpenChats,
    super.key,
  });

  final PrototypeController controller;
  final VoidCallback onOpenChats;

  @override
  State<PrototypeDiscoveryView> createState() => _PrototypeDiscoveryViewState();
}

class _PrototypeDiscoveryViewState extends State<PrototypeDiscoveryView> {
  PrototypeController get c => widget.controller;
  double ageMax = 34;
  double distance = 50;
  String religionMode = 'My Religion';
  final Set<String> intentions = {'Marriage', 'Serious relationship'};

  @override
  void initState() {
    super.initState();
    c.addListener(_refresh);
  }

  @override
  void dispose() {
    c.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _like(PrototypeProfile profile) async {
    HapticFeedback.mediumImpact();
    final matched = c.like(profile);
    if (!matched || !mounted) return;
    await Future<void>.delayed(
      MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 120),
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MatchSheet(
        controller: c,
        profile: profile,
        onMessage: () {
          Navigator.of(context).pop();
          widget.onOpenChats();
        },
      ),
    );
  }

  void _pass(PrototypeProfile profile) {
    HapticFeedback.selectionClick();
    c.pass(profile);
  }

  Future<void> _showFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Discovery filters',
                    style: TextStyle(
                      color: SoulColors.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Keep filters useful. Over-filtering can shrink your pool too far.',
                    style: TextStyle(color: SoulColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Age · 22–' + ageMax.round().toString(),
                    style: const TextStyle(
                      color: SoulColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Slider(
                    value: ageMax,
                    min: 25,
                    max: 45,
                    divisions: 20,
                    onChanged: (value) =>
                        setSheetState(() => ageMax = value),
                  ),
                  Text(
                    'Distance · up to ' + distance.round().toString() + ' km',
                    style: const TextStyle(
                      color: SoulColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Slider(
                    value: distance,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    onChanged: (value) =>
                        setSheetState(() => distance = value),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Religion',
                    style: TextStyle(
                      color: SoulColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final item in const [
                        'My Religion',
                        'All Religions',
                      ])
                        PrototypePill(
                          item,
                          selected: religionMode == item,
                          onTap: () =>
                              setSheetState(() => religionMode = item),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Intentions',
                    style: TextStyle(
                      color: SoulColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in const [
                        'Marriage',
                        'Serious relationship',
                        'Casual dating',
                      ])
                        PrototypePill(
                          item,
                          selected: intentions.contains(item),
                          onTap: () => setSheetState(() {
                            if (!intentions.remove(item)) {
                              intentions.add(item);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: SoulColors.limeLight,
                        foregroundColor: SoulColors.ink,
                      ),
                      child: const Text(
                        'Apply filters',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = c.currentProfile;
    return Scaffold(
      backgroundColor: SoulColors.forestDeep,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      const Color(0xff355e11),
                      SoulColors.forestDeep,
                      const Color(0xff061200),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: Row(
                    children: [
                      const Text(
                        'SOUL',
                        style: TextStyle(
                          color: SoulColors.limeLight,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.7,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              c.city.isEmpty ? 'Nearby' : c.city,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Filters',
                        onPressed: _showFilters,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .1),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
                    child: profile == null
                        ? _DiscoveryEmpty(onReset: c.resetDiscovery)
                        : AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 280),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: .975, end: 1)
                                    .animate(animation),
                                child: child,
                              ),
                            ),
                            child: _DiscoveryCard(
                              key: ValueKey(profile.id),
                              profile: profile,
                              onPass: () => _pass(profile),
                              onLike: () => _like(profile),
                              onOpen: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        PrototypeProfileDetailScreen(
                                      controller: c,
                                      profile: profile,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({
    required this.profile,
    required this.onPass,
    required this.onLike,
    required this.onOpen,
    super.key,
  });

  final PrototypeProfile profile;
  final VoidCallback onPass;
  final VoidCallback onLike;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onOpen,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .3),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PrototypePortrait(
                  seed: profile.seed,
                  name: profile.name,
                  borderRadius: BorderRadius.circular(30),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x22000000),
                        Color(0xdd071102),
                      ],
                      stops: [0, .54, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  left: 18,
                  child: Row(
                    children: [
                      if (profile.verified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .9),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 15,
                                color: SoulColors.forest,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  color: SoulColors.ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name + ', ' + profile.age.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.7,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            profile.city +
                                ' · ' +
                                profile.distanceKm.toString() +
                                ' km',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          _DarkPill(profile.intention),
                          _DarkPill(profile.religion),
                          _DarkPill(profile.job),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _DecisionButton(
                            icon: Icons.close_rounded,
                            color: Colors.white,
                            foreground: SoulColors.ink,
                            onTap: onPass,
                          ),
                          const SizedBox(width: 18),
                          _DecisionButton(
                            icon: Icons.favorite_rounded,
                            color: SoulColors.limeLight,
                            foreground: SoulColors.ink,
                            big: true,
                            onTap: onLike,
                          ),
                          const SizedBox(width: 18),
                          _DecisionButton(
                            icon: Icons.more_horiz_rounded,
                            color: Colors.white.withValues(alpha: .18),
                            foreground: Colors.white,
                            onTap: onOpen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.icon,
    required this.color,
    required this.foreground,
    required this.onTap,
    this.big = false,
  });

  final IconData icon;
  final Color color;
  final Color foreground;
  final VoidCallback onTap;
  final bool big;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: big ? 64 : 54,
              height: big ? 64 : 54,
              child: Icon(
                icon,
                color: foreground,
                size: big ? 30 : 26,
              ),
            ),
          ),
        ),
      );
}

class _DarkPill extends StatelessWidget {
  const _DarkPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _DiscoveryEmpty extends StatelessWidget {
  const _DiscoveryEmpty({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.travel_explore_rounded,
                size: 50,
                color: SoulColors.limeLight,
              ),
              const SizedBox(height: 16),
              const Text(
                'You are all caught up',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try widening your distance or come back later for fresh profiles.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onReset,
                style: FilledButton.styleFrom(
                  backgroundColor: SoulColors.limeLight,
                  foregroundColor: SoulColors.ink,
                ),
                child: const Text('Review profiles again'),
              ),
            ],
          ),
        ),
      );
}

class _MatchSheet extends StatelessWidget {
  const _MatchSheet({
    required this.controller,
    required this.profile,
    required this.onMessage,
  });

  final PrototypeController controller;
  final PrototypeProfile profile;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          28,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: SoulColors.forestDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: SoulColors.limeLight,
              size: 40,
            ),
            const SizedBox(height: 12),
            const Text(
              'It is a match',
              style: TextStyle(
                color: Colors.white,
                fontSize: 29,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You and ' + profile.name + ' liked each other.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 86,
                  height: 104,
                  child: PrototypePortrait(
                    seed: 31,
                    name: controller.firstName.isEmpty
                        ? 'You'
                        : controller.firstName,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-8, 0),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: SoulColors.limeLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-16, 0),
                  child: SizedBox(
                    width: 86,
                    height: 104,
                    child: PrototypePortrait(
                      seed: profile.seed,
                      name: profile.name,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onMessage,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: SoulColors.limeLight,
                  foregroundColor: SoulColors.ink,
                ),
                child: const Text(
                  'Say hello',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Keep discovering',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
}

class PrototypeProfileDetailScreen extends StatelessWidget {
  const PrototypeProfileDetailScreen({
    required this.controller,
    required this.profile,
    super.key,
  });

  final PrototypeController controller;
  final PrototypeProfile profile;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 430,
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: SoulColors.ink,
              flexibleSpace: FlexibleSpaceBar(
                background: PrototypePortrait(
                  seed: profile.seed,
                  name: profile.name,
                  borderRadius: BorderRadius.zero,
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'block') {
                      controller.block(profile);
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Report submitted for review in this prototype.',
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'report', child: Text('Report')),
                    PopupMenuItem(value: 'block', child: Text('Block')),
                  ],
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.name + ', ' + profile.age.toString(),
                          style: const TextStyle(
                            color: SoulColors.ink,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (profile.verified)
                        const Icon(
                          Icons.verified_rounded,
                          color: SoulColors.forest,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile.city +
                        ' · ' +
                        profile.distanceKm.toString() +
                        ' km away',
                    style: const TextStyle(color: SoulColors.muted),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PrototypePill(
                        profile.intention,
                        icon: Icons.favorite_border_rounded,
                      ),
                      PrototypePill(
                        profile.religion,
                        icon: Icons.auto_awesome_outlined,
                      ),
                      PrototypePill(
                        profile.maritalStatus,
                        icon: Icons.person_outline_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _detailSection('About', profile.bio),
                  _detailSection(
                    'Work & education',
                    profile.job + ' · ' + profile.education,
                  ),
                  _detailSection(
                    'Lifestyle',
                    'Smoking: ' +
                        profile.smoking +
                        ' · Alcohol: ' +
                        profile.alcohol +
                        ' · ' +
                        profile.children,
                  ),
                  _detailSection('Height', profile.height),
                  _detailSection('Relocation', profile.relocation),
                  const SizedBox(height: 6),
                  const Text(
                    'Languages',
                    style: TextStyle(
                      color: SoulColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in profile.languages)
                        PrototypePill(item),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Interests',
                    style: TextStyle(
                      color: SoulColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in profile.interests)
                        PrototypePill(item),
                    ],
                  ),
                  if (profile.privatePhotos > 0) ...[
                    const SizedBox(height: 26),
                    PrototypeSectionCard(
                      color: SoulColors.softSurface,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: SoulColors.forest,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              profile.privatePhotos.toString() +
                                  ' private photo' +
                                  (profile.privatePhotos > 1 ? 's' : ''),
                              style: const TextStyle(
                                color: SoulColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Private-photo request sent to ' +
                                        profile.name +
                                        '.',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Request access'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      );

  Widget _detailSection(String title, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: SoulColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              text,
              style: const TextStyle(
                color: SoulColors.muted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
}

class PrototypeLikesView extends StatefulWidget {
  const PrototypeLikesView({
    required this.controller,
    required this.onOpenChats,
    super.key,
  });

  final PrototypeController controller;
  final VoidCallback onOpenChats;

  @override
  State<PrototypeLikesView> createState() => _PrototypeLikesViewState();
}

class _PrototypeLikesViewState extends State<PrototypeLikesView> {
  PrototypeController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_refresh);
  }

  @override
  void dispose() {
    c.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PrototypeHeader(
                  title: c.t('likes.title'),
                  subtitle:
                      'People who already noticed you. Accept to create a match.',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: SoulColors.limeLight,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      c.incomingLikes.length.toString(),
                      style: const TextStyle(
                        color: SoulColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: c.incomingLikes.isEmpty
                      ? const _LikesEmpty()
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: .69,
                          ),
                          itemCount: c.incomingLikes.length,
                          itemBuilder: (_, index) {
                            final profile = c.incomingLikes[index];
                            return _LikeCard(
                              profile: profile,
                              onDecline: () {
                                HapticFeedback.selectionClick();
                                c.declineIncoming(profile);
                              },
                              onAccept: () {
                                HapticFeedback.mediumImpact();
                                c.acceptIncoming(profile);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Matched with ' + profile.name + '.',
                                    ),
                                    action: SnackBarAction(
                                      label: 'Chat',
                                      onPressed: widget.onOpenChats,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _LikeCard extends StatelessWidget {
  const _LikeCard({
    required this.profile,
    required this.onDecline,
    required this.onAccept,
  });

  final PrototypeProfile profile;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PrototypePortrait(
              seed: profile.seed,
              name: profile.name,
              borderRadius: BorderRadius.circular(22),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xdd071102)],
                ),
              ),
            ),
            Positioned(
              left: 13,
              right: 13,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name + ', ' + profile.age.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: IconButton.filled(
                          onPressed: onDecline,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: SoulColors.ink,
                          ),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: IconButton.filled(
                          onPressed: onAccept,
                          style: IconButton.styleFrom(
                            backgroundColor: SoulColors.limeLight,
                            foregroundColor: SoulColors.ink,
                          ),
                          icon: const Icon(Icons.favorite_rounded),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _LikesEmpty extends StatelessWidget {
  const _LikesEmpty();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 58,
              color: SoulColors.muted,
            ),
            SizedBox(height: 14),
            Text(
              'No pending likes',
              style: TextStyle(
                color: SoulColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'New likes will appear here.',
              style: TextStyle(color: SoulColors.muted),
            ),
          ],
        ),
      );
}

class PrototypeChatListView extends StatefulWidget {
  const PrototypeChatListView({
    required this.controller,
    super.key,
  });

  final PrototypeController controller;

  @override
  State<PrototypeChatListView> createState() => _PrototypeChatListViewState();
}

class _PrototypeChatListViewState extends State<PrototypeChatListView> {
  PrototypeController get c => widget.controller;
  String query = '';

  @override
  void initState() {
    super.initState();
    c.addListener(_refresh);
  }

  @override
  void dispose() {
    c.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final visible = c.conversations
        .where(
          (conversation) => conversation.profile.name
              .toLowerCase()
              .contains(query.toLowerCase()),
        )
        .toList(growable: false);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          child: Column(
            children: [
              PrototypeHeader(
                title: c.t('chat.title'),
                subtitle: 'Good conversations start simple.',
              ),
              const SizedBox(height: 18),
              TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  hintText: 'Search conversations',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: visible.isEmpty
                    ? const _ChatEmpty()
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final conversation = visible[index];
                          final last = conversation.messages.isEmpty
                              ? 'You matched — say hello'
                              : conversation.messages.last.text;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            leading: Stack(
                              children: [
                                SizedBox(
                                  width: 54,
                                  height: 54,
                                  child: PrototypePortrait(
                                    seed: conversation.profile.seed,
                                    name: conversation.profile.name,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                if (conversation.online)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 13,
                                      height: 13,
                                      decoration: BoxDecoration(
                                        color: const Color(0xff46c56f),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              conversation.profile.name,
                              style: const TextStyle(
                                color: SoulColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(
                              last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: conversation.unread > 0
                                ? Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: SoulColors.limeLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      conversation.unread.toString(),
                                      style: const TextStyle(
                                        color: SoulColors.ink,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              conversation.unread = 0;
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => PrototypeChatThreadScreen(
                                    controller: c,
                                    conversation: conversation,
                                  ),
                                ),
                              );
                              setState(() {});
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrototypeChatThreadScreen extends StatefulWidget {
  const PrototypeChatThreadScreen({
    required this.controller,
    required this.conversation,
    super.key,
  });

  final PrototypeController controller;
  final PrototypeConversation conversation;

  @override
  State<PrototypeChatThreadScreen> createState() =>
      _PrototypeChatThreadScreenState();
}

class _PrototypeChatThreadScreenState
    extends State<PrototypeChatThreadScreen> {
  final TextEditingController input = TextEditingController();
  final ScrollController scroll = ScrollController();
  Timer? replyTimer;
  bool typing = false;
  bool safetyWarning = false;

  PrototypeController get c => widget.controller;
  PrototypeConversation get conversation => widget.conversation;

  @override
  void initState() {
    super.initState();
    c.addListener(_refresh);
  }

  @override
  void dispose() {
    replyTimer?.cancel();
    c.removeListener(_refresh);
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool _looksRisky(String value) {
    final text = value.toLowerCase();
    return text.contains('otp') ||
        text.contains('money') ||
        text.contains('bank') ||
        text.contains('whatsapp') ||
        text.contains('password');
  }

  void _send() {
    final value = input.text.trim();
    if (value.isEmpty) return;
    if (_looksRisky(value) && !safetyWarning) {
      HapticFeedback.mediumImpact();
      setState(() => safetyWarning = true);
      return;
    }
    HapticFeedback.selectionClick();
    c.sendMessage(conversation, value);
    input.clear();
    setState(() {
      safetyWarning = false;
      typing = true;
    });
    replyTimer?.cancel();
    replyTimer = Timer(const Duration(milliseconds: 950), () {
      if (!mounted) return;
      c.addAutoReply(conversation);
      setState(() => typing = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) {
          scroll.animateTo(
            scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfff8f9f6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          titleSpacing: 0,
          title: Row(
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: PrototypePortrait(
                  seed: conversation.profile.seed,
                  name: conversation.profile.name,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.profile.name,
                    style: const TextStyle(
                      color: SoulColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    conversation.online ? 'Online' : 'Recently active',
                    style: const TextStyle(
                      color: SoulColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'block') {
                  c.block(conversation.profile);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted.')),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'report', child: Text('Report')),
                PopupMenuItem(value: 'block', child: Text('Block')),
              ],
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              if (safetyWarning)
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xfffff5d8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffffdda0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Color(0xff7b5800),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Keep personal details, OTPs and money requests off-platform until you trust the person. This warning does not mean anyone has done something wrong.',
                          style: TextStyle(
                            color: Color(0xff6a4c00),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => safetyWarning = false),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
                  itemCount: conversation.messages.length + (typing ? 1 : 0),
                  itemBuilder: (_, index) {
                    if (index >= conversation.messages.length) {
                      return const _TypingBubble();
                    }
                    final message = conversation.messages[index];
                    return _MessageBubble(message: message);
                  },
                ),
              ),
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                  14,
                  10,
                  14,
                  10 + MediaQuery.paddingOf(context).bottom * .35,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: input,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Message ' + conversation.profile.name,
                          filled: true,
                          fillColor: SoulColors.softSurface,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: const BorderSide(
                              color: SoulColors.lime,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    IconButton.filled(
                      onPressed: _send,
                      style: IconButton.styleFrom(
                        backgroundColor: SoulColors.limeLight,
                        foregroundColor: SoulColors.ink,
                      ),
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final PrototypeMessage message;

  @override
  Widget build(BuildContext context) => Align(
        alignment: message.mine
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * .76,
          ),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: message.mine ? SoulColors.limeLight : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(message.mine ? 18 : 5),
              bottomRight: Radius.circular(message.mine ? 5 : 18),
            ),
            border: message.mine ? null : Border.all(color: SoulColors.line),
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              color: SoulColors.ink,
              height: 1.35,
            ),
          ),
        ),
      );
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) => const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 4),
              _TypingDot(),
              _TypingDot(),
              _TypingDot(),
            ],
          ),
        ),
      );
}

class _TypingDot extends StatelessWidget {
  const _TypingDot();

  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: const BoxDecoration(
          color: SoulColors.muted,
          shape: BoxShape.circle,
        ),
      );
}

class _ChatEmpty extends StatelessWidget {
  const _ChatEmpty();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 54,
              color: SoulColors.muted,
            ),
            SizedBox(height: 14),
            Text(
              'No conversations yet',
              style: TextStyle(
                color: SoulColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'When you match, your conversations will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SoulColors.muted),
            ),
          ],
        ),
      );
}
