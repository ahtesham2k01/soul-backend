import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'uploaded_opening_design.dart';
import 'uploaded_welcome_screen.dart';

class UploadedSplashScreen extends StatefulWidget {
  const UploadedSplashScreen({
    super.key,
    this.resolvedLocationLabel,
  });

  final String? resolvedLocationLabel;

  @override
  State<UploadedSplashScreen> createState() => _UploadedSplashScreenState();
}

class _UploadedSplashScreenState extends State<UploadedSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _holdController = AnimationController(
    vsync: this,
    duration: OpeningMotion.splashHold,
  );

  bool _started = false;
  bool _navigating = false;

  static const _openingAssets = <String>[
    '$uploadedOpeningAssetRoot/onboarding/globe.webp',
    '$uploadedOpeningAssetRoot/onboarding/upperavatar.webp',
    '$uploadedOpeningAssetRoot/onboarding/avatar1.webp',
    '$uploadedOpeningAssetRoot/onboarding/avatar2.webp',
    '$uploadedOpeningAssetRoot/onboarding/avatar3.webp',
    '$uploadedOpeningAssetRoot/onboarding/avatar4.webp',
    '$uploadedOpeningAssetRoot/onboarding/slide1/slide1bg.webp',
    '$uploadedOpeningAssetRoot/onboarding/slide2/slide2bg.webp',
    '$uploadedOpeningAssetRoot/onboarding/slide3/slide3bg.webp',
    '$uploadedOpeningAssetRoot/onboarding/soulLogo.webp',
    '$uploadedOpeningAssetRoot/onboarding/BarGoogle.webp',
    '$uploadedOpeningAssetRoot/onboarding/BarApple.webp',
    '$uploadedOpeningAssetRoot/onboarding/barBg.webp',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_prepareAndContinue());
  }

  Future<void> _prepareAndContinue() async {
    try {
      await Future.wait<void>([
        _holdController.forward().orCancel,
        _precacheOpeningAssets(),
      ]);
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    _continue();
  }

  Future<void> _precacheOpeningAssets() async {
    for (final asset in _openingAssets) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(asset), context);
      } catch (_) {
        // A missing preview asset should not strand the user on splash.
      }
    }
  }

  void _continue() {
    if (_navigating || !mounted) return;
    _navigating = true;
    final copy = openingCopyFor(detectOpeningLanguageCode());
    Navigator.of(context).pushReplacement(
      openingRoute(
        context,
        UploadedGlobeIntroScreen(
          copy: copy,
          resolvedLocationLabel: widget.resolvedLocationLabel,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: soulLime,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: soulLime,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: soulLime,
          systemNavigationBarContrastEnforced: false,
        ),
        child: Scaffold(
          key: const ValueKey('opening-splash'),
          backgroundColor: soulLime,
          body: Semantics(
            image: true,
            label: 'SOUL',
            child: const ExcludeSemantics(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _ApprovedSplashHeartsPainter(),
                    ),
                  ),
                  Center(
                    child: Text(
                      'SOUL',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 38,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class UploadedGlobeIntroScreen extends StatefulWidget {
  const UploadedGlobeIntroScreen({
    required this.copy,
    super.key,
    this.resolvedLocationLabel,
    this.onFinished,
  });

  final OpeningCopy copy;
  final String? resolvedLocationLabel;
  final VoidCallback? onFinished;

  @override
  State<UploadedGlobeIntroScreen> createState() =>
      _UploadedGlobeIntroScreenState();
}

class _UploadedGlobeIntroScreenState extends State<UploadedGlobeIntroScreen>
    with SingleTickerProviderStateMixin {
  static const double _spinEnd = 1650 / 3250;
  static const double _revealStart = (1650 + 180) / 3250;
  static const double _revealEnd = (1650 + 180 + 900) / 3250;

  late final AnimationController _sequence = AnimationController(
    vsync: this,
    duration: OpeningMotion.globeSequence,
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener(_handleSequenceStatus);

  bool _started = false;
  bool _navigating = false;

  double get _spinProgress {
    if (_sequence.value >= _spinEnd) return 1;
    return Curves.easeOutCubic.transform(
      (_sequence.value / _spinEnd).clamp(0, 1),
    );
  }

  double get _revealProgress {
    if (_sequence.value <= _revealStart) return 0;
    if (_sequence.value >= _revealEnd) return 1;
    return ((_sequence.value - _revealStart) /
            (_revealEnd - _revealStart))
        .clamp(0, 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      // Reduced motion is a fully settled, already-revealed static frame.
      // AnimationBehavior.preserve keeps this deliberate hold from being
      // fast-forwarded by the framework accessibility setting.
      _sequence.value = _revealEnd;
      _sequence.animateTo(
        1,
        duration: OpeningMotion.reducedHold,
        curve: Curves.linear,
      );
    } else {
      _sequence.forward();
    }
  }

  void _handleSequenceStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _continue();
    }
  }

  void _skip() {
    if (_navigating || !mounted) return;
    HapticFeedback.selectionClick();
    _sequence.stop();
    _continue();
  }

  void _continue() {
    if (_navigating || !mounted) return;
    _navigating = true;
    if (widget.onFinished != null) {
      widget.onFinished!();
      return;
    }
    Navigator.of(context).pushReplacement(
      openingRoute(
        context,
        UploadedWelcomeScreen(
          initialLanguageCode: widget.copy.languageCode,
        ),
      ),
    );
  }

  double _phase(double value, double start, double end) {
    if (value <= start) return 0;
    if (value >= end) return 1;
    return (value - start) / (end - start);
  }

  Widget _avatar({
    required String asset,
    required double width,
    required double start,
    required String keyName,
  }) {
    final raw = _phase(
      _revealProgress,
      start,
      math.min(start + .26, .70),
    );
    final eased = Curves.easeOutBack.transform(raw);
    return Opacity(
      key: ValueKey(keyName),
      opacity: raw.clamp(0, 1),
      child: Transform.scale(
        scale: .62 + (.38 * eased),
        child: ExcludeSemantics(
          child: Image.asset(
            asset,
            width: width,
            cacheWidth: 180,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sequence
      ..removeStatusListener(_handleSequenceStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final compact = size.height < 720;
    final globeWidth = math.min(size.width * .78, 325.0);
    final decodedGlobeWidth =
        (globeWidth * dpr).round().clamp(480, 1068).toInt();
    final location = widget.resolvedLocationLabel?.trim();
    final hasLocation = location != null && location.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: soulDeepGreen,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: soulDeepGreen,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        key: const ValueKey('opening-globe'),
        backgroundColor: soulDeepGreen,
        body: Semantics(
          button: true,
          label: widget.copy.skipIntroLabel,
          hint: widget.copy.skipIntroHint,
          onTap: _skip,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _skip,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF071B05),
                        Color(0xFF0B2A08),
                      ],
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.45,
                      colors: [
                        Color(0x668DBF2E),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomLeft,
                      radius: 1.6,
                      colors: [
                        Color(0x335E7E18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: AnimatedBuilder(
                    animation: _sequence,
                    builder: (context, _) {
                      final spin = _spinProgress;
                      final reveal = _revealProgress;
                      final angle = -math.pi * 9 * (1 - spin);
                      final globeScale = .965 + (.035 * spin);

                      return Stack(
                        children: [
                          Positioned(
                            top: compact ? 74 : size.height * .16,
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
                                          key: const ValueKey(
                                            'opening-globe-rotator',
                                          ),
                                          angle: angle,
                                          child: Transform.scale(
                                            scale: globeScale,
                                            child: ExcludeSemantics(
                                              child: Image.asset(
                                                '$uploadedOpeningAssetRoot/onboarding/globe.webp',
                                                width: globeWidth,
                                                cacheWidth:
                                                    decodedGlobeWidth,
                                                filterQuality:
                                                    FilterQuality.medium,
                                                gaplessPlayback: true,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (hasLocation)
                                      Positioned(
                                        top: -34,
                                        left: 0,
                                        right: 0,
                                        child: Opacity(
                                          key: const ValueKey(
                                            'opening-location-chip',
                                          ),
                                          opacity:
                                              _phase(reveal, .70, .88),
                                          child: Transform.translate(
                                            offset: Offset(
                                              0,
                                              9 *
                                                  (1 -
                                                      _phase(
                                                        reveal,
                                                        .70,
                                                        .88,
                                                      )),
                                            ),
                                            child: Center(
                                              child: Semantics(
                                                label: location,
                                                child: Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                    maxWidth: 235,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 13,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: soulLimeAccent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      99,
                                                    ),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                        color:
                                                            Color(0x33000000),
                                                        blurRadius: 16,
                                                        offset: Offset(0, 6),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .location_on_rounded,
                                                        size: 17,
                                                        color: Colors.black,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: Text(
                                                          location,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                            color:
                                                                Colors.black,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w800,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      top: 8,
                                      left: globeWidth * .43,
                                      child: _avatar(
                                        asset:
                                            '$uploadedOpeningAssetRoot/onboarding/upperavatar.webp',
                                        width: 62,
                                        start: .04,
                                        keyName: 'opening-avatar-0',
                                      ),
                                    ),
                                    Positioned(
                                      top: globeWidth * .46,
                                      left: globeWidth * .04,
                                      child: _avatar(
                                        asset:
                                            '$uploadedOpeningAssetRoot/onboarding/avatar1.webp',
                                        width: 52,
                                        start: .14,
                                        keyName: 'opening-avatar-1',
                                      ),
                                    ),
                                    Positioned(
                                      top: globeWidth * .30,
                                      left: globeWidth * .27,
                                      child: _avatar(
                                        asset:
                                            '$uploadedOpeningAssetRoot/onboarding/avatar2.webp',
                                        width: 52,
                                        start: .24,
                                        keyName: 'opening-avatar-2',
                                      ),
                                    ),
                                    Positioned(
                                      top: globeWidth * .44,
                                      right: globeWidth * .10,
                                      child: _avatar(
                                        asset:
                                            '$uploadedOpeningAssetRoot/onboarding/avatar4.webp',
                                        width: 52,
                                        start: .34,
                                        keyName: 'opening-avatar-3',
                                      ),
                                    ),
                                    Positioned(
                                      bottom: globeWidth * .10,
                                      left: globeWidth * .43,
                                      child: _avatar(
                                        asset:
                                            '$uploadedOpeningAssetRoot/onboarding/avatar3.webp',
                                        width: 52,
                                        start: .44,
                                        keyName: 'opening-avatar-4',
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
                            bottom:
                                compact ? 58 : size.height * .085,
                            child: Opacity(
                              key: const ValueKey(
                                'opening-tagline',
                              ),
                              opacity: _phase(reveal, .78, 1),
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  14 *
                                      (1 -
                                          _phase(
                                            reveal,
                                            .78,
                                            1,
                                          )),
                                ),
                                child: _IntroTagline(
                                  copy: widget.copy,
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
      ),
    );
  }
}

class _IntroTagline extends StatelessWidget {
  const _IntroTagline({required this.copy});

  final OpeningCopy copy;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        label: '${copy.introHighlight} ${copy.introRest}',
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: soulLimeAccent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  copy.introHighlight,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: soulInk,
                    fontSize: 22,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.45,
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                copy.introRest,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.25,
                ),
              ),
            ],
          ),
        ),
      );
}

class _ApprovedSplashHeartsPainter extends CustomPainter {
  const _ApprovedSplashHeartsPainter();

  static const _heartColor = Color(0xFFBEDC58);

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.width;

    _drawHeart(
      canvas,
      center: Offset(size.width * .79, size.height * .16),
      size: Size(base * .13, base * .14),
      rotation: -.34,
      paint: Paint()
        ..color = _heartColor.withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25,
    );

    _drawHeart(
      canvas,
      center: Offset(size.width * .70, size.height * .305),
      size: Size(base * .31, base * .32),
      rotation: .10,
      dashed: true,
      paint: Paint()
        ..color = _heartColor.withValues(alpha: .66)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15,
    );

    _drawHeart(
      canvas,
      center: Offset(size.width * 1.055, size.height * .255),
      size: Size(base * .14, base * .14),
      rotation: -.18,
      paint: Paint()
        ..color = _heartColor.withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawHeart(
    Canvas canvas, {
    required Offset center,
    required Size size,
    required double rotation,
    required Paint paint,
    bool dashed = false,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = _heartPath(size);
    if (dashed) {
      _drawDashedPath(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  Path _heartPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(0, h * .43)
      ..cubicTo(
        -w * .52,
        h * .13,
        -w * .58,
        -h * .18,
        -w * .30,
        -h * .30,
      )
      ..cubicTo(
        -w * .12,
        -h * .38,
        -w * .02,
        -h * .24,
        0,
        -h * .14,
      )
      ..cubicTo(
        w * .02,
        -h * .24,
        w * .12,
        -h * .38,
        w * .30,
        -h * .30,
      )
      ..cubicTo(
        w * .58,
        -h * .18,
        w * .52,
        h * .13,
        0,
        h * .43,
      )
      ..close();
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dash = 7.5;
    const gap = 8.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ApprovedSplashHeartsPainter oldDelegate) =>
      false;
}
