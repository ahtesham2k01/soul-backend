// ignore_for_file: prefer_interpolation_to_compose_strings, deprecated_member_use


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/soul_theme.dart';
import 'prototype_models.dart';

class PrototypeProfileView extends StatefulWidget {
  const PrototypeProfileView({
    required this.controller,
    super.key,
  });

  final PrototypeController controller;

  @override
  State<PrototypeProfileView> createState() => _PrototypeProfileViewState();
}

class _PrototypeProfileViewState extends State<PrototypeProfileView> {
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
    final displayName = c.firstName.isEmpty ? 'Your profile' : c.firstName;
    return Scaffold(
      backgroundColor: const Color(0xfff7f8f5),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            PrototypeHeader(
              title: c.t('profile.title'),
              subtitle: 'Your profile, privacy and account in one place.',
              trailing: IconButton.filledTonal(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PrototypeSettingsScreen(controller: c),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined),
              ),
            ),
            const SizedBox(height: 20),
            PrototypeSectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PrototypePortrait(
                          seed: 31,
                          name: displayName,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(22),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0xaa071102),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          right: 18,
                          bottom: 16,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayName + ', 27',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 27,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.verified_rounded,
                                color: SoulColors.limeLight,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _profileProgress(),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.edit_outlined,
                                label: 'Edit profile',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        PrototypeEditProfileScreen(
                                      controller: c,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.verified_user_outlined,
                                label: 'Verification',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        PrototypeVerificationScreen(
                                      controller: c,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.workspace_premium_outlined,
                                label: 'Premium',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        PrototypePremiumScreen(
                                      controller: c,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _statusCard(),
            const SizedBox(height: 16),
            PrototypeSectionCard(
              child: Column(
                children: [
                  _settingsRow(
                    Icons.event_outlined,
                    'Events',
                    'Meet people through curated experiences',
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            PrototypeEventsScreen(controller: c),
                      ),
                    ),
                  ),
                  _divider(),
                  _settingsRow(
                    Icons.shield_outlined,
                    'Safety Center',
                    'Reporting, blocked accounts and safety guidance',
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            PrototypeSafetyCenterScreen(controller: c),
                      ),
                    ),
                  ),
                  _divider(),
                  _settingsRow(
                    Icons.visibility_outlined,
                    'Privacy & visibility',
                    'Incognito, pause and contact hiding',
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            PrototypePrivacyScreen(controller: c),
                      ),
                    ),
                  ),
                  _divider(),
                  _settingsRow(
                    Icons.notifications_none_rounded,
                    'Notifications',
                    'Matches, messages and quiet hours',
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            PrototypeNotificationsScreen(controller: c),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileProgress() {
    var score = 72;
    if (c.bio.isNotEmpty) score += 7;
    if (c.education.isNotEmpty) score += 5;
    if (c.height.isNotEmpty) score += 4;
    if (c.interests.isNotEmpty) score += 6;
    if (c.selfieVerified) score += 6;
    score = score.clamp(0, 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Profile quality',
              style: TextStyle(
                color: SoulColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              score.toString() + '%',
              style: const TextStyle(
                color: SoulColors.forest,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 7,
            backgroundColor: SoulColors.softSurface,
            color: SoulColors.limeLight,
          ),
        ),
      ],
    );
  }

  Widget _statusCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff173105), Color(0xff2f5510)],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Icon(
              c.plan == null
                  ? Icons.auto_awesome_outlined
                  : Icons.workspace_premium_rounded,
              color: SoulColors.limeLight,
              size: 30,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.plan == null
                        ? 'SOUL Free'
                        : 'SOUL ' + (c.plan ?? ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    c.plan == null
                        ? 'Discover, match and chat with core safety features included.'
                        : 'Your preview premium plan is active.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _settingsRow(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: SoulColors.limeLight.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: SoulColors.forest),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: SoulColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      );

  Widget _divider() => const Divider(height: 1, color: SoulColors.line);
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: SoulColors.softSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Column(
              children: [
                Icon(icon, color: SoulColors.forest),
                const SizedBox(height: 7),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SoulColors.ink,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class PrototypeSettingsScreen extends StatelessWidget {
  const PrototypeSettingsScreen({
    required this.controller,
    super.key,
  });

  final PrototypeController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      backgroundColor: const Color(0xfff7f8f5),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
        children: [
          _settingsGroup(
            children: [
              _tile(
                Icons.language_rounded,
                'Language',
                c.locale == 'ur' ? 'Roman Urdu' : 'English',
                () => _languageSheet(context, c),
              ),
              _tile(
                Icons.visibility_outlined,
                'Privacy & visibility',
                c.incognito ? 'Incognito on' : 'Manage discoverability',
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PrototypePrivacyScreen(controller: c),
                  ),
                ),
              ),
              _tile(
                Icons.notifications_none_rounded,
                'Notifications',
                'Matches, messages and marketing',
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PrototypeNotificationsScreen(controller: c),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _settingsGroup(
            children: [
              _tile(
                Icons.verified_user_outlined,
                'Verification',
                c.selfieVerified ? 'Selfie verified' : '2 of 4 complete',
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PrototypeVerificationScreen(controller: c),
                  ),
                ),
              ),
              _tile(
                Icons.shield_outlined,
                'Safety Center',
                'Reports, blocks and guidance',
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PrototypeSafetyCenterScreen(controller: c),
                  ),
                ),
              ),
              _tile(
                Icons.lock_outline_rounded,
                'Account & security',
                'Devices, export and deletion',
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PrototypeAccountSecurityScreen(controller: c),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _settingsGroup(
            children: [
              _tile(
                Icons.event_outlined,
                'Events',
                'Upcoming and joined events',
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PrototypeEventsScreen(controller: c),
                  ),
                ),
              ),
              _tile(
                Icons.workspace_premium_outlined,
                'Subscription',
                c.plan == null ? 'Free plan' : 'SOUL ' + (c.plan ?? ''),
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PrototypePremiumScreen(controller: c),
                  ),
                ),
              ),
              _tile(
                Icons.help_outline_rounded,
                'Help & support',
                'FAQs and contact support',
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrototypeSupportScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(
              'SOUL design prototype · local data only',
              style: TextStyle(
                color: SoulColors.muted.withValues(alpha: .8),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsGroup({required List<Widget> children}) =>
      PrototypeSectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index != children.length - 1)
                const Divider(height: 1, color: SoulColors.line),
            ],
          ],
        ),
      );

  Widget _tile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) =>
      ListTile(
        onTap: onTap,
        leading: Icon(icon, color: SoulColors.forest),
        title: Text(
          title,
          style: const TextStyle(
            color: SoulColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      );

  Future<void> _languageSheet(
    BuildContext context,
    PrototypeController c,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PrototypeHeader(
                title: 'Language',
                subtitle: 'Production translations come from Laravel.',
              ),
              const SizedBox(height: 18),
              for (final option in const [
                ('en', 'English'),
                ('en-GB', 'English (UK)'),
                ('ur', 'Roman Urdu'),
              ])
                RadioListTile<String>(
                  value: option.$1,
                  groupValue: c.locale,
                  title: Text(option.$2),
                  onChanged: (value) {
                    if (value == null) return;
                    c.chooseLocale(value);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrototypeEditProfileScreen extends StatefulWidget {
  const PrototypeEditProfileScreen({
    required this.controller,
    super.key,
  });

  final PrototypeController controller;

  @override
  State<PrototypeEditProfileScreen> createState() =>
      _PrototypeEditProfileScreenState();
}

class _PrototypeEditProfileScreenState
    extends State<PrototypeEditProfileScreen> {
  late final TextEditingController bio =
      TextEditingController(text: widget.controller.bio);
  late final TextEditingController profession =
      TextEditingController(text: widget.controller.profession);

  @override
  void dispose() {
    bio.dispose();
    profession.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: () {
              c.bio = bio.text.trim();
              c.profession = profession.text.trim();
              c.changed();
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          const PrototypeHeader(
            title: 'Make your profile feel like you',
            subtitle:
                'Keep it specific, warm and easy for someone to start a conversation from.',
          ),
          const SizedBox(height: 22),
          TextField(
            controller: profession,
            decoration: const InputDecoration(labelText: 'Profession'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: bio,
            minLines: 5,
            maxLines: 8,
            maxLength: 320,
            decoration: const InputDecoration(labelText: 'About you'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Interests',
            style: TextStyle(
              color: SoulColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const [
                'Fitness',
                'Travel',
                'Family',
                'Books',
                'Food',
                'Tech',
                'Music',
                'Nature',
              ])
                PrototypePill(
                  item,
                  selected: c.interests.contains(item),
                  onTap: () => setState(() {
                    if (!c.interests.remove(item)) c.interests.add(item);
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class PrototypeVerificationScreen extends StatefulWidget {
  const PrototypeVerificationScreen({
    required this.controller,
    super.key,
  });

  final PrototypeController controller;

  @override
  State<PrototypeVerificationScreen> createState() =>
      _PrototypeVerificationScreenState();
}

class _PrototypeVerificationScreenState
    extends State<PrototypeVerificationScreen> {
  PrototypeController get c => widget.controller;

  Future<void> _verifySelfie() async {
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(
      MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 550),
    );
    if (!mounted) return;
    c.setSelfieVerified();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selfie verification approved for preview.')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfff7f8f5),
        appBar: AppBar(title: const Text('Verification')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const PrototypeHeader(
              title: 'Build trust at your pace',
              subtitle:
                  'Verification types stay separate. Optional verification does not silently block your profile.',
            ),
            const SizedBox(height: 22),
            _verificationTile(
              Icons.mail_outline_rounded,
              'Email',
              'Verified',
              true,
              null,
            ),
            const SizedBox(height: 10),
            _verificationTile(
              Icons.phone_outlined,
              'Phone',
              'Verified',
              true,
              null,
            ),
            const SizedBox(height: 10),
            _verificationTile(
              Icons.face_retouching_natural_outlined,
              'Selfie / face',
              c.selfieVerified ? 'Verified' : 'Recommended',
              c.selfieVerified,
              c.selfieVerified ? null : _verifySelfie,
            ),
            const SizedBox(height: 10),
            _verificationTile(
              Icons.badge_outlined,
              'ID / age',
              c.idVerified ? 'Verified' : 'Optional unless safety requires it',
              c.idVerified,
              c.idVerified
                  ? null
                  : () {
                      c.setIdVerified();
                      setState(() {});
                    },
            ),
            const SizedBox(height: 16),
            PrototypeSectionCard(
              color: SoulColors.limeLight.withValues(alpha: .14),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: SoulColors.forest),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The launch decision on mandatory selfie verification remains separate. This prototype preserves the current optional/risk-required rule.',
                      style: TextStyle(
                        color: SoulColors.forest,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _verificationTile(
    IconData icon,
    String title,
    String subtitle,
    bool verified,
    VoidCallback? action,
  ) =>
      PrototypeSectionCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: verified
                    ? SoulColors.limeLight.withValues(alpha: .2)
                    : SoulColors.softSurface,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: SoulColors.forest),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: SoulColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: SoulColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            if (verified)
              const Icon(Icons.verified_rounded, color: SoulColors.forest)
            else
              FilledButton(
                onPressed: action,
                child: const Text('Start'),
              ),
          ],
        ),
      );
}

class PrototypePremiumScreen extends StatefulWidget {
  const PrototypePremiumScreen({
    required this.controller,
    super.key,
  });

  final PrototypeController controller;

  @override
  State<PrototypePremiumScreen> createState() =>
      _PrototypePremiumScreenState();
}

class _PrototypePremiumScreenState extends State<PrototypePremiumScreen> {
  String billing = 'Monthly';

  PrototypeController get c => widget.controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: SoulColors.forestDeep,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text('SOUL Premium'),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
            children: [
              const Text(
                'More control.\nNever less safety.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  height: 1.04,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Core safety, blocking, reporting, privacy and account controls stay free.',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              SegmentedButton<String>(
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? SoulColors.ink
                        : Colors.white,
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? SoulColors.limeLight
                        : Colors.white10,
                  ),
                ),
                segments: const [
                  ButtonSegment(value: 'Weekly', label: Text('Weekly')),
                  ButtonSegment(value: 'Monthly', label: Text('Monthly')),
                  ButtonSegment(value: 'Yearly', label: Text('Yearly')),
                ],
                selected: {billing},
                onSelectionChanged: (value) =>
                    setState(() => billing = value.first),
              ),
              const SizedBox(height: 18),
              _planCard(
                'Plus',
                'More daily flexibility',
                const [
                  'More Likes',
                  'Undo a recent pass',
                  'Extra discovery controls',
                ],
              ),
              const SizedBox(height: 14),
              _planCard(
                'Premium',
                'Your fullest SOUL experience',
                const [
                  'Everything in Plus',
                  'See incoming Likes sooner',
                  'Incognito controls',
                  'Priority experience where configured',
                ],
                featured: true,
              ),
              const SizedBox(height: 14),
              const Text(
                '3-day free trial may be available when configured. Store pricing and renewal terms replace these preview values in production.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _planCard(
    String name,
    String subtitle,
    List<String> features, {
    bool featured = false,
  }) {
    final selected = c.plan == name;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: featured ? SoulColors.limeLight : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: selected ? SoulColors.lime : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SOUL ' + name,
                style: const TextStyle(
                  color: SoulColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (featured)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: SoulColors.forestDeep,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Most complete',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: SoulColors.muted)),
          const SizedBox(height: 16),
          for (final feature in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: SoulColors.forest,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(color: SoulColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                c.setPlan(name);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'SOUL ' + name + ' activated for this local preview.',
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor:
                    featured ? SoulColors.forestDeep : SoulColors.limeLight,
                foregroundColor:
                    featured ? Colors.white : SoulColors.ink,
              ),
              child: Text(
                selected ? 'Active' : 'Choose ' + name + ' · ' + billing,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrototypePrivacyScreen extends StatefulWidget {
  const PrototypePrivacyScreen({
    required this.controller,
    super.key,
  });

  final PrototypeController controller;

  @override
  State<PrototypePrivacyScreen> createState() => _PrototypePrivacyScreenState();
}

class _PrototypePrivacyScreenState extends State<PrototypePrivacyScreen> {
  PrototypeController get c => widget.controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Privacy & visibility')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
          children: [
            const PrototypeHeader(
              title: 'Your visibility, your choice',
              subtitle:
                  'Privacy controls should be clear, understandable and never buried behind confusing icons.',
            ),
            const SizedBox(height: 22),
            PrototypeSectionCard(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: c.incognito,
                    title: const Text(
                      'Incognito',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: const Text(
                      'Only people you Like can discover you while this is on.',
                    ),
                    onChanged: (value) => setState(() {
                      c.incognito = value;
                      c.changed();
                    }),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: c.paused,
                    title: const Text(
                      'Pause profile',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: const Text(
                      'Keep your account but temporarily leave discovery.',
                    ),
                    onChanged: (value) => setState(() {
                      c.paused = value;
                      c.changed();
                    }),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: c.hideContacts,
                    title: const Text(
                      'Hide known contacts',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: const Text(
                      'Avoid matching with people found through your approved contact-hiding flow.',
                    ),
                    onChanged: (value) => setState(() {
                      c.hideContacts = value;
                      c.changed();
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PrototypeSectionCard(
              color: SoulColors.limeLight.withValues(alpha: .14),
              child: const Text(
                'Exact coordinates are never shown to members. Private-photo access remains match-bound and revocable.',
                style: TextStyle(
                  color: SoulColors.forest,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class PrototypeNotificationsScreen extends StatefulWidget {
  const PrototypeNotificationsScreen({
    required this.controller,
    super.key,
  });

  final PrototypeController controller;

  @override
  State<PrototypeNotificationsScreen> createState() =>
      _PrototypeNotificationsScreenState();
}

class _PrototypeNotificationsScreenState
    extends State<PrototypeNotificationsScreen> {
  PrototypeController get c => widget.controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
          children: [
            const PrototypeHeader(
              title: 'Useful, not noisy',
              subtitle:
                  'Transactional and safety messages stay separate from marketing.',
            ),
            const SizedBox(height: 20),
            PrototypeSectionCard(
              child: Column(
                children: [
                  _toggle(
                    'Matches',
                    'New matches and incoming decisions',
                    c.pushMatches,
                    (value) => c.pushMatches = value,
                  ),
                  const Divider(height: 1),
                  _toggle(
                    'Messages',
                    'Replies and important chat activity',
                    c.pushMessages,
                    (value) => c.pushMessages = value,
                  ),
                  const Divider(height: 1),
                  _toggle(
                    'Marketing',
                    'Offers and product news',
                    c.marketing,
                    (value) => c.marketing = value,
                  ),
                  const Divider(height: 1),
                  _toggle(
                    'Quiet hours',
                    'Silence non-critical notifications overnight',
                    c.quietHours,
                    (value) => c.quietHours = value,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _toggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> update,
  ) =>
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: value,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        onChanged: (next) => setState(() {
          update(next);
          c.changed();
        }),
      );
}

class PrototypeSafetyCenterScreen extends StatelessWidget {
  const PrototypeSafetyCenterScreen({
    required this.controller,
    super.key,
  });

  final PrototypeController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfff7f8f5),
        appBar: AppBar(title: const Text('Safety Center')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
          children: [
            const PrototypeHeader(
              title: 'Meet with confidence',
              subtitle:
                  'Safety actions are never paywalled. Serious or disputed cases can move to human review.',
            ),
            const SizedBox(height: 20),
            _safetyCard(
              Icons.shield_outlined,
              'Report or block',
              'Profiles and chats keep Report, Block and Report & Block within reach.',
            ),
            _safetyCard(
              Icons.payments_outlined,
              'Money requests',
              'Do not send money, bank details, passwords or OTPs to someone you met here.',
            ),
            _safetyCard(
              Icons.location_on_outlined,
              'Meet in public',
              'Choose a public place, control your own transport and tell someone you trust.',
            ),
            _safetyCard(
              Icons.verified_user_outlined,
              'Verification',
              'Selfie and ID states are separate. Risk may require stronger checks in specific cases.',
            ),
            const SizedBox(height: 6),
            PrototypeSectionCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.block_rounded,
                  color: SoulColors.forest,
                ),
                title: const Text(
                  'Blocked accounts',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  controller.blockedIds.isEmpty
                      ? 'You have not blocked anyone in this preview.'
                      : controller.blockedIds.length.toString() +
                          ' account blocked in this preview.',
                ),
              ),
            ),
          ],
        ),
      );

  Widget _safetyCard(IconData icon, String title, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PrototypeSectionCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SoulColors.limeLight.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: SoulColors.forest),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: SoulColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: const TextStyle(
                        color: SoulColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class PrototypeEventsScreen extends StatefulWidget {
  const PrototypeEventsScreen({
    required this.controller,
    super.key,
  });

  final PrototypeController controller;

  @override
  State<PrototypeEventsScreen> createState() => _PrototypeEventsScreenState();
}

class _PrototypeEventsScreenState extends State<PrototypeEventsScreen> {
  bool joinedOnly = false;
  PrototypeController get c => widget.controller;

  @override
  Widget build(BuildContext context) {
    final visible = c.events
        .where((event) => !joinedOnly || event.joined)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xfff7f8f5),
      appBar: AppBar(title: const Text('Events')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          children: [
            PrototypeHeader(
              title: joinedOnly ? 'My events' : 'Upcoming events',
              subtitle:
                  'Admin-approved experiences that create another path to meaningful introductions.',
              trailing: IconButton.filledTonal(
                onPressed: () => setState(() => joinedOnly = !joinedOnly),
                icon: Icon(
                  joinedOnly
                      ? Icons.calendar_month_rounded
                      : Icons.bookmark_outline_rounded,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: visible.isEmpty
                  ? const Center(
                      child: Text(
                        'You have not joined any upcoming events yet.',
                        style: TextStyle(color: SoulColors.muted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final event = visible[index];
                        return PrototypeSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: SoulColors.limeLight,
                                      borderRadius: BorderRadius.circular(17),
                                    ),
                                    child: Icon(
                                      event.icon,
                                      color: SoulColors.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: const TextStyle(
                                            color: SoulColors.ink,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          event.when + ' · ' + event.city,
                                          style: const TextStyle(
                                            color: SoulColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                event.subtitle,
                                style: const TextStyle(
                                  color: SoulColors.muted,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    c.toggleEvent(event);
                                    setState(() {});
                                  },
                                  child: Text(
                                    event.joined ? 'Leave event' : 'Join event',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrototypeAccountSecurityScreen extends StatefulWidget {
  const PrototypeAccountSecurityScreen({
    required this.controller,
    super.key,
  });

  final PrototypeController controller;

  @override
  State<PrototypeAccountSecurityScreen> createState() =>
      _PrototypeAccountSecurityScreenState();
}

class _PrototypeAccountSecurityScreenState
    extends State<PrototypeAccountSecurityScreen> {
  bool exportReady = false;
  bool deletionScheduled = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Account & security')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
          children: [
            const PrototypeHeader(
              title: 'Stay in control',
              subtitle:
                  'Review devices, export your data or schedule account deletion.',
            ),
            const SizedBox(height: 20),
            PrototypeSectionCard(
              child: Column(
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.phone_android_rounded,
                      color: SoulColors.forest,
                    ),
                    title: Text(
                      'This device',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text('Android · Active now'),
                    trailing: Icon(
                      Icons.check_circle_rounded,
                      color: SoulColors.forest,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.download_outlined,
                      color: SoulColors.forest,
                    ),
                    title: const Text(
                      'Download my data',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      exportReady
                          ? 'Your preview export is ready.'
                          : 'Create a portable copy of your account data.',
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        await Future<void>.delayed(
                          const Duration(milliseconds: 350),
                        );
                        if (mounted) setState(() => exportReady = true);
                      },
                      child: Text(exportReady ? 'Ready' : 'Request'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrototypeSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delete account',
                    style: TextStyle(
                      color: Color(0xffb3261e),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    deletionScheduled
                        ? 'Deletion scheduled. Production provides the documented recovery period before permanent deletion.'
                        : 'Schedule deletion with the documented recovery period. Safety evidence may follow approved retention rules.',
                    style: const TextStyle(
                      color: SoulColors.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () =>
                        setState(() => deletionScheduled = !deletionScheduled),
                    child: Text(
                      deletionScheduled
                          ? 'Cancel deletion'
                          : 'Schedule deletion',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class PrototypeSupportScreen extends StatefulWidget {
  const PrototypeSupportScreen({super.key});

  @override
  State<PrototypeSupportScreen> createState() => _PrototypeSupportScreenState();
}

class _PrototypeSupportScreenState extends State<PrototypeSupportScreen> {
  final TextEditingController message = TextEditingController();

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Help & support')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
          children: [
            const PrototypeHeader(
              title: 'How can we help?',
              subtitle:
                  'Safety, account and subscription support should be easy to reach.',
            ),
            const SizedBox(height: 20),
            for (final faq in const [
              ('Why can’t I see a profile?', 'Discovery respects blocks, pause, filters and availability.'),
              ('How do private photos work?', 'Access is match-bound and can be revoked.'),
              ('How do I report someone?', 'Use Report or Report & Block from a profile or conversation.'),
            ])
              ExpansionTile(
                title: Text(
                  faq.$1,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      faq.$2,
                      style: const TextStyle(
                        color: SoulColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            TextField(
              controller: message,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Contact support',
                hintText: 'Tell us what happened…',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Support request submitted for preview.'),
                  ),
                );
                message.clear();
              },
              child: const Text('Send request'),
            ),
          ],
        ),
      );
}
