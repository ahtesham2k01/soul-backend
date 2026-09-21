import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import 'onboarding_repository.dart';
import 'photo_onboarding_screen.dart';

class LegalSubmissionScreen extends StatefulWidget {
  const LegalSubmissionScreen({
    required this.repository,
    required this.labels,
    super.key,
  });

  final OnboardingRepository repository;
  final BootstrapState labels;

  @override
  State<LegalSubmissionScreen> createState() => _LegalSubmissionScreenState();
}

class LegalReconsentScreen extends StatefulWidget {
  const LegalReconsentScreen({
    required this.repository,
    required this.labels,
    required this.onAccepted,
    super.key,
  });
  final OnboardingRepository repository;
  final BootstrapState labels;
  final VoidCallback onAccepted;

  @override
  State<LegalReconsentScreen> createState() => _LegalReconsentScreenState();
}

class _LegalReconsentScreenState extends State<LegalReconsentScreen> {
  LegalConsentState? _legal;
  bool _agreed = false;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final legal = await widget.repository.legalConsent();
      if (mounted) setState(() { _legal = legal; _busy = false; _error = null; });
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() { _error = failure.message; _busy = false; });
    }
  }

  Future<void> _accept() async {
    final legal = _legal;
    if (legal == null || !_agreed) return;
    setState(() { _busy = true; _error = null; });
    try {
      await widget.repository.acceptLegal(legal.submissionPayload());
      widget.onAccepted();
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() { _error = failure.message; _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.labels.text('legal.outdated', 'Review required'),
          ),
        ),
        body: SafeArea(
          child: _busy && _legal == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      widget.labels.text(
                        'legal.consent_required',
                        'Review and accept the current policies to continue.',
                      ),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 18),
                    for (final key in (_legal?.commitmentKeys ?? widget.labels.commitmentKeys))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_circle_outline, color: SoulColors.forest),
                        title: Text(widget.labels.text(key, 'Follow SOUL community and safety rules.')),
                      ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _agreed,
                      onChanged: _busy ? null : (value) => setState(() => _agreed = value == true),
                      title: Text(
                        widget.labels.text(
                          'legal.commitment.policies',
                          'Accept the Terms and Privacy Policy',
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: !_agreed || _busy ? null : _accept,
                        child: Text(
                          widget.labels.text(
                            'legal.accept_current',
                            'Accept and continue',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      );
}

class _LegalSubmissionScreenState extends State<LegalSubmissionScreen> {
  LegalConsentState? _legal;
  ProfileLifecycle? _lifecycle;
  Timer? _poller;
  bool _accepted = false;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<Object>([
        widget.repository.legalConsent(),
        widget.repository.status(),
      ]);
      if (!mounted) return;
      final lifecycle = results[1] as ProfileLifecycle;
      setState(() {
        _legal = results[0] as LegalConsentState;
        _lifecycle = lifecycle;
        _busy = false;
      });
      _handleLifecycle(lifecycle);
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() { _error = failure.message; _busy = false; });
    }
  }

  Future<void> _submit() async {
    final legal = _legal;
    if (legal == null || !_accepted) return;
    setState(() { _busy = true; _error = null; });
    try {
      await widget.repository.submit(legal.submissionPayload());
      final lifecycle = await widget.repository.status();
      if (!mounted) return;
      setState(() {
        _lifecycle = lifecycle;
        _busy = false;
      });
      _handleLifecycle(lifecycle);
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() { _error = failure.message; _busy = false; });
    }
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 3), (_) => _refreshStatus());
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await widget.repository.status();
      if (!mounted) return;
      setState(() => _lifecycle = status);
      _handleLifecycle(status);
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    }
  }

  void _handleLifecycle(ProfileLifecycle lifecycle) {
    if (!mounted) return;
    if (lifecycle.live) {
      _poller?.cancel();
      Navigator.of(context).pop('home');
      return;
    }
    if (lifecycle.processing) {
      _startPolling();
    } else {
      _poller?.cancel();
    }
  }

  Future<void> _correctAndResubmit() async {
    final screen = _lifecycle?.correctionScreen;
    if (screen == 'onboarding.photos') {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PhotoOnboardingScreen(labels: widget.labels),
        ),
      );
      if (!mounted) return;
      setState(() { _busy = true; _error = null; });
      try {
        await widget.repository.resubmit();
        await _refreshStatus();
        _startPolling();
      } on SoulApiFailure catch (failure) {
        if (mounted) setState(() => _error = failure.message);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }
    Navigator.of(context).pop(screen ?? 'onboarding.profile');
  }

  @override
  Widget build(BuildContext context) {
    final lifecycle = _lifecycle;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.labels.text('onboarding.review', 'Review your profile'),
        ),
      ),
      body: SafeArea(
        child: _busy && _legal == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (lifecycle != null && lifecycle.status != 'draft')
                    _LifecycleCard(
                      labels: widget.labels,
                      lifecycle: lifecycle,
                      onCorrect: _correctAndResubmit,
                    ),
                  if (lifecycle == null || lifecycle.status == 'draft') ...[
                    Text(
                      widget.labels.text(
                        'legal.consent_required',
                        'Review and accept the current policies to continue.',
                      ),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 18),
                    for (final key in (_legal?.commitmentKeys.isNotEmpty == true
                        ? _legal!.commitmentKeys
                        : widget.labels.commitmentKeys))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_circle_outline, color: SoulColors.forest),
                        title: Text(widget.labels.text(key, _fallbackCommitment(key))),
                      ),
                    const Divider(height: 28),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _accepted,
                      onChanged: _busy ? null : (value) => setState(() => _accepted = value == true),
                      title: Text(
                        widget.labels.text(
                          'legal.commitment.policies',
                          'Accept the Terms and Privacy Policy',
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: !_accepted || _busy ? null : _submit,
                        child: Text(
                          widget.labels.text(
                            'onboarding.submit',
                            'Submit profile',
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    TextButton(
                      onPressed: _load,
                      child: Text(
                        widget.labels.text('common.retry', 'Try again'),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  String _fallbackCommitment(String key) => switch (key) {
        'legal.commitment.respect' => 'Treat every member with respect.',
        'legal.commitment.honesty' => 'Be honest about identity and relationship status.',
        'legal.commitment.no_abuse' => 'No harassment, scams or inappropriate behaviour.',
        'legal.commitment.guidelines' => 'Follow the Community Guidelines.',
        _ => 'Accept the Terms and Privacy Policy.',
      };
}

class _LifecycleCard extends StatelessWidget {
  const _LifecycleCard({
    required this.labels,
    required this.lifecycle,
    required this.onCorrect,
  });
  final BootstrapState labels;
  final ProfileLifecycle lifecycle;
  final VoidCallback onCorrect;

  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = switch (lifecycle.status) {
      'live' => (
          Icons.verified,
          labels.text('onboarding.profile_live', 'Your profile is live'),
          '',
        ),
      'changes_required' => (
          Icons.edit_note,
          labels.text('onboarding.changes_required', 'Changes are required'),
          lifecycle.reason ?? '',
        ),
      'paused' => (Icons.pause_circle_outline, 'Profile paused', lifecycle.reason ?? 'Your profile is temporarily hidden.'),
      _ => (
          Icons.hourglass_top,
          labels.text('onboarding.checking', 'We are checking your profile'),
          '',
        ),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(children: [
          Icon(icon, size: 52, color: SoulColors.forest),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center),
          if (lifecycle.correctable) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: onCorrect, child: const Text('Fix now')),
          ],
        ]),
      ),
    );
  }
}
