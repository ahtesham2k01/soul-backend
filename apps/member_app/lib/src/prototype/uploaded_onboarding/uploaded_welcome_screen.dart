// ignore_for_file: prefer_interpolation_to_compose_strings, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'uploaded_onboarding_app.dart';
import 'uploaded_profile_onboarding.dart';

const _assetRoot = 'assets/uploaded_onboarding';

class UploadedWelcomeScreen extends StatefulWidget {
  const UploadedWelcomeScreen({super.key});

  @override
  State<UploadedWelcomeScreen> createState() => _UploadedWelcomeScreenState();
}

class _UploadedWelcomeScreenState extends State<UploadedWelcomeScreen> {
  late final PageController _controller;
  int _currentPage = 0;
  String _selectedLanguage = 'English';

  static const _backgrounds = [
    '$_assetRoot/onboarding/slide1/slide1bg.webp',
    '$_assetRoot/onboarding/slide2/slide2bg.webp',
    '$_assetRoot/onboarding/slide3/slide3bg.webp',
  ];

  static const _headings = [
    '$_assetRoot/onboarding/slide1/slide1heading.webp',
    '$_assetRoot/onboarding/slide2/slide2heading.webp',
    '$_assetRoot/onboarding/slide3/slide3heading.webp',
  ];

  static const _languages = [
    ('English', 'English'),
    ('English (UK)', 'English (United Kingdom)'),
    ('Roman Urdu', 'Roman Urdu'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
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
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => FractionallySizedBox(
          heightFactor: 0.66,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select language',
                  style: TextStyle(
                    color: soulInk,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Only launch-ready languages are shown here.',
                  style: TextStyle(color: soulMuted),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: _languages.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final item = _languages[index];
                      final selected = _selectedLanguage == item.$1;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheetState(() => _selectedLanguage = item.$1);
                          setState(() => _selectedLanguage = item.$1);
                          Navigator.of(sheetContext).pop();
                        },
                        title: Text(
                          item.$1,
                          style: const TextStyle(
                            color: soulInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(item.$2),
                        trailing: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected ? soulLime : Colors.transparent,
                            border: Border.all(
                              color: selected ? soulLime : soulLine,
                              width: 1.6,
                            ),
                          ),
                          child: selected
                              ? const Icon(Icons.check_rounded, size: 15)
                              : null,
                        ),
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

  Future<void> _showHelpSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 29,
              backgroundColor: soulLime,
              child: Icon(Icons.info_outline_rounded, color: Colors.black, size: 30),
            ),
            SizedBox(height: 14),
            Text(
              'Welcome to SOUL',
              style: TextStyle(
                color: soulInk,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create an account or log in. This APK is a backend-free onboarding preview, so no email, Apple or Google request leaves your phone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: soulMuted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  void _openEmail({required bool registration}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UploadedEmailScreen(
          registration: registration,
          selectedLanguage: _selectedLanguage,
        ),
      ),
    );
  }

  void _socialContinue() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UploadedProfileOnboardingScreen(
          selectedLanguage: _selectedLanguage,
        ),
      ),
    );
  }

  Widget _buildSlide(int index) => AnimatedBuilder(
        animation: _controller,
        child: SizedBox.expand(
          child: Image.asset(
            _backgrounds[index],
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
          ),
        ),
        builder: (context, child) {
          var opacity = 1.0;
          var scale = 1.0;
          if (_controller.hasClients && _controller.position.haveDimensions) {
            final page = _controller.page ?? _controller.initialPage.toDouble();
            final diff = (page - index).abs();
            opacity = (1 - (diff * 0.65)).clamp(0, 1);
            scale = (1 - (diff * 0.04)).clamp(0.96, 1);
          }
          return Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: child),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 700;
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
        body: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              physics: const BouncingScrollPhysics(),
              itemCount: _backgrounds.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (_, index) => _buildSlide(index),
            ),
            SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: compact ? 12 : 18,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: _showLanguageSelector,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.language_rounded, color: Colors.white, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedLanguage,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Help',
                          onPressed: _showHelpSheet,
                          icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: compact ? 258 : 288,
                    child: Image.asset(
                      '$_assetRoot/onboarding/soulLogo.webp',
                      width: 112,
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: compact ? 170 : 190,
                    child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 280),
                      child: Image.asset(
                        _headings[_currentPage],
                        key: ValueKey(_currentPage),
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: compact ? 128 : 140,
                    child: const Text(
                      'The right person can change your life. Your journey to that moment starts here.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.38,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: compact ? 96 : 104,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _backgrounds.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 22 : 8,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? soulLime : Colors.white30,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16 + MediaQuery.paddingOf(context).bottom,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 55,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  '$_assetRoot/onboarding/barBg.webp',
                                  fit: BoxFit.fill,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Row(
                                  children: [
                                    Semantics(
                                      button: true,
                                      label: 'Continue with Google',
                                      child: GestureDetector(
                                        onTap: _socialContinue,
                                        child: Image.asset(
                                          '$_assetRoot/onboarding/BarGoogle.webp',
                                          width: 42,
                                          height: 42,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Semantics(
                                      button: true,
                                      label: 'Continue with Apple',
                                      child: GestureDetector(
                                        onTap: _socialContinue,
                                        child: Image.asset(
                                          '$_assetRoot/onboarding/BarApple.webp',
                                          width: 42,
                                          height: 42,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Semantics(
                                        button: true,
                                        label: 'Create Account',
                                        child: GestureDetector(
                                          onTap: () => _openEmail(registration: true),
                                          child: SizedBox(
                                            height: 42,
                                            child: Image.asset(
                                              '$_assetRoot/onboarding/barCreateAccountButton.webp',
                                              fit: BoxFit.fill,
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
                        const SizedBox(height: 5),
                        TextButton(
                          onPressed: () => _openEmail(registration: false),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text(
                            'Already have an account? Continue with Email',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
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

class UploadedEmailScreen extends StatefulWidget {
  const UploadedEmailScreen({
    required this.registration,
    required this.selectedLanguage,
    super.key,
  });

  final bool registration;
  final String selectedLanguage;

  @override
  State<UploadedEmailScreen> createState() => _UploadedEmailScreenState();
}

class _UploadedEmailScreenState extends State<UploadedEmailScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _code = TextEditingController();
  bool _codeSent = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    if (!_codeSent) {
      final value = _email.text.trim();
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid email address.')),
        );
        return;
      }
      HapticFeedback.selectionClick();
      setState(() => _codeSent = true);
      return;
    }

    if (_code.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use 123456 for this preview.')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    if (widget.registration) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => UploadedProfileOnboardingScreen(
            selectedLanguage: widget.selectedLanguage,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const _LoginPreviewScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.registration ? 'Welcome to SOUL!' : 'Welcome back';
    final subtitle = widget.registration
        ? 'Where meaningful connections come alive.'
        : 'Continue to your existing account.';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Spacer(),
                  const Icon(Icons.info_outline_rounded, size: 22),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: soulInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: soulMuted, fontSize: 12.5)),
              const SizedBox(height: 28),
              if (!_codeSent) ...[
                const Text(
                  'Email',
                  style: TextStyle(fontSize: 13, color: soulInk, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _email,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Enter email address',
                    prefixIcon: Icon(Icons.mail_outline_rounded, color: soulMuted),
                  ),
                  onSubmitted: (_) => _continue(),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: soulLine),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mail_outline_rounded, color: soulMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _email.text.trim(),
                          style: const TextStyle(color: soulInk, fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _codeSent = false),
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Verification code',
                  style: TextStyle(fontSize: 13, color: soulInk, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _code,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: 'Use 123456',
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: soulMuted),
                  ),
                  onSubmitted: (_) => _continue(),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Preview only: no message is sent and no backend is contacted.',
                  style: TextStyle(color: soulMuted, fontSize: 11.5),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _continue,
                  child: Text(_codeSent ? 'Verify & Continue' : 'Continue'),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text.rich(
                  TextSpan(
                    text: 'By continuing you agree to our ',
                    style: TextStyle(fontSize: 11, color: soulInk),
                    children: [
                      TextSpan(text: 'Terms', style: TextStyle(decoration: TextDecoration.underline)),
                      TextSpan(text: ' and '),
                      TextSpan(text: 'Privacy Policy', style: TextStyle(decoration: TextDecoration.underline)),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginPreviewScreen extends StatelessWidget {
  const _LoginPreviewScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 72, color: soulLime),
                  const SizedBox(height: 18),
                  const Text(
                    'Login flow reached',
                    style: TextStyle(color: soulInk, fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'For this onboarding-only APK, existing-account login stops here. The backend will be wired later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: soulMuted, height: 1.45),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}