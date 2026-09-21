import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/api_client.dart';
import '../../core/soul_design.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import '../onboarding/onboarding_repository.dart';
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
  final _name = TextEditingController();
  final _dob = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  OtpChallenge? _challenge;
  String? _error;
  bool _busy = false;
  int _registrationStep = 0;

  @override
  void dispose() {
    _name.dispose();
    _dob.dispose();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  void _back() {
    if (_busy) return;
    if (_challenge != null) {
      setState(() {
        _challenge = null;
        _code.clear();
        _error = null;
      });
      return;
    }
    if (widget.registration && _registrationStep > 0) {
      setState(() {
        _registrationStep--;
        _error = null;
      });
      return;
    }
    Navigator.of(context).maybePop();
  }

  Future<void> _continue() async {
    if (_challenge != null) {
      await _verifyCode();
      return;
    }
    if (widget.registration && _registrationStep < 2) {
      final error = _registrationValidation();
      if (error != null) {
        setState(() => _error = error);
        return;
      }
      setState(() {
        _registrationStep++;
        _error = null;
      });
      return;
    }
    await _requestCode();
  }

  String? _registrationValidation() {
    if (_registrationStep == 0 && _name.text.trim().length < 2) {
      return 'Enter your full name.';
    }
    if (_registrationStep == 1 && _normalizedDob(_dob.text.trim()) == null) {
      return 'Enter a valid date of birth. You must be 18 or older.';
    }
    return null;
  }

  String? _normalizedDob(String input) {
    DateTime? value;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(input)) {
      value = DateTime.tryParse(input);
    } else {
      final match =
          RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(input);
      if (match != null) {
        final day = int.tryParse(match.group(1)!);
        final month = int.tryParse(match.group(2)!);
        final year = int.tryParse(match.group(3)!);
        if (day != null && month != null && year != null) {
          final candidate = DateTime(year, month, day);
          if (candidate.year == year &&
              candidate.month == month &&
              candidate.day == day) {
            value = candidate;
          }
        }
      }
    }
    if (value == null) return null;
    final today = DateTime.now();
    var age = today.year - value.year;
    if (today.month < value.month ||
        (today.month == value.month && today.day < value.day)) {
      age--;
    }
    if (age < 18 || age > 120) return null;
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
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
      if (widget.registration) {
        await repository.verifyRegistrationOtp(
              challenge: challenge,
              code: _code.text.trim(),
              deviceName: 'SOUL mobile app',
              locale: widget.labels.locale,
            );
        final dob = _normalizedDob(_dob.text.trim());
        if (dob != null) {
          await OnboardingRepository(ref.read(apiClientProvider)).saveProfile({
            'first_name': _name.text.trim(),
            'date_of_birth': dob,
          });
        }
      } else {
        await repository.verifyLoginOtp(
              challenge: challenge,
              code: _code.text.trim(),
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


  String _title() {
    if (_challenge != null) return 'Enter Your OTP';
    if (!widget.registration || _registrationStep == 2) {
      return 'What’s your email address?';
    }
    if (_registrationStep == 0) return 'What should we call you?';
    return 'What’s your DOB ?';
  }

  String _subtitle() {
    if (_challenge != null) {
      return 'Enter the Code that we have sent to\n${_email.text.trim()}';
    }
    return 'We’ll email you a code to verify your identity';
  }

  Widget _fields() {
    if (_challenge != null) {
      return TextField(
        controller: _code,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        maxLength: 6,
        decoration: const InputDecoration(hintText: '6-digit code'),
      );
    }

    if (!widget.registration || _registrationStep == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Email',
            style: TextStyle(color: SoulColors.ink, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              hintText: 'example@gmail.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
        ],
      );
    }

    if (_registrationStep == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Full Name',
            style: TextStyle(color: SoulColors.ink, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(hintText: 'Your name'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DOB',
          style: TextStyle(color: SoulColors.ink, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _dob,
          keyboardType: TextInputType.datetime,
          decoration: const InputDecoration(hintText: 'DD/MM/YYYY'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final progress = _challenge != null
        ? 1.0
        : widget.registration
            ? (_registrationStep + 1) / 3
            : .5;

    return SoulStepScaffold(
      progress: progress,
      onBack: _back,
      child: ListView(
        children: [
          SoulPageTitle(
            _title(),
            subtitle: _subtitle(),
          ),
          const SizedBox(height: 30),
          _fields(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'By continuing you agree to our Terms and Privacy Policy',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: SoulColors.muted,
              height: 1.45,
            ),
          ),
        ],
      ),
      footer: SoulPrimaryButton(
        label: _challenge == null
            ? labels.text('common.continue', 'Continue')
            : 'Verify Code',
        onPressed: _busy ? null : _continue,
        busy: _busy,
      ),
    );
  }
}
