// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'uploaded_onboarding_app.dart';
import 'uploaded_welcome_screen.dart';

const _assetRoot = 'assets/uploaded_onboarding';

class UploadedSplashScreen extends StatefulWidget {
  const UploadedSplashScreen({super.key});

  @override
  State<UploadedSplashScreen> createState() => _UploadedSplashScreenState();
}

class _UploadedSplashScreenState extends State<UploadedSplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 950), _continue);
  }

  void _continue() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(_fadeRoute(const UploadedGlobeIntroScreen()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: soulLime,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: soulLime,
          body: SizedBox.expand(
            child: Image.asset(
              '$_assetRoot/splash.webp',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      );
}

class UploadedGlobeIntroScreen extends StatefulWidget {
  const UploadedGlobeIntroScreen({super.key});

  @override
  State<UploadedGlobeIntroScreen> createState() => _UploadedGlobeIntroScreenState();
}

class _UploadedGlobeIntroScreenState extends State<UploadedGlobeIntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spinController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1750),
  );
  late final AnimationController _contentController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  );
  late final Animation<double> _rotation = Tween<double>(
    begin: -math.pi * 10,
    end: 0,
  ).animate(
    CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _globeScale = Tween<double>(
    begin: 0.965,
    end: 1,
  ).animate(
    CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
  );

  Timer? _finishTimer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _runSequence();
  }

  Future<void> _runSequence() async {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _spinController.value = 1;
      _contentController.value = 1;
      _finishTimer = Timer(const Duration(milliseconds: 1250), _continue);
      return;
    }

    await _spinController.forward();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _contentController.forward();
    if (!mounted) return;
    _finishTimer = Timer(const Duration(milliseconds: 650), _continue);
  }

  void _continue() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(_fadeRoute(const UploadedWelcomeScreen()));
  }

  double _phase(double value, double start, double end) {
    if (value <= start) return 0;
    if (value >= end) return 1;
    return (value - start) / (end - start);
  }

  Widget _avatar(String asset, double width, double start) => AnimatedBuilder(
        animation: _contentController,
        child: Image.asset(asset, width: width),
        builder: (context, child) {
          final progress = Curves.easeOutCubic.transform(
            _phase(_contentController.value, start, start + 0.28),
          );
          return Opacity(
            opacity: progress.clamp(0, 1),
            child: Transform.scale(scale: 0.58 + (0.42 * progress), child: child),
          );
        },
      );

  @override
  void dispose() {
    _finishTimer?.cancel();
    _spinController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 720;
    final globeWidth = math.min(size.width * 0.78, 325.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: soulDeepGreen,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: soulDeepGreen,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _continue,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF071B05), Color(0xFF0B2A08)],
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.45,
                    colors: [Color(0x668DBF2E), Colors.transparent],
                  ),
                ),
              ),
              SafeArea(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_spinController, _contentController]),
                  builder: (context, _) {
                    final reveal = _contentController.value;
                    return Stack(
                      children: [
                        Positioned(
                          top: compact ? 82 : size.height * 0.18,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SizedBox(
                              width: globeWidth,
                              height: globeWidth,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Center(
                                    child: RepaintBoundary(
                                      child: Transform.rotate(
                                        angle: _rotation.value,
                                        child: Transform.scale(
                                          scale: _globeScale.value,
                                          child: Image.asset(
                                            '$_assetRoot/onboarding/globe.webp',
                                            width: globeWidth,
                                            filterQuality: FilterQuality.medium,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -34,
                                    left: 0,
                                    right: 0,
                                    child: Opacity(
                                      opacity: _phase(reveal, 0.55, 0.82),
                                      child: Transform.translate(
                                        offset: Offset(0, 10 * (1 - _phase(reveal, 0.55, 0.82))),
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                            decoration: BoxDecoration(
                                              color: soulLime,
                                              borderRadius: BorderRadius.circular(99),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x33000000),
                                                  blurRadius: 16,
                                                  offset: Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.location_on_rounded, size: 17, color: Colors.black),
                                                SizedBox(width: 6),
                                                Text(
                                                  'People near your area',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: globeWidth * 0.43,
                                    child: _avatar(
                                      '$_assetRoot/onboarding/upperavatar.webp',
                                      62,
                                      0.04,
                                    ),
                                  ),
                                  Positioned(
                                    top: globeWidth * 0.46,
                                    left: globeWidth * 0.04,
                                    child: _avatar(
                                      '$_assetRoot/onboarding/avatar1.webp',
                                      52,
                                      0.14,
                                    ),
                                  ),
                                  Positioned(
                                    top: globeWidth * 0.30,
                                    left: globeWidth * 0.27,
                                    child: _avatar(
                                      '$_assetRoot/onboarding/avatar2.webp',
                                      52,
                                      0.24,
                                    ),
                                  ),
                                  Positioned(
                                    top: globeWidth * 0.44,
                                    right: globeWidth * 0.10,
                                    child: _avatar(
                                      '$_assetRoot/onboarding/avatar4.webp',
                                      52,
                                      0.34,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: globeWidth * 0.10,
                                    left: globeWidth * 0.43,
                                    child: _avatar(
                                      '$_assetRoot/onboarding/avatar3.webp',
                                      52,
                                      0.44,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: compact ? 70 : size.height * 0.105,
                          child: Opacity(
                            opacity: _phase(reveal, 0.66, 1),
                            child: Transform.translate(
                              offset: Offset(0, 18 * (1 - _phase(reveal, 0.66, 1))),
                              child: Column(
                                children: [
                                  Image.asset(
                                    '$_assetRoot/onboarding/swipetoyour.webp',
                                    width: math.min(size.width * 0.72, 300),
                                  ),
                                  const SizedBox(height: 10),
                                  Image.asset(
                                    '$_assetRoot/onboarding/HappilyEverAfter.webp',
                                    width: math.min(size.width * 0.68, 270),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Route<void> _fadeRoute(Widget page) => PageRouteBuilder<void>(
      pageBuilder: (_, animation, __) => page,
      transitionDuration: const Duration(milliseconds: 520),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.015, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );