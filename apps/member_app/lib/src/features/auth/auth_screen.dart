import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/api_client.dart';
import '../bootstrap/bootstrap_repository.dart';
import 'auth_repository.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({required this.labels, super.key});

  final BootstrapState labels;

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
      _challenge = await ref.read(authRepositoryProvider).requestLoginOtp(_email.text.trim());
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
      final next = await ref.read(authRepositoryProvider).verifyLoginOtp(
            challenge: challenge,
            code: _code.text.trim(),
            deviceName: 'SOUL mobile app',
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => _SignedInScreen(nextStep: next)),
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
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 48),
                const Text('SOUL', textAlign: TextAlign.center, style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text('Meaningful connections, at your pace.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 44),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: !_busy && _challenge == null,
                  decoration: const InputDecoration(labelText: 'Email address', border: OutlineInputBorder()),
                ),
                if (_challenge != null) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: 6,
                    decoration: const InputDecoration(labelText: 'Verification code', border: OutlineInputBorder()),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : (_challenge == null ? _requestCode : _verifyCode),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(_challenge == null ? labels.text('auth.continue_with_email', 'Continue with Email') : 'Verify and continue'),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(onPressed: null, child: Text(labels.text('auth.continue_with_google', 'Continue with Google'))),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: null, child: Text(labels.text('auth.continue_with_apple', 'Continue with Apple'))),
                const SizedBox(height: 24),
                TextButton(onPressed: () {}, child: Text(labels.text('auth.create_account', 'Create account'))),
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
