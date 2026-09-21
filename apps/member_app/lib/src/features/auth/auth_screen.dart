import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/api_client.dart';
import '../../core/soul_design.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
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

    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repository = ref.read(authRepositoryProvider);
      if (widget.registration) {
        await repository.verifyRegistrationOtp(
          challenge: challenge,
          code: code,
          deviceName: 'SOUL mobile app',
          locale: widget.labels.locale,
        );
      } else {
        await repository.verifyLoginOtp(
          challenge: challenge,
          code: code,
          deviceName: 'SOUL mobile app',
          locale: widget.labels.locale,
        );
      }
      if (!mounted) return;
      ref.invalidate(sessionRouteProvider);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _challenge;

    return SoulStepScaffold(
      progress: challenge == null ? .38 : .68,
      onBack: () => Navigator.of(context).maybePop(),
      onInfo: _showInfo,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SoulPrimaryButton(
            label: challenge == null
                ? widget.labels.text('common.continue', 'Continue')
                : 'Verify Code',
            busy: _busy,
            onPressed: challenge == null ? _requestCode : _verifyCode,
          ),
          if (challenge == null) ...[
            const SizedBox(height: 17),
            const Text(
              'By continuing you agree to our Terms and',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SoulColors.ink,
                fontSize: 10.5,
              ),
            ),
            const Text(
              'Privacy Policy',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SoulColors.ink,
                fontSize: 10.5,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy ? null : _requestCode,
              child: const Text(
                'Resend Code',
                style: TextStyle(
                  color: SoulColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SoulPageTitle(
            challenge == null
                ? "What's your email address?"
                : 'Enter Your OTP',
            subtitle: challenge == null
                ? "We'll email you a code to verify your identity"
                : 'Enter the code that we have sent to\n${_email.text.trim()}',
          ),
          const SizedBox(height: 27),
          if (challenge == null) ...[
            const Text(
              'Email',
              style: TextStyle(
                color: SoulColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              enabled: !_busy,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _requestCode(),
              decoration: const InputDecoration(
                hintText: 'example@gmail.com',
              ),
            ),
          ] else
            _OtpBoxes(
              controller: _code,
              enabled: !_busy,
              onComplete: _verifyCode,
            ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xfffff0f0),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
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
            'SOUL uses one-time codes to verify that you control the email address on your account.',
            style: TextStyle(
              color: SoulColors.ink,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpBoxes extends StatefulWidget {
  const _OtpBoxes({
    required this.controller,
    required this.enabled,
    required this.onComplete,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onComplete;

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
    if (widget.controller.text.length == 6) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: widget.enabled ? () => _focus.requestFocus() : null,
        child: Stack(
          children: [
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 1,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: 6,
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),
            ),
            Row(
              children: List.generate(6, (index) {
                final text = widget.controller.text;
                final value = index < text.length ? text[index] : '';
                return Expanded(
                  child: Container(
                    height: 50,
                    margin: EdgeInsets.only(right: index == 5 ? 0 : 7),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: index == text.length && text.length < 6
                            ? SoulColors.limeLight
                            : SoulColors.line,
                      ),
                    ),
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: SoulColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
}
