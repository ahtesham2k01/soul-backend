// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

import 'uploaded_splash_screen.dart';

const soulLime = Color(0xFFB4D63C);
const soulDeepGreen = Color(0xFF071B05);
const soulInk = Color(0xFF20242C);
const soulMuted = Color(0xFF8A9099);
const soulLine = Color(0xFFE5E7EB);

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
      title: 'SOUL Onboarding',
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
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: soulLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: soulLime, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: soulLime,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      home: const UploadedSplashScreen(),
    );
  }
}