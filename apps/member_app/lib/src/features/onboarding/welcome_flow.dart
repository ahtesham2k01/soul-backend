import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  String? _socialError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  Future<void> _selectLanguage() async {
    final languages = widget.labels.supportedLanguages
        .where((language) => language.isLaunchReady)
        .toList(growable: false);
    if (languages.isEmpty) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _LanguageSheet(
        currentLocale: widget.labels.locale,
        languages: languages,
      ),
    );
    if (selected == null || selected == widget.labels.locale || !mounted) return;
    await ref.read(sessionStoreProvider).saveLocale(selected);
    if (!mounted) return;
    ref.invalidate(bootstrapProvider);
  }

  String get _languageLabel {
    for (final language in widget.labels.supportedLanguages) {
      if (language.code == widget.labels.locale) {
        return language.nativeName.isNotEmpty ? language.nativeName : language.name;
      }
    }
    return widget.labels.locale.toUpperCase();
  }

  Future<void> _socialSignIn({required bool apple}) async {
    setState(() { _socialBusy = true; _socialError = null; });
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
      // Closing the provider sheet is not an error and must not show a warning.
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _socialError = failure.message);
    } catch (_) {
      if (mounted) setState(() => _socialError = 'Sign-in could not be completed. Please try again.');
    } finally {
      if (mounted) setState(() => _socialBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: SoulColors.forestDeep,
        body: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (_, index) => _OnboardingSlide(slide: _slides[index]),
              ),
              Positioned(
                top: 18,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TopAction(
                      icon: Icons.language_outlined,
                      label: _languageLabel,
                      onTap: _selectLanguage,
                    ),
                    const _TopAction(icon: Icons.info_outline),
                  ],
                ),
              ),
              Positioned(
                left: 30,
                right: 30,
                bottom: 14,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 7,
                          width: index == _page ? 24 : 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: index == _page
                                ? SoulColors.lime
                                : Colors.white30,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    if (_socialError != null) ...[
                      Text(_socialError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 10),
                    ],
                    _AccountActions(
                      busy: _socialBusy,
                      createAccountLabel: widget.labels.text(
                        'auth.create_account',
                        'Create Account',
                      ),
                      onCreateAccount: () => _openEmail(registration: true),
                      onGoogle: () => _socialSignIn(apple: false),
                      onApple: () => _socialSignIn(apple: true),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _socialBusy ? null : () => _openEmail(registration: false),
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      child: const Text(
                        'Already have an account? Log in',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xff719f24), Color(0xff183707), SoulColors.forestDeep],
            stops: [0, .45, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 125,
              left: -85,
              child: _GradientHeart(size: 230, angle: -.18),
            ),
            const Positioned(
              top: 115,
              right: -112,
              child: _GradientHeart(size: 390, angle: .18),
            ),
            Positioned(
              top: 355,
              left: 12,
              child: Icon(
                Icons.favorite_border_rounded,
                size: 118,
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
            Positioned(
              top: 430,
              left: 170,
              child: Icon(
                Icons.favorite_rounded,
                size: 46,
                color: Colors.white.withValues(alpha: .15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 90, 30, 185),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 7),
                  const Row(
                    children: [
                      Icon(Icons.spa_rounded, color: SoulColors.limeLight, size: 25),
                      SizedBox(width: 7),
                      Text(
                        'SOUL',
                        style: TextStyle(
                          color: SoulColors.limeLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 25,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: SoulColors.limeLight,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(3, 1, 5, 2),
                      child: Text(
                        slide.accent,
                        style: const TextStyle(
                          color: SoulColors.ink,
                          fontSize: 29,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    slide.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    slide.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ],
        ),
      );
}

class _GradientHeart extends StatelessWidget {
  const _GradientHeart({required this.size, required this.angle});

  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: angle,
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [SoulColors.limeLight, Color(0xff527d14)],
          ).createShader(bounds),
          child: Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: size,
          ),
        ),
      );
}

class _AccountActions extends StatelessWidget {
  const _AccountActions({
    required this.busy,
    required this.createAccountLabel,
    required this.onCreateAccount,
    required this.onGoogle,
    required this.onApple,
  });

  final bool busy;
  final String createAccountLabel;
  final VoidCallback onCreateAccount;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) => Container(
        height: 64,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .16),
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(35),
        ),
        child: Row(
          children: [
            _ProviderCircle(
              onPressed: busy ? null : onGoogle,
              child: const Text(
                'G',
                style: TextStyle(
                  color: Color(0xff4285f4),
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _ProviderCircle(
              onPressed: busy ? null : onApple,
              child: const Icon(Icons.apple, color: Colors.black, size: 27),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: double.infinity,
                child: ElevatedButton(
                  onPressed: busy ? null : onCreateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SoulColors.limeLight,
                    foregroundColor: SoulColors.ink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(29),
                    ),
                  ),
                  child: Text(
                    busy ? 'Please wait…' : createAccountLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _ProviderCircle extends StatelessWidget {
  const _ProviderCircle({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 52,
        height: 52,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Center(child: child),
          ),
        ),
      );
}

class _TopAction extends StatelessWidget {
  const _TopAction({required this.icon, this.label, this.onTap});

  final IconData icon;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 25),
              if (label != null) ...[
                const SizedBox(width: 9),
                Text(
                  label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({
    required this.currentLocale,
    required this.languages,
  });

  final String currentLocale;
  final List<SupportedLanguage> languages;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 18, 26, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 28),
                  ),
                  const Expanded(
                    child: Text(
                      'Select language',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SoulColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 6),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final language = languages[index];
                    final selected = language.code == currentLocale;
                    final nativeName = language.nativeName.isNotEmpty
                        ? language.nativeName
                        : language.name;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 5),
                      onTap: () => Navigator.of(context).pop(language.code),
                      title: Text(
                        nativeName,
                        style: const TextStyle(
                          color: SoulColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: language.name.isNotEmpty
                          ? Text(
                              language.name,
                              style: const TextStyle(
                                color: SoulColors.muted,
                                fontSize: 14,
                              ),
                            )
                          : null,
                      trailing: Container(
                        width: 25,
                        height: 25,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? SoulColors.lime : SoulColors.line,
                            width: selected ? 2 : 1.5,
                          ),
                        ),
                        child: selected
                            ? Container(
                                width: 13,
                                height: 13,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: SoulColors.lime,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
}

class _Slide {
  const _Slide(this.accent, this.title, this.description, this.icon);

  final String accent;
  final String title;
  final String description;
  final IconData icon;
}

const _slides = [
  _Slide(
    'Swipe to Your',
    'Happily Ever After',
    'Start your journey to meaningful connections and lasting relationships today.',
    Icons.favorite_border_rounded,
  ),
  _Slide(
    'Discover Your',
    'Best Matches',
    'Find people who share the values and future you are looking for.',
    Icons.travel_explore_rounded,
  ),
  _Slide(
    'Meet People',
    'Around the World',
    'Connect thoughtfully, at your own pace, wherever life takes you.',
    Icons.public_rounded,
  ),
];
