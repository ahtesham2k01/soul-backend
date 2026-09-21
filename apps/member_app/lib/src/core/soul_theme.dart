import 'package:flutter/material.dart';

abstract final class SoulColors {
  static const lime = Color(0xffaeda2a);
  static const limeLight = Color(0xffb8e632);
  static const forest = Color(0xff173105);
  static const forestDeep = Color(0xff0a1b02);
  static const ink = Color(0xff171a19);
  static const muted = Color(0xff7a7f78);
  static const line = Color(0xffe7eae3);
  static const softSurface = Color(0xfff5f6f3);
  static const warmSurface = Color(0xfffafbf7);
}

ThemeData soulTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SoulColors.limeLight,
        primary: SoulColors.limeLight,
        onPrimary: SoulColors.ink,
        surface: Colors.white,
        onSurface: SoulColors.ink,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: SoulColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: 24,
          height: 1.1,
          letterSpacing: -.35,
        ),
        titleLarge: TextStyle(
          color: SoulColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: 21,
          height: 1.15,
        ),
        titleMedium: TextStyle(
          color: SoulColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: SoulColors.ink,
          fontSize: 15,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          color: SoulColors.muted,
          fontSize: 13,
          height: 1.4,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: SoulColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: SoulColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(
          color: Color(0xffb3b7af),
          fontSize: 13,
        ),
        labelStyle: const TextStyle(
          color: SoulColors.ink,
          fontSize: 12,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: SoulColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: SoulColors.limeLight,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xffc83a3a)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: Color(0xffc83a3a),
            width: 1.4,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: SoulColors.limeLight,
          foregroundColor: SoulColors.ink,
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: SoulColors.line,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
