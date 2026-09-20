import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/soul_theme.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with TickerProviderStateMixin {
  late final AnimationController _globe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final AnimationController _content = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final reduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduceMotion) {
      _globe.value = 1;
      _content.value = 1;
    } else {
      await _globe.forward();
      if (!mounted) return;
      await _content.forward();
    }
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _globe.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: SoulColors.forestDeep,
        body: AnimatedBuilder(
          animation: Listenable.merge([_globe, _content]),
          builder: (context, _) {
            final spin = Curves.easeOutCubic.transform(_globe.value);
            final reveal = Curves.easeOut.transform(_content.value);
            return Stack(
              children: [
                const _ForestBackground(),
                SafeArea(
                  child: Column(
                    children: [
                      const Spacer(),
                      Transform.rotate(
                        angle: (1 - spin) * math.pi * 3,
                        child: Transform.scale(
                          scale: .84 + (.16 * spin),
                          child: const _Globe(),
                        ),
                      ),
                      const Spacer(),
                      Opacity(
                        opacity: reveal,
                        child: Transform.translate(
                          offset: Offset(0, (1 - reveal) * 18),
                          child: const _LaunchCopy(),
                        ),
                      ),
                      const SizedBox(height: 72),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class _ForestBackground extends StatelessWidget {
  const _ForestBackground();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xff6c971e), SoulColors.forestDeep, Color(0xff26490a)],
          ),
        ),
        child: SizedBox.expand(),
      );
}

class _Globe extends StatelessWidget {
  const _Globe();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 270,
        height: 270,
        child: CustomPaint(painter: _GlobePainter()),
      );
}

class _GlobePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final grid = Paint()
      ..color = SoulColors.lime.withValues(alpha: .58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [SoulColors.lime.withValues(alpha: .26), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glow);
    canvas.drawCircle(center, radius - 3, grid..strokeWidth = 2.2);
    for (final scale in [.34, .68]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2 * scale,
          height: radius * 2 - 8,
        ),
        grid..strokeWidth = 1.2,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2 - 8,
          height: radius * 2 * scale,
        ),
        grid,
      );
    }
    for (final point in const [
      Offset(.27, .25),
      Offset(.64, .36),
      Offset(.74, .62),
      Offset(.38, .70),
      Offset(.47, .47),
    ]) {
      final position = Offset(size.width * point.dx, size.height * point.dy);
      canvas.drawCircle(position, 8, Paint()..color = SoulColors.forestDeep);
      canvas.drawCircle(position, 8, grid..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LaunchCopy extends StatelessWidget {
  const _LaunchCopy();

  @override
  Widget build(BuildContext context) => const Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: SoulColors.lime,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                'Swipe to Your',
                style: TextStyle(
                  color: SoulColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Happily Ever After',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
}
