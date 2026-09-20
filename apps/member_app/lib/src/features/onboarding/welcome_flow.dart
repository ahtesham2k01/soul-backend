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
                      label: widget.labels.locale.toUpperCase(),
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
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        onPressed: _socialBusy ? null : () => _socialSignIn(apple: false),
                        icon: const Icon(Icons.g_mobiledata, size: 27),
                        label: Text(widget.labels.text('auth.continue_with_google', 'Continue with Google')),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                      )),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        onPressed: _socialBusy ? null : () => _socialSignIn(apple: true),
                        icon: const Icon(Icons.apple),
                        label: Text(widget.labels.text('auth.continue_with_apple', 'Continue with Apple')),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                      )),
                    ]),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 49,
                      child: ElevatedButton(
                        onPressed: () => _openEmail(registration: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SoulColors.limeLight,
                          foregroundColor: SoulColors.ink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          widget.labels.text('auth.create_account', 'Create Account'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _openEmail(registration: false),
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
            colors: [Color(0xff567d19), SoulColors.forestDeep],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 96, 30, 170),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    height: 220,
                    width: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SoulColors.lime.withValues(alpha: .10),
                      border: Border.all(
                        color: SoulColors.lime.withValues(alpha: .45),
                        width: 2,
                      ),
                    ),
                    child: Icon(slide.icon, size: 94, color: SoulColors.lime),
                  ),
                ),
              ),
              const Text(
                'SOUL',
                style: TextStyle(
                  color: SoulColors.lime,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${slide.accent}\n${slide.title}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.13,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                slide.description,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
              ),
            ],
          ),
        ),
      );
}

class _TopAction extends StatelessWidget {
  const _TopAction({required this.icon, this.label});

  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: Colors.white, size: 23),
          if (label != null) ...[
            const SizedBox(width: 8),
            Text(label!, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ],
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
