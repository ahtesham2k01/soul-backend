import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import '../safety/safety_repository.dart';
import '../safety/safety_screen.dart';
import 'discovery_repository.dart';

class DiscoveryProfileScreen extends StatefulWidget {
  const DiscoveryProfileScreen({
    required this.repository,
    required this.safetyRepository,
    required this.profileId,
    required this.labels,
    super.key,
  });

  final DiscoveryRepository repository;
  final SafetyRepository safetyRepository;
  final String profileId;
  final BootstrapState labels;

  @override
  State<DiscoveryProfileScreen> createState() => _DiscoveryProfileScreenState();
}

class _DiscoveryProfileScreenState extends State<DiscoveryProfileScreen> {
  DiscoveryProfile? _profile;
  bool _loading = true;
  String? _error;
  int _photoIndex = 0;

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
      final profile = await widget.repository.profile(widget.profileId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
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
        _ => widget.labels.text('common.not_available', 'Not available'),
      };

  Future<void> _safety() async {
    final profile = _profile;
    if (profile == null) return;
    final blocked = await showProfileSafetyActions(
      context: context,
      repository: widget.safetyRepository,
      labels: widget.labels,
      profileId: profile.id,
      profileName: profile.firstName,
    );
    if (blocked && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final profile = _profile;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(labels.text('nav.profile', 'Profile')),
        actions: [
          IconButton(
            onPressed: profile == null ? null : _safety,
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? _ErrorState(
                  message: _error ??
                       labels.text(
                         'discovery.profile_unavailable',
                         'Profile unavailable.',
                       ),
                  retryLabel: labels.text('common.retry', 'Try again'),
                  onRetry: _load,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 36),
                    children: [
                      _PhotoGallery(
                        profile: profile,
                        photoIndex: _photoIndex,
                        onPhotoChanged: (index) =>
                            setState(() => _photoIndex = index),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${profile.firstName}, ${profile.age}',
                              style: const TextStyle(
                                color: SoulColors.ink,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _Pill(
                                  label: _maritalLabel(
                                    profile.maritalStatus,
                                  ),
                                ),
                                for (final intention in profile.intentions)
                                  _Pill(
                                    label: _intentionLabel(intention),
                                  ),
                              ],
                            ),
                            if (profile.city?.trim().isNotEmpty == true ||
                                profile.country.trim().isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: SoulColors.muted,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      [
                                        if (profile.city?.trim().isNotEmpty ==
                                            true)
                                          profile.city!.trim(),
                                        if (profile.country.trim().isNotEmpty)
                                          profile.country.trim(),
                                      ].join(', '),
                                      style: const TextStyle(
                                        color: SoulColors.muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (profile.bio?.trim().isNotEmpty == true)
                              _Section(
                                title: labels.text(
                                  'profile.bio',
                                  'About you',
                                ),
                                body: profile.bio!.trim(),
                              ),
                            _DetailGrid(
                              labels: labels,
                              profile: profile,
                            ),
                            if (profile.interests.isNotEmpty)
                              _ChipSection(
                                title: labels.text(
                                  'profile.interests',
                                  'Interests',
                                ),
                                values: profile.interests,
                              ),
                            if (profile.personalityTraits.isNotEmpty)
                              _ChipSection(
                                title: labels.text(
                                  'profile.traits',
                                  'Personality traits',
                                ),
                                values: profile.personalityTraits,
                              ),
                            if (profile.spokenLanguages.isNotEmpty)
                              _ChipSection(
                                title: labels.text(
                                  'profile.languages',
                                  'Languages you speak',
                                ),
                                values: profile.spokenLanguages,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({
    required this.profile,
    required this.photoIndex,
    required this.onPhotoChanged,
  });

  final DiscoveryProfile profile;
  final int photoIndex;
  final ValueChanged<int> onPhotoChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .54,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (profile.photos.isEmpty)
              const ColoredBox(
                color: SoulColors.softSurface,
                child: Icon(
                  Icons.person_rounded,
                  size: 110,
                  color: SoulColors.muted,
                ),
              )
            else
              PageView.builder(
                itemCount: profile.photos.length,
                onPageChanged: onPhotoChanged,
                itemBuilder: (_, index) {
                  final url = profile.photos[index].url;
                  if (url == null || url.isEmpty) {
                    return const ColoredBox(
                      color: SoulColors.softSurface,
                      child: Icon(
                        Icons.person_rounded,
                        size: 110,
                        color: SoulColors.muted,
                      ),
                    );
                  }
                  return Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: SoulColors.softSurface,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: SoulColors.muted,
                      ),
                    ),
                  );
                },
              ),
            if (profile.photos.length > 1)
              Positioned(
                left: 16,
                right: 16,
                top: 14,
                child: Row(
                  children: List.generate(
                    profile.photos.length,
                    (index) => Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: index == photoIndex
                              ? Colors.white
                              : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({
    required this.labels,
    required this.profile,
  });

  final BootstrapState labels;
  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context) {
    final details = <(String, String)>[
      if (profile.jobTitle?.trim().isNotEmpty == true)
        (
          labels.text('profile.job_title', 'Job title'),
          profile.jobTitle!.trim(),
        ),
      if (profile.employer?.trim().isNotEmpty == true)
        (
          labels.text('profile.employer', 'Employer'),
          profile.employer!.trim(),
        ),
      if (profile.education?.trim().isNotEmpty == true)
        (
          labels.text('profile.education', 'Education'),
          profile.education!.trim(),
        ),
      if (profile.heightCm != null)
        (
          labels.text('profile.height', 'Height'),
          '${profile.heightCm} cm',
        ),
      if (profile.grewUpIn?.trim().isNotEmpty == true)
        (
          labels.text('profile.grew_up_in', 'Grew up in'),
          profile.grewUpIn!.trim(),
        ),
      if (profile.ethnicOrigin?.trim().isNotEmpty == true)
        (
          labels.text('profile.ethnic_origin', 'Ethnic origin'),
          profile.ethnicOrigin!.trim(),
        ),
      if (profile.religiousPractice?.trim().isNotEmpty == true)
        (
          labels.text('profile.religious_practice', 'Religious practice'),
          profile.religiousPractice!.trim(),
        ),
      if (profile.prayer?.trim().isNotEmpty == true)
        (
          labels.text('profile.prayer', 'Prayer'),
          profile.prayer!.trim(),
        ),
      if (profile.diet?.trim().isNotEmpty == true)
        (
          labels.text('profile.diet', 'Diet'),
          profile.diet!.trim(),
        ),
      if (profile.dress?.trim().isNotEmpty == true)
        (
          labels.text('profile.dress', 'Dress'),
          profile.dress!.trim(),
        ),
      if (profile.relocationPreference?.trim().isNotEmpty == true)
        (
          labels.text('profile.relocation', 'Relocation preference'),
          profile.relocationPreference!.trim(),
        ),
      if (profile.familyInvolvementPreference?.trim().isNotEmpty == true)
        (
          labels.text('profile.family_involvement', 'Family involvement'),
          profile.familyInvolvementPreference!.trim(),
        ),
    ];
    if (details.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        children: [
          for (final detail in details)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(detail.$1),
              subtitle: Text(detail.$2),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: SoulColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      );
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.title,
    required this.values,
  });

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: SoulColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: values.map((value) => Chip(label: Text(value))).toList(),
            ),
          ],
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: SoulColors.softSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: SoulColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onRetry,
                child: Text(retryLabel),
              ),
            ],
          ),
        ),
      );
}
