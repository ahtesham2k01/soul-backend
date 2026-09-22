import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app_providers.dart';
import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import '../auth/auth_screen.dart';
import '../auth/native_identity_service.dart';
import '../bootstrap/bootstrap_repository.dart';

class WelcomeFlow extends ConsumerStatefulWidget {
  const WelcomeFlow({required this.labels, super.key});

  final BootstrapState labels;

  @override
  ConsumerState<WelcomeFlow> createState() => _WelcomeFlowState();
}

class _WelcomeFlowState extends ConsumerState<WelcomeFlow> {
  final _controller = PageController();
  int _page = 0;
  bool _socialBusy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _languageLabel {
    for (final language in widget.labels.supportedLanguages) {
      if (language.code == widget.labels.locale) {
        return language.nativeName;
      }
    }
    return widget.labels.locale.toUpperCase();
  }

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
    if (_socialBusy) return;
    setState(() => _socialBusy = true);
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
      // Closing the provider sheet is not an error.
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
      if (mounted) setState(() => _socialBusy = false);
    }
  }

  Future<void> _selectLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: false,
      builder: (sheetContext) {
        final languages = widget.labels.supportedLanguages
            .where(
              (language) =>
                  language.isLaunchTarget && language.isLaunchReady,
            )
            .toList(growable: false);
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: .72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 18, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      Expanded(
                        child: Text(
                          widget.labels.text(
                            'language.select',
                            'Select language',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: SoulColors.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: languages.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 22,
                      endIndent: 22,
                    ),
                    itemBuilder: (_, index) {
                      final language = languages[index];
                      final active = language.code == widget.labels.locale;
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        title: Text(
                          language.nativeName,
                          style: const TextStyle(
                            color: SoulColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: language.name == language.nativeName
                            ? null
                            : Text(language.name),
                        trailing: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: active
                                  ? SoulColors.lime
                                  : const Color(0xffe6e8eb),
                              width: 1.5,
                            ),
                          ),
                          child: active
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: SoulColors.lime,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        onTap: () =>
                            Navigator.of(sheetContext).pop(language.code),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || selected == widget.labels.locale) return;
    await ref.read(sessionStoreProvider).saveLocale(selected);
    await ref.read(translationCacheStoreProvider).clear();
    ref.invalidate(bootstrapCacheProvider);
    ref.invalidate(bootstrapProvider);
  }

  void _showInfo() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SOUL',
                style: TextStyle(
                  color: SoulColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.labels.text(
                  'onboarding.subtitle',
                  'Start your journey to meaningful connections and lasting relationships today',
                ),
                style: const TextStyle(
                  color: SoulColors.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: SoulColors.forestDeep,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 700;
              return Stack(
                children: [
                  const Positioned.fill(child: _WelcomeBackdrop()),
                  Positioned.fill(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: 3,
                      onPageChanged: (value) => setState(() => _page = value),
                      itemBuilder: (_, index) => _WelcomeArtwork(
                        index: index,
                        locationLabel: _locationLabel,
                      ),
                    ),
                  ),
                  Positioned(
                    top: compact ? 12 : 18,
                    left: 22,
                    right: 22,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _TopAssetAction(
                          asset: 'assets/design/welcome/globe_icon.svg',
                          label: _languageLabel,
                          onTap: _selectLanguage,
                        ),
                        _TopAssetAction(
                          asset: 'assets/design/welcome/info_icon.svg',
                          onTap: _showInfo,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: compact ? 118 : 130,
                    child: _HeadlineBlock(
                      labels: widget.labels,
                      page: _page,
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 18 + MediaQuery.paddingOf(context).bottom,
                    child: _AuthBar(
                      busy: _socialBusy,
                      labels: widget.labels,
                      onGoogle: () => _socialSignIn(apple: false),
                      onApple: () => _socialSignIn(apple: true),
                      onCreateAccount: () => _openEmail(registration: true),
                      onLogin: () => _openEmail(registration: false),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
}

class _WelcomeBackdrop extends StatelessWidget {
  const _WelcomeBackdrop();

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xff5f861b),
                  Color(0xff244c0b),
                  Color(0xff102903),
                  Color(0xff071600),
                ],
                stops: [0, .25, .62, 1],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 1.18),
            child: Container(
              width: MediaQuery.sizeOf(context).width * 1.3,
              height: 250,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    SoulColors.lime.withValues(alpha: .40),
                    SoulColors.lime.withValues(alpha: .08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}

class _WelcomeArtwork extends StatelessWidget {
  const _WelcomeArtwork({
    required this.index,
    required this.locationLabel,
  });

  final int index;
  final String? locationLabel;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final visualHeight = size.height * .53;

    if (index == 0) {
      return SizedBox(
        height: visualHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 38,
              right: -38,
              child: SvgPicture.asset(
                'assets/design/welcome/abstract_right.svg',
                width: size.width * .49,
              ),
            ),
            Positioned(
              top: 62,
              left: -24,
              child: Opacity(
                opacity: .78,
                child: SvgPicture.asset(
                  'assets/design/welcome/abstract_left.svg',
                  width: size.width * .42,
                ),
              ),
            ),
            Positioned(
              top: visualHeight * .43,
              left: size.width * .08,
              child: Opacity(
                opacity: .45,
                child: SvgPicture.asset(
                  'assets/design/welcome/dashed_heart.svg',
                  width: size.width * .35,
                ),
              ),
            ),
            Positioned(
              top: visualHeight * .39,
              right: size.width * .25,
              child: Opacity(
                opacity: .55,
                child: SvgPicture.asset(
                  'assets/design/welcome/heart_bubble.svg',
                  width: 34,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (index == 1) {
      return SizedBox(
        height: visualHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 70,
              right: -22,
              child: SvgPicture.asset(
                'assets/design/welcome/paper_plane.svg',
                width: size.width * .47,
              ),
            ),
            Positioned(
              top: 118,
              left: 28,
              child: SvgPicture.asset(
                'assets/design/welcome/star.svg',
                width: 72,
              ),
            ),
            Positioned(
              top: visualHeight * .34,
              right: 4,
              child: Transform.rotate(
                angle: -.08,
                child: SvgPicture.asset(
                  'assets/design/welcome/profile_card.svg',
                  width: size.width * .48,
                ),
              ),
            ),
            Positioned(
              top: visualHeight * .39,
              left: size.width * .07,
              child: Opacity(
                opacity: .35,
                child: SvgPicture.asset(
                  'assets/design/welcome/dashed_heart.svg',
                  width: size.width * .32,
                ),
              ),
            ),
            Positioned(
              top: visualHeight * .32,
              right: size.width * .12,
              child: SvgPicture.asset(
                'assets/design/welcome/heart_bubble.svg',
                width: 34,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: visualHeight,
      child: Stack(
        children: [
          Positioned(
            top: 82,
            left: size.width * .12,
            right: size.width * .12,
            child: SvgPicture.asset(
              'assets/design/welcome/globe_art.svg',
              height: size.width * .62,
            ),
          ),
          if (locationLabel != null)
            Positioned(
              top: 68,
              right: size.width * .14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: SoulColors.limeLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 11,
                      color: SoulColors.ink,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      locationLabel!,
                      style: const TextStyle(
                        color: SoulColors.ink,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeadlineBlock extends StatelessWidget {
  const _HeadlineBlock({
    required this.labels,
    required this.page,
  });

  final BootstrapState labels;
  final int page;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/design/welcome/soul_lime.svg',
            width: 96,
            height: 22,
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: SoulColors.limeLight,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              labels.text(
                'onboarding.headline_highlight',
                'Swipe to Your',
              ),
              style: const TextStyle(
                color: SoulColors.ink,
                fontSize: 28,
                height: 1.02,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            labels.text(
              'onboarding.headline_rest',
              'Happily Ever After',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.04,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            labels.text(
              'onboarding.subtitle',
              'Start your journey to meaningful connections and lasting relationships today',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              height: 1.3,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(
              3,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: index == page ? 20 : 7,
                height: 5,
                margin: const EdgeInsetsDirectional.only(start: 4),
                decoration: BoxDecoration(
                  color: index == page
                      ? SoulColors.lime
                      : Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
      );
}

class _AuthBar extends StatelessWidget {
  const _AuthBar({
    required this.busy,
    required this.labels,
    required this.onGoogle,
    required this.onApple,
    required this.onCreateAccount,
    required this.onLogin,
  });

  final bool busy;
  final BootstrapState labels;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _SocialCircle(
                semanticLabel: labels.text(
                  'auth.continue_with_google',
                  'Continue with Google',
                ),
                asset: 'assets/design/welcome/google.svg',
                onTap: busy ? null : onGoogle,
              ),
              const SizedBox(width: 8),
              _SocialCircle(
                semanticLabel: labels.text(
                  'auth.continue_with_apple',
                  'Continue with Apple',
                ),
                asset: 'assets/design/welcome/apple.svg',
                onTap: busy ? null : onApple,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: FilledButton(
                    onPressed: busy ? null : onCreateAccount,
                    style: FilledButton.styleFrom(
                      backgroundColor: SoulColors.limeLight,
                      foregroundColor: SoulColors.ink,
                      disabledBackgroundColor:
                          SoulColors.limeLight.withValues(alpha: .65),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: SoulColors.ink,
                            ),
                          )
                        : Text(
                            labels.text(
                              'auth.create_account',
                              'Create Account',
                            ),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton(
              onPressed: busy ? null : onLogin,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: .55),
                ),
                shape: const StadiumBorder(),
              ),
              child: Text(
                labels.text(
                  'auth.continue_with_email',
                  'Continue with Email',
                ),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
}

class _SocialCircle extends StatelessWidget {
  const _SocialCircle({
    required this.semanticLabel,
    required this.asset,
    required this.onTap,
  });

  final String semanticLabel;
  final String asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semanticLabel,
        child: GestureDetector(
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? .55 : 1,
            child: SvgPicture.asset(
              asset,
              width: 40,
              height: 40,
            ),
          ),
        ),
      );
}

class _TopAssetAction extends StatelessWidget {
  const _TopAssetAction({
    required this.asset,
    required this.onTap,
    this.label,
  });

  final String asset;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(asset, width: 20, height: 20),
                if (label != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    label!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
