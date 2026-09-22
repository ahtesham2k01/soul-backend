import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';

/// Exact launch color sampled from the approved splash reference.
const soulSplashColor = Color(0xffb3d63b);

class SoulBrandSplash extends StatelessWidget {
  const SoulBrandSplash({super.key});

  static const _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: soulSplashColor,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: soulSplashColor,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: soulSplashColor,
    systemNavigationBarContrastEnforced: false,
  );

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: _overlayStyle,
        child: Scaffold(
          backgroundColor: soulSplashColor,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const IgnorePointer(
                child: CustomPaint(painter: _SplashHeartsPainter()),
              ),
              Center(
                child: Semantics(
                  label: 'SOUL',
                  image: true,
                  child: const ExcludeSemantics(
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
                ),
              ),
            ],
          ),
        ),
      );
}

/// Visible launch sequence:
/// approved SOUL splash -> fast-to-slow globe -> member markers -> real location
/// -> localized tagline -> existing auth/onboarding route.
class LaunchScreen extends StatefulWidget {
  const LaunchScreen({
    required this.labels,
    required this.onFinished,
    super.key,
  });

  final BootstrapState labels;
  final VoidCallback onFinished;

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  bool _started = false;
  bool _showGlobe = false;
  bool _finished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_run());
  }

  Future<void> _run() async {
    final media = MediaQuery.maybeOf(context);
    final reduceMotion = media?.disableAnimations ??
        WidgetsBinding
            .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

    // The native/Flutter splash may already have been visible during bootstrap.
    // This short hold guarantees the approved first frame is still perceivable
    // on very fast devices without making slower startup feel artificially long.
    await Future<void>.delayed(
      Duration(milliseconds: reduceMotion ? 260 : 620),
    );
    if (!mounted) return;

    setState(() => _showGlobe = true);
    await Future<void>.delayed(
      Duration(milliseconds: reduceMotion ? 40 : 160),
    );
    if (!mounted) return;

    if (reduceMotion) {
      _spin.value = 1;
      _reveal.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 720));
      _finish();
      return;
    }

    await _spin.forward();
    if (!mounted || _finished) return;

    // The pause is intentional: users should feel the globe settle before
    // avatars, location and copy appear.
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted || _finished) return;

    await _reveal.forward();
    if (!mounted || _finished) return;

    await Future<void>.delayed(const Duration(milliseconds: 430));
    _finish();
  }

  void _skip() {
    if (!_showGlobe || _finished) return;
    _spin.value = 1;
    _reveal.value = 1;
    Future<void>.delayed(const Duration(milliseconds: 160), _finish);
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _spin.dispose();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _showGlobe
            ? _GlobeIntro(
                key: const ValueKey('globe-intro'),
                labels: widget.labels,
                spin: _spin,
                reveal: _reveal,
                onSkip: _skip,
              )
            : const SoulBrandSplash(
                key: ValueKey('brand-splash'),
              ),
      );
}

class _GlobeIntro extends StatelessWidget {
  const _GlobeIntro({
    required this.labels,
    required this.spin,
    required this.reveal,
    required this.onSkip,
    super.key,
  });

  final BootstrapState labels;
  final Animation<double> spin;
  final Animation<double> reveal;
  final VoidCallback onSkip;

  static const _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: SoulColors.forestDeep,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: SoulColors.forestDeep,
    systemNavigationBarContrastEnforced: false,
  );

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: _overlayStyle,
        child: Scaffold(
          backgroundColor: SoulColors.forestDeep,
          body: Semantics(
            button: true,
            label: 'Skip intro animation',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSkip,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _GlobeBackground(),
                  SafeArea(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([spin, reveal]),
                      builder: (context, _) {
                        final screen = MediaQuery.sizeOf(context);
                        final compact = screen.height < 720;
                        final globeSize = math.min(
                          screen.width * (compact ? .68 : .73),
                          compact ? 252.0 : 292.0,
                        );

                        return Stack(
                          children: [
                            Positioned(
                              top: compact ? 66 : screen.height * .145,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: _GlobeStage(
                                  key: const ValueKey('launch-globe-stage'),
                                  size: globeSize,
                                  rotationProgress: spin.value,
                                  revealProgress: reveal.value,
                                  location: labels.location,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 24,
                              right: 24,
                              bottom: compact ? 64 : screen.height * .105,
                              child: _LaunchTagline(
                                labels: labels,
                                progress: reveal.value,
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

class _GlobeBackground extends StatelessWidget {
  const _GlobeBackground();

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xff173a08),
                  SoulColors.forestDeep,
                  Color(0xff0c2503),
                ],
              ),
            ),
          ),
          Positioned(
            left: -70,
            right: -70,
            bottom: -170,
            height: 390,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      SoulColors.lime.withValues(alpha: .32),
                      SoulColors.lime.withValues(alpha: .08),
                      Colors.transparent,
                    ],
                    stops: const [0, .42, 1],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

class _GlobeStage extends StatelessWidget {
  const _GlobeStage({
    required this.size,
    required this.rotationProgress,
    required this.revealProgress,
    required this.location,
    super.key,
  });

  final double size;
  final double rotationProgress;
  final double revealProgress;
  final BootstrapLocation? location;

  static const _avatars = <_AvatarSpec>[
    _AvatarSpec(.52, .18, 1.10, Color(0xffd8d8cf)),
    _AvatarSpec(.33, .37, .82, Color(0xffb6c79d)),
    _AvatarSpec(.19, .54, .76, Color(0xffddd0b1)),
    _AvatarSpec(.71, .49, .84, Color(0xffc6b497)),
    _AvatarSpec(.43, .74, .77, Color(0xffc3c7ad)),
  ];

  @override
  Widget build(BuildContext context) {
    final easedSpin = Curves.easeOutCubic.transform(rotationProgress);
    // More than three rotations start visually fast and decelerate into the
    // final orientation. Transform.rotate stays on the compositor and avoids
    // repainting the globe every frame.
    final angle = math.pi * 2 * 3.18 * easedSpin;
    final locationProgress = _phase(revealProgress, .58, .82);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          RepaintBoundary(
            child: Transform.rotate(
              angle: angle,
              child: SizedBox.square(
                dimension: size,
                child: CustomPaint(
                  key: const ValueKey('launch-globe'),
                  isComplex: true,
                  willChange: false,
                  painter: const _PremiumGlobePainter(),
                ),
              ),
            ),
          ),
          ...List<Widget>.generate(_avatars.length, (index) {
            final spec = _avatars[index];
            final start = .04 + (index * .095);
            final progress = _phase(
              revealProgress,
              start,
              math.min(start + .30, .70),
            );
            return _MemberBubble(
              key: ValueKey('launch-avatar-$index'),
              spec: spec,
              globeSize: size,
              progress: progress,
            );
          }),
          if (location != null && location!.city.trim().isNotEmpty)
            Positioned(
              key: const ValueKey('launch-location-chip'),
              top: -18,
              left: 0,
              right: 0,
              child: Center(
                child: Opacity(
                  opacity: locationProgress,
                  child: Transform.translate(
                    offset: Offset(0, (1 - locationProgress) * 10),
                    child: Transform.scale(
                      scale: .94 + (.06 * Curves.easeOutBack.transform(
                        locationProgress,
                      )),
                      child: _LocationChip(location: location!),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.location});

  final BootstrapLocation location;

  @override
  Widget build(BuildContext context) {
    final flag = _countryFlag(location.countryCode);
    final city = location.city.trim();
    final code = location.countryCode.trim().toUpperCase();

    return Container(
      constraints: const BoxConstraints(maxWidth: 235),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: SoulColors.limeLight,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .14),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flag, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              code.isEmpty ? city : '$city, $code',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SoulColors.ink,
                fontSize: 12,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberBubble extends StatelessWidget {
  const _MemberBubble({
    required this.spec,
    required this.globeSize,
    required this.progress,
    super.key,
  });

  final _AvatarSpec spec;
  final double globeSize;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final bubbleSize = 34 * spec.scale;
    final curved = Curves.easeOutBack.transform(progress);

    return Positioned(
      left: (globeSize * spec.dx) - (bubbleSize / 2),
      top: (globeSize * spec.dy) - (bubbleSize / 2),
      child: Opacity(
        opacity: progress,
        child: Transform.scale(
          scale: .35 + (.65 * curved),
          child: Container(
            width: bubbleSize,
            height: bubbleSize,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SoulColors.lime,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .22),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: spec.faceColor,
              ),
              child: Icon(
                Icons.person_rounded,
                color: SoulColors.forestDeep,
                size: bubbleSize * .58,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LaunchTagline extends StatelessWidget {
  const _LaunchTagline({
    required this.labels,
    required this.progress,
  });

  final BootstrapState labels;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final first = _phase(progress, .67, .90);
    final second = _phase(progress, .78, 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: first,
          child: Transform.translate(
            offset: Offset(0, (1 - first) * 16),
            child: Container(
              key: const ValueKey('launch-headline-highlight'),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: SoulColors.limeLight,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                labels.text('onboarding.headline_highlight', 'Swipe to Your'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SoulColors.ink,
                  fontSize: 22,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Opacity(
          opacity: second,
          child: Transform.translate(
            offset: Offset(0, (1 - second) * 14),
            child: Text(
              key: const ValueKey('launch-headline-rest'),
              labels.text(
                'onboarding.headline_rest',
                'Happily Ever After',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -.25,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumGlobePainter extends CustomPainter {
  const _PremiumGlobePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    final sphere = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-.35, -.38),
        radius: .95,
        colors: [
          Color(0xffb9df35),
          Color(0xff6f9d18),
          Color(0xff35590d),
          Color(0xff173506),
        ],
        stops: [0, .42, .74, 1],
      ).createShader(rect);

    canvas.drawCircle(center, radius, sphere);

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius - 1)),
    );

    final grid = Paint()
      ..color = const Color(0xffd5ef72).withValues(alpha: .13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * .42,
        height: size.height * .96,
      ),
      grid,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * .76,
        height: size.height * .96,
      ),
      grid,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * .96,
        height: size.height * .42,
      ),
      grid,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * .96,
        height: size.height * .72,
      ),
      grid,
    );

    final land = Paint()
      ..color = const Color(0xff294b0d)
      ..style = PaintingStyle.fill;

    final europeAfrica = Path()
      ..moveTo(size.width * .45, size.height * .22)
      ..cubicTo(
        size.width * .54,
        size.height * .18,
        size.width * .63,
        size.height * .24,
        size.width * .68,
        size.height * .30,
      )
      ..cubicTo(
        size.width * .61,
        size.height * .34,
        size.width * .59,
        size.height * .39,
        size.width * .63,
        size.height * .44,
      )
      ..cubicTo(
        size.width * .58,
        size.height * .47,
        size.width * .55,
        size.height * .55,
        size.width * .53,
        size.height * .68,
      )
      ..cubicTo(
        size.width * .47,
        size.height * .73,
        size.width * .42,
        size.height * .63,
        size.width * .39,
        size.height * .55,
      )
      ..cubicTo(
        size.width * .34,
        size.height * .47,
        size.width * .32,
        size.height * .37,
        size.width * .38,
        size.height * .31,
      )
      ..close();

    final asia = Path()
      ..moveTo(size.width * .60, size.height * .26)
      ..cubicTo(
        size.width * .74,
        size.height * .22,
        size.width * .88,
        size.height * .29,
        size.width * .96,
        size.height * .39,
      )
      ..cubicTo(
        size.width * .89,
        size.height * .44,
        size.width * .80,
        size.height * .45,
        size.width * .74,
        size.height * .53,
      )
      ..cubicTo(
        size.width * .69,
        size.height * .50,
        size.width * .65,
        size.height * .42,
        size.width * .58,
        size.height * .39,
      )
      ..close();

    final west = Path()
      ..moveTo(size.width * .09, size.height * .30)
      ..cubicTo(
        size.width * .18,
        size.height * .20,
        size.width * .31,
        size.height * .22,
        size.width * .36,
        size.height * .32,
      )
      ..cubicTo(
        size.width * .30,
        size.height * .39,
        size.width * .28,
        size.height * .46,
        size.width * .22,
        size.height * .51,
      )
      ..cubicTo(
        size.width * .15,
        size.height * .48,
        size.width * .10,
        size.height * .40,
        size.width * .09,
        size.height * .30,
      )
      ..close();

    canvas.drawPath(europeAfrica, land);
    canvas.drawPath(asia, land);
    canvas.drawPath(west, land);

    canvas.drawCircle(
      Offset(size.width * .71, size.height * .64),
      size.width * .018,
      land,
    );
    canvas.drawCircle(
      Offset(size.width * .78, size.height * .70),
      size.width * .012,
      land,
    );

    final shade = Paint()
      ..shader = RadialGradient(
        center: const Alignment(.50, .48),
        radius: .72,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: .34),
        ],
        stops: const [.55, 1],
      ).createShader(rect);
    canvas.drawCircle(center, radius, shade);

    canvas.restore();

    canvas.drawCircle(
      center,
      radius - .8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = SoulColors.lime.withValues(alpha: .38),
    );
  }

  @override
  bool shouldRepaint(covariant _PremiumGlobePainter oldDelegate) => false;
}

class _AvatarSpec {
  const _AvatarSpec(this.dx, this.dy, this.scale, this.faceColor);

  final double dx;
  final double dy;
  final double scale;
  final Color faceColor;
}

double _phase(double value, double start, double end) {
  if (value <= start) return 0;
  if (value >= end) return 1;
  return (value - start) / (end - start);
}

String _countryFlag(String rawCode) {
  final code = rawCode.trim().toUpperCase();
  if (!RegExp(r'^[A-Z]{2}$').hasMatch(code)) return '•';
  return String.fromCharCodes(
    code.codeUnits.map((unit) => 0x1F1E6 + unit - 0x41),
  );
}

class _SplashHeartsPainter extends CustomPainter {
  const _SplashHeartsPainter();

  static const _heartColor = Color(0xffbedc58);

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
  bool shouldRepaint(covariant _SplashHeartsPainter oldDelegate) => false;
}
