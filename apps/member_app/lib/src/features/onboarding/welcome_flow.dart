import 'package:flutter/material.dart';

import '../../core/soul_theme.dart';
import '../auth/auth_screen.dart';
import '../bootstrap/bootstrap_repository.dart';

class WelcomeFlow extends StatefulWidget {
  const WelcomeFlow({required this.labels, super.key});

  final BootstrapState labels;

  @override
  State<WelcomeFlow> createState() => _WelcomeFlowState();
}

class _WelcomeFlowState extends State<WelcomeFlow> {
  final _controller = PageController();
  int _page = 0;

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
