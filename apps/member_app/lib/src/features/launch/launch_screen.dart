import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';

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
                      _LaunchGlobe(
                        labels: widget.labels,
                        spin: spin,
                      ),
                      const Spacer(),
                      Opacity(
                        opacity: reveal,
                        child: Transform.translate(
                          offset: Offset(0, (1 - reveal) * 18),
                          child: _LaunchCopy(labels: widget.labels),
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

class _LaunchGlobe extends StatelessWidget {
  const _LaunchGlobe({
    required this.labels,
    required this.spin,
  });

  final BootstrapState labels;
  final double spin;

  String? get _locationLabel {
    final location = labels.location;
    if (location == null || location.city.trim().isEmpty) return null;
    final country = location.countryCode.trim();
    return country.isEmpty ? location.city : '${location.city}, $country';
  }

  @override
  Widget build(BuildContext context) {
    final locationLabel = _locationLabel;

    return SizedBox(
      width: 270,
      height: 270,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: (1 - spin) * math.pi * 3,
            child: Transform.scale(
              scale: .84 + (.16 * spin),
              child: const _Globe(),
            ),
          ),
          if (locationLabel != null)
            Positioned(
              bottom: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: SoulColors.limeLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: SoulColors.ink,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        locationLabel,
                        style: const TextStyle(
                          color: SoulColors.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
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
  const _LaunchCopy({required this.labels});

  final BootstrapState labels;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: SoulColors.lime,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                labels.text(
                  'onboarding.headline_highlight',
                  'Swipe to Your',
                ),
                style: const TextStyle(
                  color: SoulColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            labels.text(
              'onboarding.headline_rest',
              'Happily Ever After',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
}
