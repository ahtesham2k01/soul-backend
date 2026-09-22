
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/soul_theme.dart';
import '../features/launch/launch_screen.dart';
import 'prototype_home.dart';
import 'prototype_models.dart';
import 'prototype_onboarding.dart';

class SoulPrototypeApp extends StatefulWidget {
  const SoulPrototypeApp({super.key});

  @override
  State<SoulPrototypeApp> createState() => _SoulPrototypeAppState();
}

class _SoulPrototypeAppState extends State<SoulPrototypeApp> {
  final PrototypeController controller = PrototypeController();

  @override
  void initState() {
    super.initState();
    controller.addListener(_refresh);
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SOUL',
        theme: _prototypeTheme(),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        ),
        home: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: switch (controller.stage) {
            PrototypeStage.launch => LaunchScreen(
                key: const ValueKey('prototype-launch'),
                labels: controller.bootstrap,
                onFinished: () =>
                    controller.setStage(PrototypeStage.welcome),
              ),
            PrototypeStage.welcome => PrototypeWelcomeScreen(
                key: const ValueKey('prototype-welcome'),
                controller: controller,
              ),
            PrototypeStage.auth => PrototypeEmailAuthScreen(
                key: const ValueKey('prototype-auth'),
                controller: controller,
              ),
            PrototypeStage.onboarding => PrototypeOnboardingScreen(
                key: const ValueKey('prototype-onboarding'),
                controller: controller,
              ),
            PrototypeStage.home => PrototypeMainShell(
                key: const ValueKey('prototype-home'),
                controller: controller,
              ),
          },
        ),
      );
}

ThemeData _prototypeTheme() {
  final base = soulTheme();
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.white,
      foregroundColor: SoulColors.ink,
      surfaceTintColor: Colors.white,
      titleTextStyle: TextStyle(
        color: SoulColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SoulColors.limeLight,
        foregroundColor: SoulColors.ink,
        minimumSize: const Size(0, 50),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SoulColors.ink,
        minimumSize: const Size(0, 50),
        side: const BorderSide(color: SoulColors.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: const Color(0xfffafbf8),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: SoulColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: SoulColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: SoulColors.lime,
          width: 1.5,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: SoulColors.ink,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  );
}

class PrototypeWelcomeScreen extends StatefulWidget {
  const PrototypeWelcomeScreen({
    required this.controller,
    super.key,
  });

  final PrototypeController controller;

  @override
  State<PrototypeWelcomeScreen> createState() =>
      _PrototypeWelcomeScreenState();
}

class _PrototypeWelcomeScreenState extends State<PrototypeWelcomeScreen> {
  final PageController pageController = PageController();
  int page = 0;

  PrototypeController get c => widget.controller;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> _chooseLanguage() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PrototypeHeader(
                title: 'Choose language',
                subtitle:
                    'This preview includes the current launch-target language direction.',
              ),
              const SizedBox(height: 14),
              for (final option in const [
                ('en', 'English'),
                ('en-GB', 'English (UK)'),
                ('ur', 'Roman Urdu'),
              ])
                RadioListTile<String>(
                  value: option.$1,
                  groupValue: c.locale,
                  title: Text(option.$2),
                  onChanged: (value) {
                    if (value == null) return;
                    c.chooseLocale(value);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _socialContinue() {
    HapticFeedback.mediumImpact();
    c.registration = true;
    c.setStage(PrototypeStage.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 700;
    return Scaffold(
      backgroundColor: SoulColors.forestDeep,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            const Positioned.fill(child: _PrototypeWelcomeBackdrop()),
            Positioned.fill(
              child: PageView(
                controller: pageController,
                onPageChanged: (value) => setState(() => page = value),
                children: const [
                  _WelcomeScene(
                    asset: 'assets/design/welcome/globe_art.svg',
                    title: 'People near you',
                    subtitle:
                        'Discover people while keeping exact location private.',
                    icon: Icons.public_rounded,
                  ),
                  _WelcomeScene(
                    asset: 'assets/design/welcome/dashed_heart.svg',
                    title: 'Built around values',
                    subtitle:
                        'Religion, lifestyle, intentions and what matters to you can shape the experience.',
                    icon: Icons.favorite_border_rounded,
                  ),
                  _WelcomeScene(
                    asset: 'assets/design/welcome/heart_bubble.svg',
                    title: 'Safer by design',
                    subtitle:
                        'Verification, private photos, blocking and reporting stay within reach.',
                    icon: Icons.shield_outlined,
                  ),
                ],
              ),
            ),
            Positioned(
              top: compact ? 8 : 14,
              left: 18,
              right: 18,
              child: Row(
                children: [
                  _GlassAction(
                    onTap: _chooseLanguage,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.language_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          c.locale == 'ur' ? 'Roman Urdu' : 'English',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _GlassAction(
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => const SafeArea(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(22, 8, 22, 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PrototypeHeader(
                                title: 'Welcome to SOUL',
                                subtitle:
                                    'A global relationship and matchmaking product built for meaningful connections, privacy and cultural depth.',
                              ),
                              SizedBox(height: 18),
                              Text(
                                'This APK is a backend-free design prototype. Every interaction uses local data so Flutter UX can be reviewed before production APIs are wired back in.',
                                style: TextStyle(
                                  color: SoulColors.muted,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: compact ? 126 : 142,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    'assets/design/welcome/soul_lime.svg',
                    width: 92,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: SoulColors.limeLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      c.t('headline.highlight'),
                      style: const TextStyle(
                        color: SoulColors.ink,
                        fontSize: 27,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.t('headline.rest'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.04,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    c.t('welcome.subtitle'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (var index = 0; index < 3; index++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: page == index ? 22 : 7,
                          height: 5,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: page == index
                                ? SoulColors.limeLight
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 14 + MediaQuery.paddingOf(context).bottom,
              child: Column(
                children: [
                  Row(
                    children: [
                      _SocialButton(
                        asset: 'assets/design/welcome/google.svg',
                        label: c.t('welcome.google'),
                        onTap: _socialContinue,
                      ),
                      const SizedBox(width: 8),
                      _SocialButton(
                        asset: 'assets/design/welcome/apple.svg',
                        label: c.t('welcome.apple'),
                        onTap: _socialContinue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: FilledButton(
                            key: const ValueKey('prototype-create-account'),
                            onPressed: c.beginRegistration,
                            style: FilledButton.styleFrom(
                              shape: const StadiumBorder(),
                            ),
                            child: Text(c.t('welcome.create')),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton(
                      key: const ValueKey('prototype-email-login'),
                      onPressed: c.beginLogin,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: .5),
                        ),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(c.t('welcome.email')),
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

class _PrototypeWelcomeBackdrop extends StatelessWidget {
  const _PrototypeWelcomeBackdrop();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xff608a1d),
              Color(0xff274f0c),
              Color(0xff102903),
              Color(0xff071600),
            ],
            stops: [0, .25, .64, 1],
          ),
        ),
      );
}

class _WelcomeScene extends StatelessWidget {
  const _WelcomeScene({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String asset;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        Positioned(
          top: size.height * .09,
          left: size.width * .11,
          right: size.width * .11,
          child: SizedBox(
            height: size.height * .41,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: .88,
                  child: SvgPicture.asset(
                    asset,
                    width: asset.contains('globe') ? 250 : 215,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: SoulColors.limeLight, size: 17),
                        const SizedBox(width: 7),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: size.height * .47,
          left: 35,
          right: 35,
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .58),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassAction extends StatelessWidget {
  const _GlassAction({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: child,
          ),
        ),
      );
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: SvgPicture.asset(
            asset,
            width: 44,
            height: 44,
          ),
        ),
      );
}

class PrototypeEmailAuthScreen extends StatefulWidget {
  const PrototypeEmailAuthScreen({
    required this.controller,
    super.key,
  });

  final PrototypeController controller;

  @override
  State<PrototypeEmailAuthScreen> createState() =>
      _PrototypeEmailAuthScreenState();
}

class _PrototypeEmailAuthScreenState extends State<PrototypeEmailAuthScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController otp = TextEditingController();
  bool otpSent = false;

  PrototypeController get c => widget.controller;

  @override
  void dispose() {
    email.dispose();
    otp.dispose();
    super.dispose();
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    if (!otpSent) {
      if (!email.text.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid email address.')),
        );
        return;
      }
      HapticFeedback.selectionClick();
      setState(() => otpSent = true);
      return;
    }
    if (otp.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the preview code 123456.')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    c.continueFromAuth();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => c.setStage(PrototypeStage.welcome),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              PrototypeHeader(
                title:
                    c.registration ? 'Create your account' : 'Welcome back',
                subtitle: c.registration
                    ? 'We will use email only to confirm and protect your account.'
                    : 'Enter your email to continue to your existing SOUL profile.',
              ),
              const SizedBox(height: 30),
              if (!otpSent)
                TextField(
                  key: const ValueKey('prototype-email-field'),
                  controller: email,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    hintText: 'you@example.com',
                  ),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: SoulColors.softSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mail_outline_rounded,
                        color: SoulColors.forest,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          email.text,
                          style: const TextStyle(
                            color: SoulColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => otpSent = false),
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('prototype-otp-field'),
                  controller: otp,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Verification code',
                    hintText: 'Use 123456 for this preview',
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('prototype-auth-continue'),
                  onPressed: _continue,
                  child: Text(
                    otpSent
                        ? (c.registration
                            ? 'Verify & create account'
                            : 'Verify & continue')
                        : 'Continue',
                  ),
                ),
              ),
              if (otpSent) ...[
                const SizedBox(height: 12),
                const Text(
                  'Prototype tip: any 4–6 digit code works. No email is sent and no backend is contacted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SoulColors.muted,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              const PrototypeSectionCard(
                color: Color(0xfff6f9e9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: SoulColors.forest,
                    ),
                    SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'The real app keeps provider tokens and OTPs out of logs and confirms account state on the server. This design prototype intentionally skips network calls.',
                        style: TextStyle(
                          color: SoulColors.forest,
                          height: 1.45,
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
