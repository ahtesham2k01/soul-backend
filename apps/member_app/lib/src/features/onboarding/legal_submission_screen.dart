import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/soul_design.dart';
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
  State<LegalSubmissionScreen> createState() =>
      _LegalSubmissionScreenState();
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
  State<LegalReconsentScreen> createState() =>
      _LegalReconsentScreenState();
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
      if (!mounted) return;
      setState(() {
        _legal = legal;
        _busy = false;
        _error = null;
      });
    } on SoulApiFailure catch (failure) {
      if (mounted) {
        setState(() {
          _error = failure.message;
          _busy = false;
        });
      }
    }
  }

  Future<void> _accept() async {
    final legal = _legal;
    if (legal == null || !_agreed) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.acceptLegal(legal.submissionPayload());
      widget.onAccepted();
    } on SoulApiFailure catch (failure) {
      if (mounted) {
        setState(() {
          _error = failure.message;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 7, 16, 0),
                child: SoulTopBar(
                  title: 'Updated policies',
                  onBack: () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: _busy && _legal == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        children: [
                          const SoulPageTitle(
                            'Review before continuing',
                            subtitle:
                                'One or more legal documents changed. Your profile remains safe while you review them.',
                          ),
                          const SizedBox(height: 18),
                          for (final key in (_legal?.commitmentKeys ??
                              widget.labels.commitmentKeys))
                            _PromiseRow(
                              text: widget.labels.text(
                                key,
                                'Follow SOUL community and safety rules.',
                              ),
                            ),
                          const SizedBox(height: 10),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _agreed,
                            onChanged: _busy
                                ? null
                                : (value) =>
                                    setState(() => _agreed = value == true),
                            title: const Text(
                              'I accept the current Terms, Privacy Policy, Community Guidelines and commitments.',
                              style: TextStyle(
                                color: SoulColors.ink,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  10,
                  24,
                  18 + MediaQuery.paddingOf(context).bottom * .35,
                ),
                child: SoulPrimaryButton(
                  label: 'Accept and continue',
                  busy: _busy,
                  onPressed: _agreed ? _accept : null,
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
      setState(() {
        _legal = results[0] as LegalConsentState;
        _lifecycle = results[1] as ProfileLifecycle;
        _busy = false;
      });
      if (_lifecycle!.processing) _startPolling();
    } on SoulApiFailure catch (failure) {
      if (mounted) {
        setState(() {
          _error = failure.message;
          _busy = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final legal = _legal;
    if (legal == null || !_accepted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.submit(legal.submissionPayload());
      _lifecycle = await widget.repository.status();
      if (!mounted) return;
      setState(() => _busy = false);
      _startPolling();
    } on SoulApiFailure catch (failure) {
      if (mounted) {
        setState(() {
          _error = failure.message;
          _busy = false;
        });
      }
    }
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshStatus(),
    );
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
        MaterialPageRoute<void>(
          builder: (_) => const PhotoOnboardingScreen(),
        ),
      );
      if (!mounted) return;

      setState(() {
        _busy = true;
        _error = null;
      });
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _busy && _legal == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 7, 16, 0),
                    child: SoulTopBar(
                      onBack: () => Navigator.of(context).maybePop(),
                      onInfo: _showInfo,
                    ),
                  ),
                  Expanded(
                    child: lifecycle != null &&
                            lifecycle.status != 'draft'
                        ? _LifecycleView(
                            lifecycle: lifecycle,
                            error: _error,
                            busy: _busy,
                            onCorrect: _correctAndResubmit,
                            onRetry: _load,
                          )
                        : _commitmentView(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _commitmentView() {
    final commitments = _legal?.commitmentKeys.isNotEmpty == true
        ? _legal!.commitmentKeys
        : widget.labels.commitmentKeys;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            children: [
              const SoulPageTitle(
                'I promise to:',
                subtitle:
                    'These commitments help keep SOUL respectful, honest and safe.',
              ),
              const SizedBox(height: 20),
              for (final key in commitments)
                _PromiseRow(
                  text: widget.labels.text(
                    key,
                    _fallbackCommitment(key),
                  ),
                ),
              const SizedBox(height: 10),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _accepted,
                onChanged: _busy
                    ? null
                    : (value) =>
                        setState(() => _accepted = value == true),
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'I agree that serious or repeated violations can lead to my account being restricted or blocked.',
                  style: TextStyle(
                    color: SoulColors.ink,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            10,
            24,
            18 + MediaQuery.paddingOf(context).bottom * .35,
          ),
          child: Column(
            children: [
              SoulPrimaryButton(
                label: 'Accept & Finish',
                busy: _busy,
                onPressed: _accepted ? _submit : null,
              ),
              const SizedBox(height: 12),
              const Text(
                'By continuing you agree to our Terms and Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SoulColors.muted,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showInfo() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Text(
            'SOUL reviews submitted profiles before they become discoverable. Your profile remains hidden while required checks are running.',
            style: TextStyle(
              color: SoulColors.ink,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }

  String _fallbackCommitment(String key) => switch (key) {
        'legal.commitment.respect' =>
          'Treat everyone with respect.',
        'legal.commitment.honesty' =>
          'Be honest about your identity and relationship status.',
        'legal.commitment.no_abuse' =>
          'Do not harass, scam or behave inappropriately.',
        'legal.commitment.guidelines' =>
          'Follow the SOUL Community Guidelines.',
        _ => 'Follow the SOUL community and safety rules.',
      };
}

class _PromiseRow extends StatelessWidget {
  const _PromiseRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 13,
              backgroundColor: SoulColors.limeLight,
              child: Icon(
                Icons.check_rounded,
                size: 16,
                color: SoulColors.ink,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: SoulColors.ink,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
}

class _LifecycleView extends StatelessWidget {
  const _LifecycleView({
    required this.lifecycle,
    required this.error,
    required this.busy,
    required this.onCorrect,
    required this.onRetry,
  });

  final ProfileLifecycle lifecycle;
  final String? error;
  final bool busy;
  final VoidCallback onCorrect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final processing = lifecycle.processing;
    final live = lifecycle.live;
    final correctable = lifecycle.correctable;

    final icon = live
        ? Icons.favorite_rounded
        : correctable
            ? Icons.edit_note_rounded
            : processing
                ? Icons.hourglass_top_rounded
                : Icons.pause_circle_outline_rounded;

    final title = live
        ? 'Congratulations'
        : correctable
            ? 'A correction is needed'
            : processing
                ? "We're reviewing your profile"
                : 'Profile paused';

    final body = live
        ? 'Your profile has been approved and can now be shown to compatible people.'
        : correctable
            ? (lifecycle.reason ??
                'Please update the highlighted information and resubmit.')
            : processing
                ? 'Your verification status will appear here. Your profile stays hidden until the required checks finish.'
                : (lifecycle.reason ??
                    'Your profile is temporarily hidden.');

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 58, 24, 30),
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: SoulColors.limeLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 46,
              color: SoulColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SoulColors.ink,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SoulColors.muted,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (correctable)
          SoulPrimaryButton(
            label: 'Fix now',
            busy: busy,
            onPressed: onCorrect,
          )
        else if (error != null)
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          )
        else if (live)
          SoulPrimaryButton(
            label: 'Continue',
            onPressed: () => Navigator.of(context).pop('complete'),
          )
        else
          const Center(
            child: CircularProgressIndicator(
              color: SoulColors.limeLight,
            ),
          ),
      ],
    );
  }
}
