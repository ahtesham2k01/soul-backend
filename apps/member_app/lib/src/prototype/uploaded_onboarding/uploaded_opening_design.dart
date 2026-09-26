import 'package:flutter/material.dart';

const soulLime = Color(0xFFB3D63B);
const soulLimeAccent = Color(0xFFC5F043);
const soulDeepGreen = Color(0xFF071B05);
const soulInk = Color(0xFF20242C);
const soulMuted = Color(0xFF8A9099);
const soulLine = Color(0xFFE5E7EB);

const uploadedOpeningAssetRoot = 'assets/uploaded_onboarding';

abstract final class OpeningMotion {
  static const splashHold = Duration(milliseconds: 900);
  static const globeSpin = Duration(milliseconds: 1650);
  static const settlePause = Duration(milliseconds: 180);
  static const contentReveal = Duration(milliseconds: 900);
  static const finalHold = Duration(milliseconds: 520);
  static const globeSequence = Duration(milliseconds: 3250);
  static const reducedSequence = Duration(milliseconds: 760);
  static const route = Duration(milliseconds: 360);
  static const reducedReveal = Duration(milliseconds: 300);
  static const reducedHold = Duration(milliseconds: 460);
}

class OpeningCopy {
  const OpeningCopy({
    required this.languageCode,
    required this.introHighlight,
    required this.introRest,
    required this.slideHighlight,
    required this.slideRest,
    required this.description,
    required this.createAccount,
    required this.emailContinue,
    required this.selectLanguage,
    required this.helpTitle,
    required this.helpBody,
    required this.previewEnd,
    required this.skipIntroLabel,
    required this.skipIntroHint,
    required this.nearbyLabel,
    required this.workingLabel,
  });

  final String languageCode;
  final String introHighlight;
  final String introRest;
  final String slideHighlight;
  final List<String> slideRest;
  final String description;
  final String createAccount;
  final String emailContinue;
  final String selectLanguage;
  final String helpTitle;
  final String helpBody;
  final String previewEnd;
  final String skipIntroLabel;
  final String skipIntroHint;
  final String nearbyLabel;
  final String workingLabel;
}

OpeningCopy openingCopyFor(String rawCode) {
  final code = rawCode.toLowerCase();
  if (code == 'ur') {
    return const OpeningCopy(
      languageCode: 'ur',
      introHighlight: 'Apni',
      introRest: 'Khushgawar Kahani Dhoondhein',
      slideHighlight: 'Swipe karke Apna',
      slideRest: [
        'Sacha Soul Match Paayein',
        'Mustaqbil ka Humsafar Dhoondhein',
        'Bharose ka Rishta Banayein',
      ],
      description:
          'Sahi insan aap ki zindagi badal sakta hai. Us lamhe tak ka safar yahan se shuru hota hai.',
      createAccount: 'Account Banayein',
      emailContinue: 'Email se Login karein',
      selectLanguage: 'Language select karein',
      helpTitle: 'SOUL mein khush aamdeed',
      helpBody:
          'Ye APK sirf opening experience review karne ke liye hai: splash, animated globe aur teen welcome slides.',
      previewEnd:
          'Opening preview yahin khatam hota hai — account flow jaan boojh kar include nahi kiya gaya.',
      skipIntroLabel: 'Intro skip karein',
      skipIntroHint: 'Welcome screens par jane ke liye double tap karein.',
      nearbyLabel: 'Aap ke qareeb log',
      workingLabel: 'Kaam jaari hai',
    );
  }

  return OpeningCopy(
    languageCode: code == 'en-gb' ? 'en-GB' : 'en',
    introHighlight: 'Swipe to Your',
    introRest: 'Happily Ever After',
    slideHighlight: 'Swipe to Your',
    slideRest: const [
      'True Soul Match',
      'Future Life Partner',
      'True Trust Bond',
    ],
    description:
        'The right person can change your life. Your journey to that moment starts here.',
    createAccount: 'Create Account',
    emailContinue: 'Continue with Email',
    selectLanguage: 'Select language',
    helpTitle: 'Welcome to SOUL',
    helpBody:
        'This APK is only for reviewing the opening experience: splash, animated globe and the three welcome slides.',
    previewEnd:
        'Opening preview ends here — account flow is intentionally not included.',
    skipIntroLabel: 'Skip intro',
    skipIntroHint: 'Double tap to continue to the welcome screens.',
    nearbyLabel: 'People near you',
    workingLabel: 'In progress',
  );
}

String detectOpeningLanguageCode() {
  final locales = WidgetsBinding.instance.platformDispatcher.locales;
  for (final locale in locales) {
    if (locale.languageCode.toLowerCase() == 'ur') return 'ur';
  }
  for (final locale in locales) {
    if (locale.languageCode.toLowerCase() == 'en' &&
        locale.countryCode?.toUpperCase() == 'GB') {
      return 'en-GB';
    }
  }
  return 'en';
}

Route<void> openingRoute(BuildContext context, Widget page) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return PageRouteBuilder<void>(
    pageBuilder: (_, animation, __) => page,
    transitionDuration: reduceMotion ? Duration.zero : OpeningMotion.route,
    reverseTransitionDuration:
        reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
    transitionsBuilder: (_, animation, __, child) {
      if (reduceMotion) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.01, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
