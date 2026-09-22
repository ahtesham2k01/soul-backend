import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// Keeps the approved brand splash visible briefly after bootstrap/session state
/// is ready so a fast device cannot skip the first visual frame.
class LaunchScreen extends StatefulWidget {
  const LaunchScreen({
    required this.onFinished,
    super.key,
  });

  final VoidCallback onFinished;

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      const Duration(milliseconds: 900),
      () {
        if (mounted) widget.onFinished();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SoulBrandSplash();
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

    // Deliberately extends beyond the right edge, matching the clipped heart
    // detail in the approved reference.
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
