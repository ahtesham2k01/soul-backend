import 'package:flutter/material.dart';

import 'uploaded_opening_design.dart';
export 'uploaded_opening_design.dart';
import 'uploaded_splash_screen.dart';

class SoulOnboardingPreviewApp extends StatelessWidget {
  const SoulOnboardingPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: soulLime,
      brightness: Brightness.light,
      primary: soulLime,
      surface: Colors.white,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SOUL',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: soulInk,
            fontSize: 28,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          titleMedium: TextStyle(
            color: soulInk,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: TextStyle(
            color: soulMuted,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: soulInk,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: const UploadedSplashScreen(),
    );
  }
}
