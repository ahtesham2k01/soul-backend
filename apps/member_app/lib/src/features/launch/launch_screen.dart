import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    duration: const Duration(milliseconds: 1500),
  );
  late final AnimationController _content = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
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
    await Future<void>.delayed(const Duration(milliseconds: 420));
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
            final reveal = Curves.easeOutCubic.transform(_globe.value);
            final copy = Curves.easeOut.transform(_content.value);
            return Stack(
              children: [
                const _LaunchBackdrop(),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      children: [
                        Positioned(
                          top: constraints.maxHeight * .18,
                          left: 24,
                          right: 24,
                          child: Transform.scale(
                            scale: .88 + (.12 * reveal),
                            child: Opacity(
                              opacity: .35 + (.65 * reveal),
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  SvgPicture.asset(
                                    'assets/design/welcome/globe_art.svg',
                                    width: constraints.maxWidth * .72,
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: constraints.maxWidth * .08,
                                    child: const _DistanceChip(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 28,
                          right: 28,
                          bottom: constraints.maxHeight * .11,
                          child: Opacity(
                            opacity: copy,
                            child: Transform.translate(
                              offset: Offset(0, (1 - copy) * 14),
                              child: const _LaunchCopy(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class _LaunchBackdrop extends StatelessWidget {
  const _LaunchBackdrop();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xff648d1e),
              Color(0xff244d0b),
              Color(0xff102903),
              Color(0xff071600),
            ],
            stops: [0, .26, .62, 1],
          ),
        ),
        child: SizedBox.expand(),
      );
}

class _DistanceChip extends StatelessWidget {
  const _DistanceChip();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: SoulColors.limeLight,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 11,
                color: SoulColors.ink,
              ),
              SizedBox(width: 3),
              Text(
                '45KM Away',
                style: TextStyle(
                  color: SoulColors.ink,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
}

class _LaunchCopy extends StatelessWidget {
  const _LaunchCopy();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: SoulColors.limeLight,
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text(
              'Swipe to Your',
              style: TextStyle(
                color: SoulColors.ink,
                fontSize: 20,
                height: 1.08,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Happily Ever After',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
}
