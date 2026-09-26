import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/api_client.dart';
import '../../prototype/uploaded_onboarding/uploaded_welcome_screen.dart';
import '../auth/auth_screen.dart';
import '../auth/native_identity_service.dart';
import '../bootstrap/bootstrap_repository.dart';

/// Connects the owner-approved Feature 1 visuals to production actions.
class WelcomeFlow extends ConsumerStatefulWidget {
  const WelcomeFlow({required this.labels, super.key});

  final BootstrapState labels;

  @override
  ConsumerState<WelcomeFlow> createState() => _WelcomeFlowState();
}

class _WelcomeFlowState extends ConsumerState<WelcomeFlow> {
  String? _socialProvider;
  bool _languageBusy = false;

  String? get _locationLabel {
    final location = widget.labels.location;
    if (location == null || location.city.trim().isEmpty) return null;
    final country = location.countryCode.trim();
    return country.isEmpty ? location.city : '${location.city}, $country';
  }

  void _openEmail({required bool registration}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthScreen(
          labels: widget.labels,
          registration: registration,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _socialSignIn({required bool apple}) async {
    if (_socialProvider != null) return;
    setState(() => _socialProvider = apple ? 'apple' : 'google');
    try {
      final native = ref.read(nativeIdentityProvider);
      final auth = ref.read(authRepositoryProvider);
      if (apple) {
        final credential = await native.apple();
        await auth.signInWithApple(
          identityToken: credential.identityToken,
          rawNonce: credential.rawNonce,
          deviceName: 'SOUL mobile app',
          locale: widget.labels.locale,
          givenName: credential.givenName,
          familyName: credential.familyName,
        );
      } else {
        final credential = await native.google();
        await auth.signInWithGoogle(
          idToken: credential.idToken,
          deviceName: 'SOUL mobile app',
          locale: widget.labels.locale,
        );
      }
      ref.invalidate(sessionRouteProvider);
    } on NativeIdentityCancelled {
      // Closing the provider-owned sheet is an intentional cancellation.
    } on SoulApiFailure catch (failure) {
      _showMessage(failure.message);
    } catch (_) {
      _showMessage(
        apple
            ? widget.labels.text(
                'auth.error.apple_failed',
                'Apple sign-in could not be completed. Please try again.',
              )
            : widget.labels.text(
                'auth.error.google_failed',
                'Google sign-in could not be completed. Please try again.',
              ),
      );
    } finally {
      if (mounted) setState(() => _socialProvider = null);
    }
  }

  Future<void> _useOpeningLanguage(String code) async {
    if (code == widget.labels.locale || _languageBusy) return;
    setState(() => _languageBusy = true);
    try {
      await ref.read(sessionStoreProvider).saveLocale(code);
      await ref.read(translationCacheStoreProvider).clear();
      ref.invalidate(bootstrapCacheProvider);
      ref.invalidate(bootstrapProvider);
    } catch (_) {
      _showMessage(
        widget.labels.text(
          'error.bootstrap_unavailable',
          'We could not load the app configuration. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _languageBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => UploadedWelcomeScreen(
        initialLanguageCode: widget.labels.locale,
        resolvedLocationLabel: _locationLabel,
        busySocialProvider: _socialProvider,
        languageBusy: _languageBusy,
        onLanguageSelected: _useOpeningLanguage,
        onGoogle: _socialProvider != null ? null : () => _socialSignIn(apple: false),
        onApple: _socialProvider != null ? null : () => _socialSignIn(apple: true),
        onCreateAccount: () => _openEmail(registration: true),
        onEmailLogin: () => _openEmail(registration: false),
      );
}
