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
        appBar: AppBar(title: const Text('Updated policies')),
        body: SafeArea(
          child: _busy && _legal == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text('Review before continuing', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 10),
                    const Text('One or more legal documents changed. Your profile remains safe while you review them.'),
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
                      title: const Text('I accept the current Terms, Privacy Policy, Community Guidelines and commitments.'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: FilledButton(onPressed: !_agreed || _busy ? null : _accept, child: Text(_busy ? 'Saving…' : 'Accept and continue')),
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
      setState(() {
        _legal = results[0] as LegalConsentState;
        _lifecycle = results[1] as ProfileLifecycle;
        _busy = false;
      });
      if (_lifecycle!.processing) _startPolling();
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
      _lifecycle = await widget.repository.status();
      if (!mounted) return;
      setState(() => _busy = false);
      _startPolling();
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
      if (!status.processing) _poller?.cancel();
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    }
  }

  Future<void> _correctAndResubmit() async {
    final screen = _lifecycle?.correctionScreen;
    if (screen == 'onboarding.photos') {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const PhotoOnboardingScreen()),
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
      appBar: AppBar(title: const Text('Complete your profile')),
      body: SafeArea(
        child: _busy && _legal == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (lifecycle != null && lifecycle.status != 'draft')
                    _LifecycleCard(lifecycle: lifecycle, onCorrect: _correctAndResubmit),
                  if (lifecycle == null || lifecycle.status == 'draft') ...[
                    Text('Our community commitments', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 10),
                    const Text('Please review these promises before your profile is submitted.'),
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
                      title: const Text('I accept the current Terms, Privacy Policy, Community Guidelines and community commitments.'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: !_accepted || _busy ? null : _submit,
                        child: Text(_busy ? 'Submitting…' : 'Submit profile'),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    TextButton(onPressed: _load, child: const Text('Retry')),
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
  const _LifecycleCard({required this.lifecycle, required this.onCorrect});
  final ProfileLifecycle lifecycle;
  final VoidCallback onCorrect;

  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = switch (lifecycle.status) {
      'live' => (Icons.verified, 'Your profile is live', 'You can now start discovering compatible people.'),
      'changes_required' => (Icons.edit_note, 'A correction is needed', lifecycle.reason ?? 'Please update the highlighted information.'),
      'paused' => (Icons.pause_circle_outline, 'Profile paused', lifecycle.reason ?? 'Your profile is temporarily hidden.'),
      _ => (Icons.hourglass_top, 'Profile checks in progress', 'Your profile is hidden until automated safety checks finish.'),
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
