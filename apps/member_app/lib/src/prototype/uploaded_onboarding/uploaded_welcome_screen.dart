import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'uploaded_opening_design.dart';

class UploadedWelcomeScreen extends StatefulWidget {
  const UploadedWelcomeScreen({
    super.key,
    this.initialLanguageCode,
    this.onLanguageSelected,
    this.onGoogle,
    this.onApple,
    this.onCreateAccount,
    this.onEmailLogin,
    this.resolvedLocationLabel,
  });

  final String? initialLanguageCode;
  final ValueChanged<String>? onLanguageSelected;
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onEmailLogin;
  final String? resolvedLocationLabel;

  @override
  State<UploadedWelcomeScreen> createState() => _UploadedWelcomeScreenState();
}

class _UploadedWelcomeScreenState extends State<UploadedWelcomeScreen> {
  late final PageController _controller;
  late String _languageCode;
  int _currentPage = 0;

  static const _backgrounds = [
    '$uploadedOpeningAssetRoot/onboarding/slide1/slide1bg.webp',
    '$uploadedOpeningAssetRoot/onboarding/slide2/slide2bg.webp',
    '$uploadedOpeningAssetRoot/onboarding/slide3/slide3bg.webp',
  ];

  static const _languages = <(String, String, String)>[
    ('en', 'English', 'English'),
    ('en-GB', 'English (UK)', 'English (United Kingdom)'),
    ('ur', 'Roman Urdu', 'Roman Urdu'),
  ];

  OpeningCopy get copy => openingCopyFor(_languageCode);

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _languageCode =
        widget.initialLanguageCode ?? detectOpeningLanguageCode();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showLanguageSelector() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                copy.selectLanguage,
                style: const TextStyle(
                  color: soulInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              for (final language in _languages)
                Semantics(
                  button: true,
                  selected: _languageCode == language.$1,
                  label: language.$2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _languageCode = language.$1);
                      Navigator.of(sheetContext).pop();
                      widget.onLanguageSelected?.call(language.$1);
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 58),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    language.$2,
                                    style: const TextStyle(
                                      color: soulInk,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    language.$3,
                                    style: const TextStyle(
                                      color: soulMuted,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration:
                                  MediaQuery.disableAnimationsOf(context)
                                      ? Duration.zero
                                      : const Duration(milliseconds: 160),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      _languageCode == language.$1
                                          ? soulLimeAccent
                                          : soulLine,
                                  width: 1.8,
                                ),
                              ),
                              child: _languageCode == language.$1
                                  ? const Center(
                                      child: CircleAvatar(
                                        radius: 5,
                                        backgroundColor: soulLimeAccent,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showHelpSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 2, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: soulLime,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              copy.helpTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: soulInk,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              copy.helpBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: soulMuted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreviewEnd() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(copy.previewEnd),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _runOrPreview(VoidCallback? action) {
    if (action != null) {
      action();
      return;
    }
    _showPreviewEnd();
  }

  Widget _buildSlide(int index) => AnimatedBuilder(
        animation: _controller,
        child: Builder(
          builder: (context) {
            final targetWidth = math
                .min(
                  1500,
                  math.max(
                    720,
                    MediaQuery.sizeOf(context).width *
                        MediaQuery.devicePixelRatioOf(context),
                  ),
                )
                .round();
            return RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _backgrounds[index],
                    fit: BoxFit.cover,
                    cacheWidth: targetWidth,
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                  ),
                  if (index == 2)
                    Align(
                      alignment: const Alignment(0, -.69),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 38),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: soulLimeAccent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: soulInk,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.resolvedLocationLabel ?? copy.nearbyLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: soulInk,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        builder: (context, child) {
          if (MediaQuery.disableAnimationsOf(context)) return child!;
          var opacity = 1.0;
          var scale = 1.0;
          if (_controller.hasClients &&
              _controller.position.haveDimensions) {
            final page =
                _controller.page ?? _controller.initialPage.toDouble();
            final diff = (page - index).abs();
            opacity = (1 - (diff * .65)).clamp(0, 1);
            scale = (1 - (diff * .04)).clamp(.96, 1);
          }
          return Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: child),
          );
        },
      );

  Widget _buildDot(int index) {
    final active = _currentPage == index;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedContainer(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 22 : 8,
      height: 7,
      decoration: BoxDecoration(
        color: active ? soulLimeAccent : Colors.white30,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 700;
    final currentCopy = copy;

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
        key: const ValueKey('opening-welcome'),
        backgroundColor: soulDeepGreen,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              key: const ValueKey('opening-welcome-pages'),
              controller: _controller,
              physics: const PageScrollPhysics(),
              allowImplicitScrolling: true,
              itemCount: _backgrounds.length,
              onPageChanged: (index) =>
                  setState(() => _currentPage = index),
              itemBuilder: (_, index) => _buildSlide(index),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      compact ? 4 : 8,
                      12,
                      0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: copy.selectLanguage,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: _showLanguageSelector,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 48,
                                      minWidth: 48,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.language_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              _languages
                                                  .firstWhere(
                                                    (item) =>
                                                        item.$1 ==
                                                        _languageCode,
                                                  )
                                                  .$2,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
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
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Help',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: _showHelpSheet,
                          icon: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) =>
                          SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          compact ? 8 : 18,
                          20,
                          14,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 22,
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _WelcomeBottomPanel(
                              copy: currentCopy,
                              currentPage: _currentPage,
                              compact: compact,
                              dots: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  _buildDot(0),
                                  _buildDot(1),
                                  _buildDot(2),
                                ],
                              ),
                              onGoogle: () => _runOrPreview(widget.onGoogle),
                              onApple: () => _runOrPreview(widget.onApple),
                              onCreate: () =>
                                  _runOrPreview(widget.onCreateAccount),
                              onEmail: () =>
                                  _runOrPreview(widget.onEmailLogin),
                            ),
                          ),
                        ),
                      ),
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
}

class _WelcomeBottomPanel extends StatelessWidget {
  const _WelcomeBottomPanel({
    required this.copy,
    required this.currentPage,
    required this.compact,
    required this.dots,
    required this.onGoogle,
    required this.onApple,
    required this.onCreate,
    required this.onEmail,
  });

  final OpeningCopy copy;
  final int currentPage;
  final bool compact;
  final Widget dots;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onCreate;
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          image: true,
          label: 'SOUL',
          child: ExcludeSemantics(
            child: Image.asset(
              '$uploadedOpeningAssetRoot/onboarding/soulLogo.webp',
              width: compact ? 98 : 112,
              cacheWidth: 384,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        SizedBox(height: compact ? 10 : 14),
        AnimatedSwitcher(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _WelcomeHeadline(
            key: ValueKey('${copy.languageCode}-$currentPage'),
            highlight: copy.slideHighlight,
            rest: copy.slideRest[currentPage],
            showHeart: currentPage == 0,
            compact: compact,
          ),
        ),
        SizedBox(height: compact ? 9 : 12),
        Text(
          copy.description,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 12.5 : 14,
            height: 1.35,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: compact ? 12 : 16),
        Semantics(
          label: 'Page ${currentPage + 1} of 3',
          child: ExcludeSemantics(child: dots),
        ),
        SizedBox(height: compact ? 12 : 16),
        _WelcomeActionBar(
          copy: copy,
          onGoogle: onGoogle,
          onApple: onApple,
          onCreate: onCreate,
        ),
        const SizedBox(height: 3),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: TextButton(
              onPressed: onEmail,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              ),
              child: Text(
                copy.emailContinue,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeHeadline extends StatelessWidget {
  const _WelcomeHeadline({
    required this.highlight,
    required this.rest,
    required this.showHeart,
    required this.compact,
    super.key,
  });

  final String highlight;
  final String rest;
  final bool showHeart;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 29.0 : 34.0;
    return Semantics(
      header: true,
      label: '$highlight $rest',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 7 : 9,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: soulLimeAccent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    highlight,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      color: soulInk,
                      fontSize: fontSize,
                      height: 1.02,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                if (showHeart)
                  Container(
                    width: compact ? 38 : 44,
                    height: compact ? 38 : 44,
                    decoration: const BoxDecoration(
                      color: Color(0x55334A08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: soulLimeAccent,
                      size: 23,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              rest,
              maxLines: 3,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                height: 1.02,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeActionBar extends StatelessWidget {
  const _WelcomeActionBar({
    required this.copy,
    required this.onGoogle,
    required this.onApple,
    required this.onCreate,
  });

  final OpeningCopy copy;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final accessibilityLayout =
            textScale >= 1.5 || constraints.maxWidth < 300;

        if (accessibilityLayout) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xCC637F22),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: .20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialCircle(
                      semanticsLabel: 'Continue with Google',
                      asset:
                          '$uploadedOpeningAssetRoot/onboarding/BarGoogle.webp',
                      onTap: onGoogle,
                    ),
                    const SizedBox(width: 12),
                    _SocialCircle(
                      semanticsLabel: 'Continue with Apple',
                      asset:
                          '$uploadedOpeningAssetRoot/onboarding/BarApple.webp',
                      onTap: onApple,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const ValueKey('opening-create-account'),
                    onPressed: onCreate,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: soulLimeAccent,
                      foregroundColor: soulInk,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      copy.createAccount,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          height: 58,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xCC637F22),
            borderRadius: BorderRadius.circular(29),
            border: Border.all(
              color: Colors.white.withValues(alpha: .20),
            ),
          ),
          child: Row(
            children: [
              _SocialCircle(
                semanticsLabel: 'Continue with Google',
                asset:
                    '$uploadedOpeningAssetRoot/onboarding/BarGoogle.webp',
                onTap: onGoogle,
              ),
              const SizedBox(width: 9),
              _SocialCircle(
                semanticsLabel: 'Continue with Apple',
                asset:
                    '$uploadedOpeningAssetRoot/onboarding/BarApple.webp',
                onTap: onApple,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    key: const ValueKey('opening-create-account'),
                    onPressed: onCreate,
                    style: FilledButton.styleFrom(
                      backgroundColor: soulLimeAccent,
                      foregroundColor: soulInk,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      copy.createAccount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SocialCircle extends StatelessWidget {
  const _SocialCircle({
    required this.semanticsLabel,
    required this.asset,
    required this.onTap,
  });

  final String semanticsLabel;
  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semanticsLabel,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 44,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Image.asset(
                  asset,
                  cacheWidth: 144,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        ),
      );
}
