import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/api_client.dart';
import '../../core/soul_design.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import '../onboarding/onboarding_repository.dart';
import 'auth_input_validation.dart';
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
  final _nameFocus = FocusNode();
  final _dobFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _codeFocus = FocusNode();
  OtpChallenge? _challenge;
  String? _error;
  bool _busy = false;
  Timer? _resendTimer;
  int _resendSeconds = 0;
  int _registrationStep = 0;

  @override
  void dispose() {
    _name.dispose();
    _dob.dispose();
    _email.dispose();
    _code.dispose();
    _nameFocus.dispose();
    _dobFocus.dispose();
    _emailFocus.dispose();
    _codeFocus.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _focusCurrentField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_challenge != null) {
        _codeFocus.requestFocus();
      } else if (!widget.registration || _registrationStep == 2) {
        _emailFocus.requestFocus();
      } else if (_registrationStep == 0) {
        _nameFocus.requestFocus();
      } else {
        _dobFocus.requestFocus();
      }
    });
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendSeconds = 30;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  void _back() {
    if (_busy) return;
    if (_challenge != null) {
      setState(() {
        _challenge = null;
        _code.clear();
        _error = null;
        _resendSeconds = 0;
      });
      _resendTimer?.cancel();
      _focusCurrentField();
      return;
    }
    if (widget.registration && _registrationStep > 0) {
      setState(() {
        _registrationStep--;
        _error = null;
      });
      _focusCurrentField();
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
      _focusCurrentField();
      return;
    }
    await _requestCode();
  }

  String? _registrationValidation() {
    if (_registrationStep == 0) {
      final name = _name.text.trim();
      if (name.isEmpty || name.length > 80) {
        return widget.labels.text(
          'auth.validation_name',
          'Enter your first name.',
        );
      }
    }
    if (_registrationStep == 1 && _normalizedDob(_dob.text.trim()) == null) {
      return widget.labels.text('auth.validation_dob', 'Enter a valid date of birth. You must be 18 or older.');
    }
    return null;
  }

  String? _normalizedDob(String input) => normalizeAdultDateOfBirth(input);


  Future<void> _requestCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = _email.text.trim();
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
        throw SoulApiFailure(
          statusCode: 422,
          code: 'INVALID_EMAIL',
          message: widget.labels.text('auth.validation_email', 'Enter a valid email address.'),
        );
      }
      final repository = ref.read(authRepositoryProvider);
      _challenge = widget.registration
          ? await repository.requestRegistrationOtp(email)
          : await repository.requestLoginOtp(email);
      if (mounted) {
        _code.clear();
        _startResendCooldown();
        setState(() {});
        _focusCurrentField();
      }
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode() async {
    final challenge = _challenge;
    if (challenge == null) return;
    if (_code.text.trim().length != 6) {
      setState(() => _error = widget.labels.text(
            'auth.enter_code',
            'Enter the verification code.',
          ));
      _codeFocus.requestFocus();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    var authenticationCompleted = false;

    try {
      final repository = ref.read(authRepositoryProvider);
      if (widget.registration) {
        await repository.verifyRegistrationOtp(
          challenge: challenge,
          code: _code.text.trim(),
          deviceName: 'SOUL mobile app',
          locale: widget.labels.locale,
        );
        authenticationCompleted = true;

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
        authenticationCompleted = true;
      }

      _routeAfterAuthentication();
    } on SoulApiFailure catch (failure) {
      if (authenticationCompleted) {
        // The OTP has already been consumed and the session was issued.
        // Re-resolve the saved session instead of trapping the member on an
        // OTP screen that can no longer be submitted successfully.
        _routeAfterAuthentication();
        return;
      }

      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _routeAfterAuthentication() {
    if (!mounted) return;
    ref.invalidate(sessionRouteProvider);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }


  String _title() {
    if (_challenge != null) {
      return widget.labels.text(
        'auth.enter_code',
        'Enter the verification code',
      );
    }
    if (!widget.registration || _registrationStep == 2) {
      return widget.labels.text('auth.email', 'Email');
    }
    if (_registrationStep == 0) {
      return widget.labels.text('profile.first_name', 'First name');
    }
    return widget.labels.text('profile.date_of_birth', 'Date of birth');
  }

  String _subtitle() {
    if (_challenge != null) {
      return widget.labels.format('auth.otp_sent_to', 'Enter the code we sent to {email}.', {'email': _email.text.trim()});
    }
    if (widget.registration && _registrationStep == 0) {
      return widget.labels.text(
        'auth.validation_name',
        'Enter your first name.',
      );
    }
    if (widget.registration && _registrationStep == 1) {
      return widget.labels.text(
        'auth.validation_dob',
        'Enter a valid date of birth. You must be 18 or older.',
      );
    }
    return widget.labels.text('auth.email_code_help', 'We’ll email you a code to verify your identity.');
  }

  Widget _fields() {
    if (_challenge != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('auth-otp-field'),
            controller: _code,
            focusNode: _codeFocus,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            onSubmitted: (_) {
              if (!_busy) _verifyCode();
            },
            onChanged: (value) {
              if (_error != null) setState(() => _error = null);
              if (value.length == 6 && !_busy) _verifyCode();
            },
            decoration: InputDecoration(
              hintText: widget.labels.text('auth.otp_hint', '6-digit code'),
              prefixIcon: const Icon(Icons.password_rounded),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const ValueKey('auth-resend-code'),
              onPressed: _busy || _resendSeconds > 0 ? null : _requestCode,
              child: Text(
                _resendSeconds > 0
                    ? '${widget.labels.text('common.retry', 'Try again')} (${_resendSeconds}s)'
                    : widget.labels.text('common.retry', 'Try again'),
              ),
            ),
          ),
        ],
      );
    }

    if (!widget.registration || _registrationStep == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.labels.text('auth.email', 'Email'),
            style: const TextStyle(color: SoulColors.ink, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _email,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) {
              if (!_busy) _continue();
            },
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              hintText: widget.labels.text('auth.email_hint', 'example@gmail.com'),
              prefixIcon: const Icon(Icons.mail_outline_rounded),
            ),
          ),
        ],
      );
    }

    if (_registrationStep == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.labels.text('profile.first_name', 'First name'),
            style: const TextStyle(color: SoulColors.ink, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            focusNode: _nameFocus,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            onSubmitted: (_) {
              if (!_busy) _continue();
            },
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(hintText: widget.labels.text('auth.name_hint', 'Your name')),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labels.text('profile.date_of_birth', 'Date of birth'),
          style: const TextStyle(color: SoulColors.ink, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _dob,
          focusNode: _dobFocus,
          keyboardType: TextInputType.datetime,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.birthday],
          onSubmitted: (_) {
            if (!_busy) _continue();
          },
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          decoration: InputDecoration(
            hintText: widget.labels.text('auth.dob_hint', 'DD/MM/YYYY'),
          ),
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
      footer: SoulPrimaryButton(
        label: labels.text('common.continue', 'Continue'),
        onPressed: _busy ? null : _continue,
        busy: _busy,
      ),
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
            Semantics(
              liveRegion: true,
              container: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            labels.text(
              'legal.commitment.policies',
              'Accept the Terms and Privacy Policy',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: SoulColors.muted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
