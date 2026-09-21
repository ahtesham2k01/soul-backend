import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import 'profile_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.repository,
    required this.labels,
    required this.account,
    required this.profile,
    required this.onSessionEnded,
    required this.onLocaleChanged,
  });

  final ProfileRepository repository;
  final BootstrapState labels;
  final AccountSnapshot account;
  final Map<String, dynamic> profile;
  final VoidCallback onSessionEnded;
  final VoidCallback onLocaleChanged;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfff7f7f4),
        appBar: AppBar(
          title: Text(labels.text('settings.title', 'Settings')),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
          children: [
            _SettingsSection(
              title: 'Personal information',
              children: [
                _ReadOnlyRow(
                  label: labels.text('profile.first_name', 'First name'),
                  value: profile['first_name']?.toString() ?? '—',
                ),
                _ReadOnlyRow(
                  label: 'Email address',
                  value: account.email ?? '—',
                ),
                _ReadOnlyRow(
                  label: 'Phone number',
                  value: account.phone ?? '—',
                ),
              ],
            ),
            _SettingsSection(
              title: labels.text('notifications.title', 'Notifications'),
              children: [
                _NavRow(
                  icon: Icons.notifications_none_rounded,
                  title: labels.text(
                    'notifications.title',
                    'Notifications',
                  ),
                  subtitle: 'New likes, matches, messages and account updates',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => NotificationSettingsScreen(
                        repository: repository,
                        labels: labels,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _SettingsSection(
              title: 'App settings',
              children: [
                _NavRow(
                  icon: Icons.language_rounded,
                  title: labels.text('settings.language', 'Language'),
                  subtitle: labels.locale,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => LanguageSettingsScreen(
                        repository: repository,
                        labels: labels,
                        onChanged: onLocaleChanged,
                      ),
                    ),
                  ),
                ),
                _NavRow(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Membership',
                  subtitle: 'Plus, Premium and store products',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => MembershipScreen(
                        repository: repository,
                        labels: labels,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _SettingsSection(
              title: labels.text('settings.privacy', 'Privacy'),
              children: [
                _NavRow(
                  icon: Icons.visibility_outlined,
                  title: labels.text('settings.privacy', 'Privacy'),
                  subtitle: 'Visibility, incognito, pause and photo protection',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => PrivacySettingsScreen(
                        repository: repository,
                        labels: labels,
                      ),
                    ),
                  ),
                ),
                _NavRow(
                  icon: Icons.block_rounded,
                  title: 'Blocked profiles',
                  subtitle: 'Review profiles you have blocked',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => BlockedProfilesScreen(
                        repository: repository,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _SettingsSection(
              title: 'Security',
              children: [
                _NavRow(
                  icon: Icons.devices_rounded,
                  title: labels.text(
                    'settings.devices',
                    'Active devices',
                  ),
                  subtitle: 'Sign out devices you no longer use',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => DeviceSessionsScreen(
                        repository: repository,
                        labels: labels,
                        onSessionEnded: onSessionEnded,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _SettingsSection(
              title: 'Manage account',
              children: [
                _NavRow(
                  icon: Icons.download_outlined,
                  title: labels.text(
                    'settings.download_data',
                    'Download my data',
                  ),
                  subtitle: 'Request a private export of your SOUL data',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => DataExportScreen(
                        repository: repository,
                        labels: labels,
                      ),
                    ),
                  ),
                ),
                _NavRow(
                  icon: Icons.delete_outline_rounded,
                  title: labels.text(
                    'settings.delete_account',
                    'Delete account',
                  ),
                  subtitle: labels.text(
                    'settings.deletion_recovery',
                    'You can recover your account for 30 days.',
                  ),
                  destructive: true,
                  onTap: () => _deleteAccount(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            OutlinedButton(
              onPressed: () => _logout(context, allDevices: false),
              child: Text(labels.text('auth.log_out', 'Log out')),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _logout(context, allDevices: true),
              child: Text(
                labels.text(
                  'auth.log_out_all',
                  'Log out from all devices',
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _logout(
    BuildContext context, {
    required bool allDevices,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          allDevices
              ? labels.text(
                  'auth.log_out_all',
                  'Log out from all devices',
                )
              : labels.text('auth.log_out', 'Log out'),
        ),
        content: Text(
          allDevices
              ? 'Every SOUL session on your devices will be signed out.'
              : 'You will be signed out on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(labels.text('common.cancel', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(labels.text('common.confirm', 'Confirm')),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    try {
      await repository.logout(allDevices: allDevices);
      onSessionEnded();
    } on SoulApiFailure catch (failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          labels.text('settings.delete_account', 'Delete account'),
        ),
        content: Text(
          labels.text(
            'settings.deletion_recovery',
            'You can recover your account for 30 days.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(labels.text('common.cancel', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(labels.text('common.confirm', 'Confirm')),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    try {
      await repository.scheduleDeletion();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Account deletion scheduled'),
          content: Text(
            labels.text(
              'settings.deletion_recovery',
              'You can recover your account for 30 days.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(labels.text('common.done', 'Done')),
            ),
          ],
        ),
      );
      onSessionEnded();
    } on SoulApiFailure catch (failure) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    }
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({
    super.key,
    required this.repository,
    required this.labels,
  });

  final ProfileRepository repository;
  final BootstrapState labels;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationSettings? _settings;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await widget.repository.notifications();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _loading = false;
        _error = null;
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _save() async {
    final settings = _settings;
    if (settings == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.repository.saveNotifications(settings);
      if (!mounted) return;
      setState(() {
        _settings = saved;
        _saving = false;
      });
      Navigator.of(context).pop();
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.labels.text(
              'notifications.title',
              'Notifications',
            ),
          ),
          actions: [
            TextButton(
              onPressed: _settings == null || _saving ? null : _save,
              child: Text(widget.labels.text('common.save', 'Save')),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _settings == null
                ? _Retry(
                    message: _error ?? 'Notifications are unavailable.',
                    onRetry: _load,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                    children: [
                      if (_error != null)
                        _InlineError(message: _error!),
                      _ToggleGroup(
                        title: 'Push notifications',
                        children: [
                          _switch(
                            widget.labels.text(
                              'notifications.new_matches',
                              'New matches',
                            ),
                            _settings!.pushNewMatches,
                            (value) => _settings = _settings!.copyWith(
                              pushNewMatches: value,
                            ),
                          ),
                          _switch(
                            widget.labels.text(
                              'notifications.new_messages',
                              'New messages',
                            ),
                            _settings!.pushNewMessages,
                            (value) => _settings = _settings!.copyWith(
                              pushNewMessages: value,
                            ),
                          ),
                          _switch(
                            'Private photos',
                            _settings!.pushPrivatePhotos,
                            (value) => _settings = _settings!.copyWith(
                              pushPrivatePhotos: value,
                            ),
                          ),
                          _switch(
                            'Verification',
                            _settings!.pushVerification,
                            (value) => _settings = _settings!.copyWith(
                              pushVerification: value,
                            ),
                          ),
                          _switch(
                            'Account updates',
                            _settings!.pushAccount,
                            (value) => _settings = _settings!.copyWith(
                              pushAccount: value,
                            ),
                          ),
                          _switch(
                            widget.labels.text(
                              'notifications.marketing',
                              'Marketing',
                            ),
                            _settings!.pushMarketing,
                            (value) => _settings = _settings!.copyWith(
                              pushMarketing: value,
                            ),
                          ),
                          const ListTile(
                            title: Text('Safety updates'),
                            subtitle: Text(
                              'Always on for important safety notices.',
                            ),
                            trailing: Icon(Icons.lock_outline_rounded),
                          ),
                        ],
                      ),
                      _ToggleGroup(
                        title: 'Email',
                        children: [
                          _switch(
                            widget.labels.text(
                              'notifications.new_matches',
                              'New matches',
                            ),
                            _settings!.emailNewMatches,
                            (value) => _settings = _settings!.copyWith(
                              emailNewMatches: value,
                            ),
                          ),
                          _switch(
                            widget.labels.text(
                              'notifications.new_messages',
                              'New messages',
                            ),
                            _settings!.emailNewMessages,
                            (value) => _settings = _settings!.copyWith(
                              emailNewMessages: value,
                            ),
                          ),
                          _switch(
                            'Private photos',
                            _settings!.emailPrivatePhotos,
                            (value) => _settings = _settings!.copyWith(
                              emailPrivatePhotos: value,
                            ),
                          ),
                          _switch(
                            'Verification',
                            _settings!.emailVerification,
                            (value) => _settings = _settings!.copyWith(
                              emailVerification: value,
                            ),
                          ),
                          _switch(
                            'Account updates',
                            _settings!.emailAccount,
                            (value) => _settings = _settings!.copyWith(
                              emailAccount: value,
                            ),
                          ),
                          _switch(
                            widget.labels.text(
                              'notifications.marketing',
                              'Marketing',
                            ),
                            _settings!.emailMarketing,
                            (value) => _settings = _settings!.copyWith(
                              emailMarketing: value,
                            ),
                          ),
                          const ListTile(
                            title: Text('Safety updates'),
                            subtitle: Text(
                              'Always on for important safety notices.',
                            ),
                            trailing: Icon(Icons.lock_outline_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
      );

  Widget _switch(
    String title,
    bool value,
    ValueChanged<bool> apply,
  ) =>
      SwitchListTile(
        title: Text(title),
        value: value,
        onChanged: _saving
            ? null
            : (next) => setState(() {
                  apply(next);
                  _error = null;
                }),
      );
}

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({
    super.key,
    required this.repository,
    required this.labels,
  });

  final ProfileRepository repository;
  final BootstrapState labels;

  @override
  State<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  PrivacySettings? _settings;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await widget.repository.privacy();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _loading = false;
        _error = null;
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _save() async {
    final settings = _settings;
    if (settings == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.repository.savePrivacy(settings);
      if (!mounted) return;
      setState(() {
        _settings = saved;
        _saving = false;
      });
      Navigator.of(context).pop();
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.labels.text('settings.privacy', 'Privacy')),
          actions: [
            TextButton(
              onPressed: _settings == null || _saving ? null : _save,
              child: Text(widget.labels.text('common.save', 'Save')),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _settings == null
                ? _Retry(
                    message: _error ?? 'Privacy settings are unavailable.',
                    onRetry: _load,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                    children: [
                      if (_error != null)
                        _InlineError(message: _error!),
                      _ToggleGroup(
                        title: 'Profile visibility',
                        children: [
                          _privacySwitch(
                            'Discoverable',
                            'Allow your profile to appear in discovery.',
                            _settings!.discoverable,
                            (value) => _settings =
                                _settings!.copyWith(discoverable: value),
                          ),
                          _privacySwitch(
                            'Incognito',
                            'Only people you have liked can discover you.',
                            _settings!.incognito,
                            (value) =>
                                _settings = _settings!.copyWith(incognito: value),
                          ),
                          _privacySwitch(
                            'Pause profile',
                            'Temporarily stop appearing in discovery.',
                            _settings!.profilePaused,
                            (value) => _settings =
                                _settings!.copyWith(profilePaused: value),
                          ),
                          _privacySwitch(
                            'Show city',
                            'Show your city, never your precise coordinates.',
                            _settings!.showCity,
                            (value) =>
                                _settings = _settings!.copyWith(showCity: value),
                          ),
                        ],
                      ),
                      _ToggleGroup(
                        title: 'Contact privacy',
                        children: [
                          _privacySwitch(
                            'Hide phone contacts',
                            'Hide profiles that match contacts you upload for privacy filtering.',
                            _settings!.hideContacts,
                            (value) => _settings =
                                _settings!.copyWith(hideContacts: value),
                          ),
                        ],
                      ),
                      _ToggleGroup(
                        title: 'Private photos',
                        children: [
                          _privacySwitch(
                            'Screenshot protection',
                            'Use the maximum protection available on supported devices.',
                            _settings!.screenshotProtectionEnabled,
                            (value) => _settings = _settings!.copyWith(
                              screenshotProtectionEnabled: value,
                            ),
                          ),
                          const ListTile(
                            title: Text('Read receipts'),
                            subtitle: Text(
                              'Read receipts remain enabled for all chats.',
                            ),
                            trailing: Icon(Icons.lock_outline_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
      );

  Widget _privacySwitch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> apply,
  ) =>
      SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: _saving
            ? null
            : (next) => setState(() {
                  apply(next);
                  _error = null;
                }),
      );
}

class BlockedProfilesScreen extends StatefulWidget {
  const BlockedProfilesScreen({
    super.key,
    required this.repository,
  });

  final ProfileRepository repository;

  @override
  State<BlockedProfilesScreen> createState() => _BlockedProfilesScreenState();
}

class _BlockedProfilesScreenState extends State<BlockedProfilesScreen> {
  final List<BlockedProfile> _items = [];
  String? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;
  final Set<String> _busy = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final page = await widget.repository.blockedProfiles();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _nextCursor = page.nextCursor;
        _loading = false;
        _error = null;
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
      final page = await widget.repository.blockedProfiles(cursor: cursor);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
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

  Future<void> _unblock(BlockedProfile item) async {
    setState(() => _busy.add(item.id));
    try {
      await widget.repository.unblock(item.id);
      if (!mounted) return;
      setState(() {
        _busy.remove(item.id);
        _items.removeWhere((value) => value.id == item.id);
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy.remove(item.id);
        _error = failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Blocked profiles')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _items.isEmpty
                ? _Retry(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _items.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 180),
                              Icon(
                                Icons.block_rounded,
                                size: 54,
                                color: SoulColors.muted,
                              ),
                              SizedBox(height: 14),
                              Center(child: Text('No blocked profiles')),
                            ],
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification.metrics.extentAfter < 300) {
                                _loadMore();
                              }
                              return false;
                            },
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(18, 10, 18, 30),
                              itemCount: _items.length +
                                  (_loadingMore && _nextCursor != null ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, index) {
                                if (index >= _items.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(18),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }
                                final item = _items[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: SoulColors.softSurface,
                                    foregroundImage:
                                        item.photoUrl == null ||
                                                item.photoUrl!.isEmpty
                                            ? null
                                            : NetworkImage(item.photoUrl!),
                                    child: item.photoUrl == null ||
                                            item.photoUrl!.isEmpty
                                        ? const Icon(Icons.person_rounded)
                                        : null,
                                  ),
                                  title: Text(item.firstName),
                                  trailing: TextButton(
                                    onPressed: _busy.contains(item.id)
                                        ? null
                                        : () => _unblock(item),
                                    child: const Text('Unblock'),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
      );
}

class DeviceSessionsScreen extends StatefulWidget {
  const DeviceSessionsScreen({
    super.key,
    required this.repository,
    required this.labels,
    required this.onSessionEnded,
  });

  final ProfileRepository repository;
  final BootstrapState labels;
  final VoidCallback onSessionEnded;

  @override
  State<DeviceSessionsScreen> createState() => _DeviceSessionsScreenState();
}

class _DeviceSessionsScreenState extends State<DeviceSessionsScreen> {
  List<DeviceSession> _sessions = const [];
  bool _loading = true;
  final Set<String> _busy = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sessions = await widget.repository.sessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
        _error = null;
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _revoke(DeviceSession session) async {
    setState(() => _busy.add(session.id));
    try {
      final current = await widget.repository.revokeSession(session.id);
      if (!mounted) return;
      if (current) {
        widget.onSessionEnded();
        return;
      }
      setState(() {
        _busy.remove(session.id);
        _sessions =
            _sessions.where((item) => item.id != session.id).toList();
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy.remove(session.id);
        _error = failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.labels.text('settings.devices', 'Active devices'),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _sessions.isEmpty
                ? _Retry(message: _error!, onRetry: _load)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                    itemCount: _sessions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final item = _sessions[index];
                      return ListTile(
                        leading: Icon(
                          item.isCurrent
                              ? Icons.smartphone_rounded
                              : Icons.devices_other_rounded,
                        ),
                        title: Text(item.deviceName),
                        subtitle: Text(
                          item.isCurrent ? 'This device' : 'Active session',
                        ),
                        trailing: TextButton(
                          onPressed: _busy.contains(item.id)
                              ? null
                              : () => _revoke(item),
                          child: Text(
                            item.isCurrent ? 'Sign out' : 'Revoke',
                          ),
                        ),
                      );
                    },
                  ),
      );
}

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({
    super.key,
    required this.repository,
    required this.labels,
    required this.onChanged,
  });

  final ProfileRepository repository;
  final BootstrapState labels;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final languages = labels.supportedLanguages
        .where((item) => item.isLaunchReady)
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(labels.text('settings.language', 'Language')),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        itemCount: languages.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final language = languages[index];
          final selected = language.code == labels.locale;
          return ListTile(
            onTap: () async {
              await repository.saveLocale(language.code);
              if (context.mounted) Navigator.of(context).pop();
              onChanged();
            },
            title: Text(language.nativeName),
            subtitle: language.nativeName == language.name
                ? null
                : Text(language.name),
            trailing: selected
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: SoulColors.forest,
                  )
                : null,
          );
        },
      ),
    );
  }
}

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({
    super.key,
    required this.repository,
    required this.labels,
  });

  final ProfileRepository repository;
  final BootstrapState labels;

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  List<DataExportState> _items = const [];
  bool _loading = true;
  bool _requesting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.repository.exports();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _request() async {
    setState(() => _requesting = true);
    try {
      await widget.repository.requestDataExport();
      await _load();
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.labels.text(
              'settings.download_data',
              'Download my data',
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                children: [
                  const Text(
                    'SOUL prepares a private export in the background. Completed exports expire for your security.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _requesting ? null : _request,
                    icon: const Icon(Icons.download_rounded),
                    label: Text(
                      _requesting ? 'Requesting…' : 'Request new export',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _InlineError(message: _error!),
                  ],
                  const SizedBox(height: 20),
                  for (final item in _items)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(item.status),
                        subtitle: Text(
                          item.downloadAvailable
                              ? 'Ready to download'
                              : 'Export is being prepared',
                        ),
                        trailing: item.downloadAvailable
                            ? const Icon(Icons.check_circle_outline_rounded)
                            : const Icon(Icons.schedule_rounded),
                      ),
                    ),
                ],
              ),
      );
}

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({
    super.key,
    required this.repository,
    required this.labels,
  });

  final ProfileRepository repository;
  final BootstrapState labels;

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  final InAppPurchase _store = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  List<SubscriptionProduct> _products = const [];
  Map<String, ProductDetails> _storeProducts = const {};
  Map<String, dynamic> _capabilities = const {};
  Set<String> _pendingProducts = const {};
  bool _loading = true;
  bool _storeAvailable = false;
  bool _restoring = false;
  String? _error;
  String? _storeMessage;

  String get _platform => defaultTargetPlatform == TargetPlatform.iOS
      ? 'ios'
      : 'android';

  @override
  void initState() {
    super.initState();
    _purchaseSubscription = _store.purchaseStream.listen(
      (purchases) => unawaited(_handlePurchases(purchases)),
      onError: (_) {
        if (mounted) {
          setState(() {
            _storeMessage = 'The store could not complete this request.';
            _pendingProducts = const {};
          });
        }
      },
    );
    _load();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait<Object>([
        widget.repository.subscriptionProducts(_platform),
        widget.repository.entitlements(_platform),
      ]);
      final products = values[0] as List<SubscriptionProduct>;
      final available = await _store.isAvailable();
      Map<String, ProductDetails> storeProducts = const {};
      String? storeMessage;

      if (available && products.isNotEmpty) {
        final response = await _store.queryProductDetails(
          products.map((item) => item.productId).toSet(),
        );
        storeProducts = {
          for (final detail in response.productDetails) detail.id: detail,
        };
        if (response.error != null) {
          storeMessage = response.error!.message;
        } else if (response.notFoundIDs.isNotEmpty) {
          storeMessage =
              'Some membership options are not configured in this store yet.';
        }
      }

      if (!mounted) return;
      setState(() {
        _products = products;
        _capabilities = values[1] as Map<String, dynamic>;
        _storeAvailable = available;
        _storeProducts = storeProducts;
        _storeMessage = storeMessage;
        _loading = false;
        _error = null;
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _buy(SubscriptionProduct product) async {
    final details = _storeProducts[product.productId];
    if (details == null) {
      setState(() => _storeMessage =
          'This membership is not available from your platform store right now.');
      return;
    }

    setState(() {
      _pendingProducts = {..._pendingProducts, product.productId};
      _storeMessage = null;
    });

    try {
      final started = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
      if (!started && mounted) {
        setState(() {
          _pendingProducts = {..._pendingProducts}..remove(product.productId);
          _storeMessage = 'The store did not start the purchase.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pendingProducts = {..._pendingProducts}..remove(product.productId);
        _storeMessage = 'The store could not start the purchase.';
      });
    }
  }

  Future<void> _restore() async {
    if (_restoring || !_storeAvailable) return;
    setState(() {
      _restoring = true;
      _storeMessage = null;
    });
    try {
      await _store.restorePurchases();
      if (mounted) {
        setState(() {
          _storeMessage =
              'Restore requested. SOUL will verify any store purchases returned.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _storeMessage = 'Purchases could not be restored.');
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        if (mounted) {
          setState(() {
            _pendingProducts = {..._pendingProducts, purchase.productID};
          });
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        if (mounted) {
          setState(() {
            _pendingProducts = {..._pendingProducts}
              ..remove(purchase.productID);
            _storeMessage = purchase.error?.message ??
                'The purchase was cancelled or could not be completed.';
          });
        }
        continue;
      }

      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        continue;
      }

      final receipt = _platform == 'ios'
          ? (purchase.purchaseID ?? '')
          : purchase.verificationData.serverVerificationData;
      if (receipt.isEmpty) {
        if (mounted) {
          setState(() {
            _pendingProducts = {..._pendingProducts}
              ..remove(purchase.productID);
            _storeMessage =
                'The store did not return a verifiable transaction.';
          });
        }
        continue;
      }

      try {
        final verified = await widget.repository.verifyPurchase(
          platform: _platform,
          productId: purchase.productID,
          receipt: receipt,
        );
        if (purchase.pendingCompletePurchase) {
          await _store.completePurchase(purchase);
        }
        final capabilities =
            await widget.repository.entitlements(_platform);
        if (!mounted) return;
        setState(() {
          _pendingProducts = {..._pendingProducts}
            ..remove(purchase.productID);
          _capabilities = capabilities;
          _storeMessage = verified.status == 'active'
              ? 'Membership is active on your SOUL account.'
              : 'The store transaction was verified.';
        });
      } on SoulApiFailure catch (failure) {
        if (!mounted) return;
        setState(() {
          _pendingProducts = {..._pendingProducts}
            ..remove(purchase.productID);
          _storeMessage = failure.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Membership')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _Retry(message: _error!, onRetry: _load)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: SoulColors.limeLight,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SOUL Membership',
                              style: TextStyle(
                                color: SoulColors.ink,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _capabilities.isEmpty
                                  ? 'Your account is using the standard feature set.'
                                  : 'Your current account capabilities are active.',
                            ),
                          ],
                        ),
                      ),
                      if (_storeMessage != null) ...[
                        const SizedBox(height: 14),
                        _InlineError(message: _storeMessage!),
                      ],
                      const SizedBox(height: 18),
                      for (final product in _products)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.planName,
                                  style: const TextStyle(
                                    color: SoulColors.ink,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (product.description != null &&
                                    product.description!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(product.description!),
                                ],
                                if (product.trialDays > 0) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '${product.trialDays}-day free trial',
                                    style: const TextStyle(
                                      color: SoulColors.forest,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                                if (_storeProducts[product.productId]
                                    case final details?) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    details.price,
                                    style: const TextStyle(
                                      color: SoulColors.ink,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: _pendingProducts
                                              .contains(product.productId)
                                          ? null
                                          : () => _buy(product),
                                      child: Text(
                                        _pendingProducts
                                                .contains(product.productId)
                                            ? 'Waiting for store…'
                                            : 'Continue with store',
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      if (_products.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No store products are available for this account and region right now.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed:
                            _storeAvailable && !_restoring ? _restore : null,
                        icon: const Icon(Icons.restore_rounded),
                        label: Text(
                          _restoring ? 'Restoring…' : 'Restore purchases',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Apple or Google processes payment. SOUL activates membership only after the server verifies the store transaction.',
                        style: TextStyle(
                          color: SoulColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
      );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                title,
                style: const TextStyle(
                  color: SoulColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    children[i],
                    if (i < children.length - 1)
                      const Divider(height: 1, indent: 58),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _ToggleGroup extends StatelessWidget {
  const _ToggleGroup({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => _SettingsSection(
        title: title,
        children: children,
      );
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(label),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 190),
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: SoulColors.muted),
          ),
        ),
      );
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: destructive
              ? Theme.of(context).colorScheme.error
              : SoulColors.ink,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: destructive
                ? Theme.of(context).colorScheme.error
                : SoulColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xffffeeee),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(message),
      );
}

class _Retry extends StatelessWidget {
  const _Retry({
    required this.message,
    required this.onRetry,
  });

  final String message;
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
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}
