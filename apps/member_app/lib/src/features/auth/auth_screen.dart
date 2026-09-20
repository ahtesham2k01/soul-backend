import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import '../onboarding/onboarding_screen.dart';
import 'auth_repository.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    required this.labels,
    required this.registration,
    super.key,
  });

  final BootstrapState labels;
  final bool registration;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  OtpChallenge? _challenge;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = _email.text.trim();
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
        throw const SoulApiFailure(
          statusCode: 422,
          code: 'INVALID_EMAIL',
          message: 'Enter a valid email address.',
        );
      }
      final repository = ref.read(authRepositoryProvider);
      _challenge = widget.registration
          ? await repository.requestRegistrationOtp(email)
          : await repository.requestLoginOtp(email);
      if (mounted) setState(() {});
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode() async {
    final challenge = _challenge;
    if (challenge == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repository = ref.read(authRepositoryProvider);
      final next = widget.registration
          ? await repository.verifyRegistrationOtp(
              challenge: challenge,
              code: _code.text.trim(),
              deviceName: 'SOUL mobile app',
            )
          : await repository.verifyLoginOtp(
              challenge: challenge,
              code: _code.text.trim(),
              deviceName: 'SOUL mobile app',
            );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => next == 'onboarding'
              ? OnboardingScreen(labels: widget.labels)
              : _SignedInScreen(nextStep: next),
        ),
      );
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const Icon(Icons.info_outline),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      Text(
                        _challenge == null
                            ? "What's your email address?"
                            : 'Enter Your OTP',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _challenge == null
                            ? "We'll email you a code to verify your identity"
                            : 'Enter the code sent to ${_email.text.trim()}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 30),
                      if (_challenge == null)
                        const Text('Email', style: TextStyle(color: SoulColors.ink, fontSize: 13)),
                      if (_challenge == null) const SizedBox(height: 6),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: !_busy && _challenge == null,
                  decoration: const InputDecoration(hintText: 'example@gmail.com'),
                ),
                if (_challenge != null) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: 6,
                    decoration: const InputDecoration(hintText: '6-digit code'),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _busy
                              ? null
                              : (_challenge == null ? _requestCode : _verifyCode),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SoulColors.lime,
                            foregroundColor: SoulColors.ink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _busy
                                ? 'Please wait…'
                                : (_challenge == null ? labels.text('common.continue', 'Continue') : 'Verify Code'),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'By continuing you agree to our Terms and\nPrivacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: SoulColors.ink, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignedInScreen extends StatelessWidget {
  const _SignedInScreen({required this.nextStep});

  final String nextStep;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('SOUL')),
        body: Center(
          child: Text(nextStep == 'onboarding' ? 'Your onboarding will continue here.' : 'Your SOUL home will appear here.'),
        ),
      );
}
