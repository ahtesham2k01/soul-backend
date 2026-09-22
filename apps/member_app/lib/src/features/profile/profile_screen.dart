import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import '../events/event_repository.dart';
import '../events/events_screen.dart';
import '../onboarding/photo_onboarding_screen.dart';
import '../safety/safety_repository.dart';
import '../safety/safety_screen.dart';
import 'notification_center_screen.dart';
import 'profile_edit_screen.dart';
import 'profile_repository.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.repository,
    required this.safetyRepository,
    required this.eventRepository,
    required this.labels,
    required this.onSessionEnded,
    required this.onLocaleChanged,
  });

  final ProfileRepository repository;
  final SafetyRepository safetyRepository;
  final EventRepository eventRepository;
  final BootstrapState labels;
  final VoidCallback onSessionEnded;
  final Future<void> Function() onLocaleChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AccountSnapshot? _account;
  Map<String, dynamic> _profile = const {};
  Map<String, dynamic> _religion = const {};
  List<OwnProfilePhoto> _photos = const [];
  bool _loading = true;
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
      final values = await Future.wait<Object?>([
        widget.repository.account(),
        widget.repository.profile(),
        widget.repository.photos(),
        widget.repository.religionProfile(),
      ]);
      if (!mounted) return;
      setState(() {
        _account = values[0] as AccountSnapshot;
        _profile = values[1] as Map<String, dynamic>;
        _photos = values[2] as List<OwnProfilePhoto>;
        _religion = values[3] is Map
            ? Map<String, dynamic>.from(values[3] as Map)
            : const <String, dynamic>{};
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

  OwnProfilePhoto? get _cover {
    for (final photo in _photos) {
      if (photo.position == 1) return photo;
    }
    return null;
  }

  int get _completionPercent {
    final spokenLanguages = _profile['spoken_languages'];
    final religionPath = _religion['path'];
    final approvedCover = _cover?.moderationStatus == 'approved' &&
        _cover?.visibility == 'public';
    final approvedClearFace = _photos.any(
      (photo) =>
          photo.moderationStatus == 'approved' &&
          photo.faceDetected == true,
    );

    final required = <bool>[
      _filled(_profile['first_name']),
      _filled(_profile['date_of_birth']),
      _filled(_profile['gender']),
      _filled(_profile['city_name']),
      _filled(_profile['country_code']),
      _filled(_profile['nationality_country_code']),
      religionPath is List && religionPath.isNotEmpty,
      _filled(_profile['marital_status']),
      _profile['intentions'] is List &&
          (_profile['intentions'] as List).isNotEmpty,
      _filled(_profile['profession_status']),
      spokenLanguages is List && spokenLanguages.isNotEmpty,
      _filled(_profile['smoking']),
      _filled(_profile['alcohol']),
      _filled(_profile['current_children']),
      _filled(_profile['future_children']),
      approvedCover,
      approvedClearFace,
    ];
    final done = required.where((value) => value).length;
    return ((done / required.length) * 100).round();
  }

  bool _filled(Object? value) =>
      value != null && value.toString().trim().isNotEmpty;

  List<String> _strings(Object? value) => value is List
      ? value.map((item) => item.toString()).toList(growable: false)
      : const [];

  String _label(String key, Object? value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return '—';
    return widget.labels.text(
      '$key.$raw',
      raw.replaceAll('_', ' '),
    );
  }

  String _displayList(Object? value) {
    if (value is! List || value.isEmpty) return '—';
    return value.map((item) {
      if (item is Map) {
        return item['native_name']?.toString() ??
            item['name']?.toString() ??
            item['label']?.toString() ??
            item['value']?.toString() ??
            item['code']?.toString() ??
            '';
      }
      return item.toString().replaceAll('_', ' ');
    }).where((item) => item.trim().isNotEmpty).join(' · ');
  }

  String _religionPath() {
    final raw = _religion['path'];
    if (raw is! List || raw.isEmpty) return '—';
    return raw.whereType<Map>().map((item) {
      final label = item['label']?.toString().trim() ?? '';
      if (label.isNotEmpty) return label;
      final slug = item['slug']?.toString() ?? '';
      return slug
          .split('-')
          .where((part) => part.isNotEmpty)
          .map((part) =>
              part[0].toUpperCase() + part.substring(1).toLowerCase())
          .join(' ');
    }).where((item) => item.isNotEmpty).join(' · ');
  }

  String _intentions() {
    final values = _strings(_profile['intentions']);
    if (values.isEmpty) return '—';
    return values
        .map(
          (value) => switch (value) {
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
          },
        )
        .join(' · ');
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(
          repository: widget.repository,
          labels: widget.labels,
          initial: _profile,
        ),
      ),
    );
    if (changed == true && mounted) await _load();
  }

  Future<void> _photosEditor() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PhotoOnboardingScreen(labels: widget.labels),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _settings() async {
    final account = _account;
    if (account == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          repository: widget.repository,
          labels: widget.labels,
          account: account,
          profile: _profile,
          onSessionEnded: widget.onSessionEnded,
          onLocaleChanged: widget.onLocaleChanged,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: Colors.white,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return ColoredBox(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _load,
                  child: Text(
                    widget.labels.text('common.retry', 'Try again'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: const Color(0xfff7f7f4),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 126),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.labels.text('nav.profile', 'Profile'),
                      style: const TextStyle(
                        color: SoulColors.ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: widget.labels.text('notifications.title', 'Notifications'),
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => NotificationCenterScreen(
                          repository: widget.repository,
                          labels: widget.labels,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                  IconButton(
                    tooltip: widget.labels.text(
                      'settings.title',
                      'Settings',
                    ),
                    onPressed: _settings,
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ProfileHero(
                firstName: _profile['first_name']?.toString() ?? 'SOUL',
                status: _profile['profile_status']?.toString() ?? '',
                completionPercent: _completionPercent,
                coverUrl: _cover?.url,
                onEdit: _edit,
                onPhotos: _photosEditor,
                labels: widget.labels,
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => MembershipScreen(
                      repository: widget.repository,
                      labels: widget.labels,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: SoulColors.limeLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.black,
                        foregroundColor: SoulColors.limeLight,
                        child: Icon(Icons.workspace_premium_rounded),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.labels.text(
                                'profile.membership_cta',
                                'Make your profile stand out',
                              ),
                              style: const TextStyle(
                                color: SoulColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.labels.text(
                                'profile.membership_cta_subtitle',
                                'View Plus and Premium membership options.',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ProfileShortcut(
                      icon: Icons.event_outlined,
                      label: widget.labels.text('profile.events', 'Events'),
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => EventsScreen(
                            repository: widget.eventRepository,
                            labels: widget.labels,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ProfileShortcut(
                      icon: Icons.verified_user_outlined,
                      label: widget.labels.text('profile.verification', 'Verification'),
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => VerificationScreen(
                            repository: widget.safetyRepository,
                            labels: widget.labels,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ProfileShortcut(
                      icon: Icons.settings_outlined,
                      label: widget.labels.text('settings.title', 'Settings'),
                      onTap: _settings,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ProfileSection(
                title: widget.labels.text('profile.bio', 'About you'),
                rows: [
                  _ProfileValue(
                    icon: Icons.short_text_rounded,
                    label: widget.labels.text('profile.bio', 'About you'),
                    value: _profile['bio']?.toString() ?? 'Add a bio',
                  ),
                  _ProfileValue(
                    icon: Icons.location_on_outlined,
                    label: widget.labels.text(
                      'profile.city',
                      'Current city',
                    ),
                    value: _profile['city_name']?.toString() ?? '—',
                  ),
                  _ProfileValue(
                    icon: Icons.straighten_rounded,
                    label: widget.labels.text('profile.height', 'Height'),
                    value: _profile['height_cm'] == null
                        ? '—'
                        : '${_profile['height_cm']} cm',
                  ),
                  _ProfileValue(
                    icon: Icons.favorite_outline_rounded,
                    label: widget.labels.text(
                      'profile.marital_status',
                      'Marital status',
                    ),
                    value: _label(
                      'profile',
                      _profile['marital_status'],
                    ),
                  ),
                ],
              ),
              _ProfileSection(
                title: widget.labels.text(
                  'profile.intentions',
                  'What are you looking for?',
                ),
                rows: [
                  _ProfileValue(
                    icon: Icons.favorite_rounded,
                    label: widget.labels.text(
                      'profile.intentions',
                      'What are you looking for?',
                    ),
                    value: _intentions(),
                  ),
                  _ProfileValue(
                    icon: Icons.child_care_outlined,
                    label: widget.labels.text(
                      'profile.children_future',
                      'Do you want children?',
                    ),
                    value: _label(
                      'profile',
                      _profile['future_children'],
                    ),
                  ),
                ],
              ),
              _ProfileSection(
                title: widget.labels.text('profile.section_personality', 'Personality and interests'),
                rows: [
                  _ProfileValue(
                    icon: Icons.interests_outlined,
                    label: widget.labels.text(
                      'profile.interests',
                      'Interests',
                    ),
                    value: _displayList(_profile['interests']),
                  ),
                  _ProfileValue(
                    icon: Icons.psychology_outlined,
                    label: widget.labels.text(
                      'profile.traits',
                      'Personality traits',
                    ),
                    value: _displayList(_profile['personality_traits']),
                  ),
                  _ProfileValue(
                    icon: Icons.language_outlined,
                    label: widget.labels.text(
                      'profile.languages',
                      'Languages you speak',
                    ),
                    value: _displayList(_profile['spoken_languages']),
                  ),
                ],
              ),
              _ProfileSection(
                title: widget.labels.text('profile.section_background', 'Background and faith'),
                rows: [
                  _ProfileValue(
                    icon: Icons.account_tree_outlined,
                    label: widget.labels.text(
                      'profile.religion',
                      'Religion or belief',
                    ),
                    value: _religionPath(),
                  ),
                  _ProfileValue(
                    icon: Icons.public_outlined,
                    label: widget.labels.text(
                      'profile.grew_up_in',
                      'Grew up in',
                    ),
                    value: _profile['grew_up_in']?.toString() ?? '—',
                  ),
                  _ProfileValue(
                    icon: Icons.groups_outlined,
                    label: widget.labels.text(
                      'profile.ethnic_origin',
                      'Ethnic origin',
                    ),
                    value: _profile['ethnic_origin']?.toString() ?? '—',
                  ),
                  _ProfileValue(
                    icon: Icons.self_improvement_outlined,
                    label: widget.labels.text(
                      'profile.religious_practice',
                      'Religious practice',
                    ),
                    value:
                        _profile['religious_practice']?.toString() ?? '—',
                  ),
                ],
              ),
              _ProfileSection(
                title: widget.labels.text('profile.section_career', 'Education and career'),
                rows: [
                  _ProfileValue(
                    icon: Icons.school_outlined,
                    label: widget.labels.text(
                      'profile.education',
                      'Education',
                    ),
                    value: _profile['education']?.toString() ?? '—',
                  ),
                  _ProfileValue(
                    icon: Icons.work_outline_rounded,
                    label: widget.labels.text(
                      'profile.job_title',
                      'Job title',
                    ),
                    value: _profile['job_title']?.toString() ??
                        _label(
                          'profile',
                          _profile['profession_status'],
                        ),
                  ),
                  _ProfileValue(
                    icon: Icons.business_outlined,
                    label: widget.labels.text(
                      'profile.employer',
                      'Employer',
                    ),
                    value: _profile['employer']?.toString() ?? '—',
                  ),
                ],
              ),
              _ProfileSection(
                title: widget.labels.text('profile.section_lifestyle', 'Lifestyle'),
                rows: [
                  _ProfileValue(
                    icon: Icons.smoke_free_rounded,
                    label: widget.labels.text(
                      'profile.smoking',
                      'Do you smoke?',
                    ),
                    value: _label('profile', _profile['smoking']),
                  ),
                  _ProfileValue(
                    icon: Icons.local_bar_outlined,
                    label: widget.labels.text(
                      'profile.alcohol',
                      'Do you drink alcohol?',
                    ),
                    value: _label('profile', _profile['alcohol']),
                  ),
                ],
              ),
              _ProfileSection(
                title: widget.labels.text('profile.section_future', 'Future plans'),
                rows: [
                  _ProfileValue(
                    icon: Icons.flight_takeoff_outlined,
                    label: widget.labels.text(
                      'profile.relocation',
                      'Relocation preference',
                    ),
                    value: _profile['relocation_preference']?.toString() ?? '—',
                  ),
                  _ProfileValue(
                    icon: Icons.family_restroom_outlined,
                    label: widget.labels.text(
                      'profile.family_involvement',
                      'Family involvement',
                    ),
                    value: _profile['family_involvement_preference']
                            ?.toString() ??
                        '—',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FilledButton.icon(
                onPressed: _edit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: SoulColors.limeLight,
                  foregroundColor: SoulColors.ink,
                ),
                icon: const Icon(Icons.edit_outlined),
                label: Text(widget.labels.text('common.edit', 'Edit')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.firstName,
    required this.status,
    required this.completionPercent,
    required this.coverUrl,
    required this.onEdit,
    required this.onPhotos,
    required this.labels,
  });

  final String firstName;
  final String status;
  final int completionPercent;
  final String? coverUrl;
  final VoidCallback onEdit;
  final VoidCallback onPhotos;
  final BootstrapState labels;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Row(
              children: [
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPhotos,
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: SoulColors.softSurface,
                    foregroundImage:
                        coverUrl == null || coverUrl!.isEmpty
                            ? null
                            : NetworkImage(coverUrl!),
                    child: coverUrl == null || coverUrl!.isEmpty
                        ? const Icon(
                            Icons.add_a_photo_outlined,
                            size: 30,
                            color: SoulColors.muted,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SoulColors.ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        status.isEmpty
                            ? 'Profile'
                            : status.replaceAll('_', ' '),
                        style: const TextStyle(color: SoulColors.muted),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: onEdit,
                  child: Text(labels.text('common.edit', 'Edit')),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: completionPercent / 100,
                      minHeight: 7,
                      color: SoulColors.lime,
                      backgroundColor: SoulColors.line,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$completionPercent%',
                  style: const TextStyle(
                    color: SoulColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                labels.text('profile.complete_profile', 'Complete profile'),
                style: const TextStyle(
                  color: SoulColors.muted,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
}

class _ProfileShortcut extends StatelessWidget {
  const _ProfileShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
            child: Column(
              children: [
                Icon(icon, color: SoulColors.ink, size: 25),
                const SizedBox(height: 7),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SoulColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_ProfileValue> rows;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                title,
                style: const TextStyle(
                  color: SoulColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    rows[i],
                    if (i < rows.length - 1)
                      const Divider(height: 1, indent: 54),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _ProfileValue extends StatelessWidget {
  const _ProfileValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: SoulColors.ink),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(value),
      );
}
