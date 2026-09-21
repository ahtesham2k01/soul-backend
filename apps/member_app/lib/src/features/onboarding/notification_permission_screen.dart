import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/api_client.dart';
import '../../core/soul_design.dart';
import '../bootstrap/bootstrap_repository.dart';
import '../profile/profile_repository.dart';

class NotificationPermissionScreen extends ConsumerStatefulWidget {
  const NotificationPermissionScreen({
    required this.labels,
    super.key,
  });

  final BootstrapState labels;

  @override
  ConsumerState<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends ConsumerState<NotificationPermissionScreen> {
  NotificationSettings? _settings;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings =
          await ref.read(profileRepositoryProvider).notifications();
      if (!mounted) return;
      setState(() {
        _settings = settings;
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

  Future<void> _allow() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final settings = _settings;
      if (settings != null) {
        await ref
            .read(profileRepositoryProvider)
            .saveNotifications(settings);
      }

      await ref
          .read(pushRegistrationServiceProvider)
          .requestPermissionAndSynchronize();

      if (mounted) Navigator.of(context).pop(true);
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = failure.message;
      });
    }
  }

  void _notNow() {
    if (_busy) return;
    Navigator.of(context).pop(false);
  }

  void _change(NotificationSettings Function(NotificationSettings) update) {
    final current = _settings;
    if (current == null) return;
    setState(() => _settings = update(current));
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final settings = _settings;

    return SoulStepScaffold(
      progress: 1,
      onBack: _notNow,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SoulPrimaryButton(
            label: labels.text(
              'notifications.allow',
              'Allow notifications',
            ),
            onPressed: _loading || _busy ? null : _allow,
            busy: _busy,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : _notNow,
            child: Text(
              labels.text('common.not_now', 'Not now'),
            ),
          ),
        ],
      ),
      child: ListView(
        children: [
          SoulPageTitle(
            labels.text('notifications.title', 'Notifications'),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (settings != null) ...[
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  labels.text(
                    'notifications.new_matches',
                    'New matches',
                  ),
                ),
                value: settings.pushNewMatches,
                onChanged: _busy
                    ? null
                    : (value) => _change(
                          (current) =>
                              current.copyWith(pushNewMatches: value),
                        ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  labels.text(
                    'notifications.new_messages',
                    'New messages',
                  ),
                ),
                value: settings.pushNewMessages,
                onChanged: _busy
                    ? null
                    : (value) => _change(
                          (current) =>
                              current.copyWith(pushNewMessages: value),
                        ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  labels.text('notifications.safety', 'Safety updates'),
                ),
                value: true,
                onChanged: null,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  labels.text('notifications.marketing', 'Marketing'),
                ),
                value: settings.pushMarketing,
                onChanged: _busy
                    ? null
                    : (value) => _change(
                          (current) =>
                              current.copyWith(pushMarketing: value),
                        ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              TextButton(
                onPressed: _busy ? null : _load,
                child: Text(
                  labels.text('common.retry', 'Try again'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
