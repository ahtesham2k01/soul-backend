import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import '../safety/safety_repository.dart';
import '../safety/safety_screen.dart';
import 'discovery_filters_screen.dart';
import 'discovery_profile_screen.dart';
import 'discovery_repository.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({
    super.key,
    required this.repository,
    required this.safetyRepository,
    required this.labels,
  });

  final DiscoveryRepository repository;
  final SafetyRepository safetyRepository;
  final BootstrapState labels;

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  DiscoveryPreferences? _preferences;
  DiscoveryPrivacyState? _privacy;
  final List<DiscoveryCandidate> _candidates = [];
  String? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;
  bool _savingDecision = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object?>([
        widget.repository.preferences(),
        widget.repository.privacyState(),
      ]);
      final preferences = results[0] as DiscoveryPreferences?;
      final privacy = results[1] as DiscoveryPrivacyState;
      CandidatePage? page;
      if (preferences != null) {
        page = await widget.repository.candidates();
      }
      if (!mounted) return;
      setState(() {
        _preferences = preferences;
        _privacy = privacy;
        _candidates
          ..clear()
          ..addAll(page?.items ?? const []);
        _nextCursor = page?.nextCursor;
        _loading = false;
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (_loadingMore || cursor == null || cursor.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.repository.candidates(cursor: cursor);
      if (!mounted) return;
      setState(() {
        _candidates.addAll(page.items);
        _nextCursor = page.nextCursor;
        _loadingMore = false;
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _editFilters() async {
    final initial = _preferences;
    if (initial == null) {
      await _load();
      return;
    }

    final updated = await Navigator.of(context).push<DiscoveryPreferences>(
      MaterialPageRoute(
        builder: (_) => DiscoveryFiltersScreen(
          initial: initial,
          labels: widget.labels,
        ),
      ),
    );
    if (updated == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final saved = await widget.repository.savePreferences(updated);
      final page = await widget.repository.candidates();
      if (!mounted) return;
      setState(() {
        _preferences = saved;
        _candidates
          ..clear()
          ..addAll(page.items);
        _nextCursor = page.nextCursor;
        _loading = false;
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _decide(String decision) async {
    if (_savingDecision || _candidates.isEmpty) return;
    final candidate = _candidates.first;

    setState(() {
      _savingDecision = true;
      _error = null;
    });

    try {
      final result = await widget.repository.decide(candidate.id, decision);
      if (!mounted) return;
      setState(() {
        _candidates.removeAt(0);
        _savingDecision = false;
      });

      if (result.matched) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              widget.labels.text('matches.new_match', 'It is a match!'),
            ),
            content: Text('${candidate.firstName} and you liked each other.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(widget.labels.text('common.done', 'Done')),
              ),
            ],
          ),
        );
      } else if (decision == 'like' && mounted) {
        final controller = ScaffoldMessenger.of(context);
        controller.hideCurrentSnackBar();
        controller.showSnackBar(
          SnackBar(
            content: Text(
              widget.labels.format(
                'likes.sent',
                'Like sent to {name}.',
                {'name': candidate.firstName},
              ),
            ),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                try {
                  await widget.repository.withdrawLike(candidate.id);
                } on SoulApiFailure catch (failure) {
                  if (!mounted) return;
                  setState(() => _error = failure.message);
                }
              },
            ),
          ),
        );
      }

      if (_candidates.length < 4) {
        await _loadMore();
      }
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _savingDecision = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _openProfile(DiscoveryCandidate candidate) async {
    final blocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => DiscoveryProfileScreen(
          repository: widget.repository,
          safetyRepository: widget.safetyRepository,
          profileId: candidate.id,
          labels: widget.labels,
        ),
      ),
    );
    if (blocked == true && mounted) {
      setState(
        () => _candidates.removeWhere((item) => item.id == candidate.id),
      );
      if (_candidates.length < 4) await _loadMore();
    }
  }

  Future<void> _safety(DiscoveryCandidate candidate) async {
    final blocked = await showProfileSafetyActions(
      context: context,
      repository: widget.safetyRepository,
      profileId: candidate.id,
      profileName: candidate.firstName,
    );
    if (!blocked || !mounted) return;
    setState(() => _candidates.removeWhere((item) => item.id == candidate.id));
    if (_candidates.length < 4) await _loadMore();
  }

  String _maritalLabel(String value) =>
      widget.labels.text('profile.$value', value.replaceAll('_', ' '));

  String _intentionLabel(String value) => switch (value) {
        'marriage' => widget.labels.text(
            'profile.intention_marriage',
            'Marriage',
          ),
        'serious_relationship' => widget.labels.text(
            'profile.intention_serious',
            'Serious relationship',
          ),
        'casual_dating' => widget.labels.text(
            'profile.intention_casual',
            'Casual dating',
          ),
        _ => value.replaceAll('_', ' '),
      };

  String? _distanceLabel(String? key) {
    if (key == null || key.isEmpty) return null;
    return widget.labels.text(
      key,
      key.replaceAll('distance.', '').replaceAll('_', ' '),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: SoulColors.limeLight),
        ),
      );
    }

    if (_error != null && _preferences == null) {
      return _RetryState(message: _error!, onRetry: _load);
    }

    if (_preferences == null) {
      return _EmptyState(
        icon: Icons.tune_rounded,
        title: widget.labels.text('discovery.filters', 'Filters'),
        message: 'Choose who you would like to discover.',
        actionLabel: widget.labels.text('common.retry', 'Try again'),
        onAction: _load,
      );
    }

    final candidate = _candidates.isEmpty ? null : _candidates.first;
    if (candidate == null) {
      return _EmptyState(
        icon: Icons.favorite_border_rounded,
        title: widget.labels.text(
          'discovery.no_profiles',
          'No more profiles right now',
        ),
        message: 'Try adjusting your filters or check back later.',
        actionLabel: widget.labels.text('common.retry', 'Try again'),
        onAction: _load,
        secondaryLabel: widget.labels.text('discovery.filters', 'Filters'),
        onSecondary: _editFilters,
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CandidatePhoto(
            candidate: candidate,
            maritalLabel: _maritalLabel(candidate.maritalStatus),
            intentionLabels:
                candidate.intentions.map(_intentionLabel).toList(growable: false),
            distanceLabel: _distanceLabel(candidate.distanceBand),
          ),
          if (_privacy?.limitedVisibility == true)
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(82, 16, 82, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xcc111111),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    _privacy!.profilePaused
                        ? widget.labels.text(
                            'discovery.profile_paused',
                            'Profile paused',
                          )
                        : _privacy!.incognito
                            ? widget.labels.text(
                                'discovery.incognito_on',
                                'Incognito is on',
                              )
                            : widget.labels.text(
                                'discovery.visibility_off',
                                'Discovery visibility is off',
                              ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 18, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: FilledButton.icon(
                  onPressed: _editFilters,
                  style: FilledButton.styleFrom(
                    backgroundColor: SoulColors.limeLight,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 11,
                    ),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(
                    widget.labels.text('discovery.filters', 'Filters'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 18, 0),
              child: Align(
                alignment: Alignment.topRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircleAction(
                      icon: Icons.person_outline_rounded,
                      semanticLabel:
                          widget.labels.text('nav.profile', 'Profile'),
                      onPressed:
                          _savingDecision ? null : () => _openProfile(candidate),
                    ),
                    const SizedBox(height: 10),
                    _CircleAction(
                      icon: Icons.more_horiz_rounded,
                      semanticLabel: 'Safety options',
                      onPressed:
                          _savingDecision ? null : () => _safety(candidate),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 188,
            child: Column(
              children: [
                _CircleAction(
                  icon: Icons.favorite_border_rounded,
                  semanticLabel:
                      widget.labels.text('discovery.like', 'Like'),
                  iconColor: const Color(0xffef3340),
                  onPressed:
                      _savingDecision ? null : () => _decide('like'),
                ),
                const SizedBox(height: 12),
                _CircleAction(
                  icon: Icons.close_rounded,
                  semanticLabel:
                      widget.labels.text('discovery.pass', 'Pass'),
                  background: const Color(0x99000000),
                  iconColor: Colors.white,
                  onPressed:
                      _savingDecision ? null : () => _decide('pass'),
                ),
              ],
            ),
          ),
          if (_error != null)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(18, 72, 18, 0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xdd111111),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => _error = null),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_savingDecision)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: SoulColors.limeLight,
                backgroundColor: Colors.transparent,
              ),
            ),
          if (_loadingMore)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 98,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: SoulColors.limeLight,
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }
}

class _CandidatePhoto extends StatefulWidget {
  const _CandidatePhoto({
    required this.candidate,
    required this.maritalLabel,
    required this.intentionLabels,
    required this.distanceLabel,
  });

  final DiscoveryCandidate candidate;
  final String maritalLabel;
  final List<String> intentionLabels;
  final String? distanceLabel;

  @override
  State<_CandidatePhoto> createState() => _CandidatePhotoState();
}

class _CandidatePhotoState extends State<_CandidatePhoto> {
  int _photoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final candidate = widget.candidate;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (candidate.photos.isEmpty)
          const _PhotoFallback()
        else
          PageView.builder(
            itemCount: candidate.photos.length,
            onPageChanged: (index) => setState(() => _photoIndex = index),
            itemBuilder: (_, index) {
              final url = candidate.photos[index].url;
              if (url == null || url.isEmpty) return const _PhotoFallback();
              return Image.network(
                url,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const _PhotoFallback(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const _PhotoFallback(loading: true);
                },
              );
            },
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x66000000),
                Colors.transparent,
                Color(0x22000000),
                Color(0xdd000000),
              ],
              stops: [0, 0.25, 0.55, 1],
            ),
          ),
        ),
        if (candidate.photos.length > 1)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Row(
                  children: List.generate(
                    candidate.photos.length,
                    (index) => Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: index == _photoIndex
                              ? Colors.white
                              : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: 24,
          right: 86,
          bottom: 116,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${candidate.firstName}, ${candidate.age}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 9),
              if (candidate.city != null || widget.distanceLabel != null)
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        [
                          if (widget.distanceLabel != null)
                            widget.distanceLabel!,
                          if (candidate.city != null &&
                              candidate.city!.trim().isNotEmpty)
                            candidate.city!,
                        ].join(' · '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _InfoPill(text: widget.maritalLabel),
                  for (final intention in widget.intentionLabels)
                    _InfoPill(text: intention),
                  _InfoPill(text: candidate.country),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: const Color(0xff222222),
        child: Center(
          child: loading
              ? const CircularProgressIndicator(color: SoulColors.limeLight)
              : const Icon(
                  Icons.person_rounded,
                  size: 110,
                  color: Colors.white54,
                ),
        ),
      );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x66000000),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      );
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.background = Colors.white,
    this.iconColor = SoulColors.ink,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semanticLabel,
        child: Material(
          color: background,
          shape: const CircleBorder(),
          elevation: background == Colors.white ? 3 : 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(icon, color: iconColor, size: 29),
            ),
          ),
        ),
      );
}

class _RetryState extends StatelessWidget {
  const _RetryState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 30, 30, 120),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: SoulColors.limeLight,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Icon(icon, size: 46, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: SoulColors.limeLight,
                    foregroundColor: SoulColors.ink,
                  ),
                  child: Text(actionLabel),
                ),
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onSecondary,
                    child: Text(secondaryLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
