import 'dart:async';

import 'package:flutter/material.dart';

import '../../prototype/uploaded_onboarding/uploaded_opening_design.dart';
import '../../prototype/uploaded_onboarding/uploaded_splash_screen.dart';
import '../bootstrap/bootstrap_repository.dart';
import 'launch_screen.dart';

/// The single production launch path for Feature 1.
///
/// The first frame remains the approved native-matching brand splash. Once it
/// has been held long enough to be perceived, the owner-provided globe assets
/// and animation take over. This prevents the production app and review APK
/// from drifting into two visually different implementations.
class CanonicalOpeningLaunch extends StatefulWidget {
  const CanonicalOpeningLaunch({
    required this.labels,
    required this.onFinished,
    super.key,
  });

  final BootstrapState labels;
  final VoidCallback onFinished;

  @override
  State<CanonicalOpeningLaunch> createState() =>
      _CanonicalOpeningLaunchState();
}

class _CanonicalOpeningLaunchState extends State<CanonicalOpeningLaunch> {
  Timer? _hold;
  bool _showGlobe = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hold != null || _showGlobe) return;
    final reduced = MediaQuery.disableAnimationsOf(context);
    _hold = Timer(
      reduced ? const Duration(milliseconds: 260) : OpeningMotion.splashHold,
      () {
        if (mounted) setState(() => _showGlobe = true);
      },
    );
  }

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  String? get _locationLabel {
    final location = widget.labels.location;
    if (location == null || location.city.trim().isEmpty) return null;
    final country = location.countryCode.trim();
    return country.isEmpty ? location.city : '${location.city}, $country';
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : OpeningMotion.route,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _showGlobe
            ? UploadedGlobeIntroScreen(
                key: const ValueKey('canonical-opening-globe'),
                copy: openingCopyFor(widget.labels.locale),
                resolvedLocationLabel: _locationLabel,
                onFinished: widget.onFinished,
              )
            : const SoulBrandSplash(
                key: ValueKey('canonical-opening-splash'),
              ),
      );
}
