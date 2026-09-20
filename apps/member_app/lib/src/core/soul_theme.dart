import 'package:flutter/material.dart';

abstract final class SoulColors {
  static const lime = Color(0xffb4d63c);
  static const limeLight = Color(0xffc5f043);
  static const forest = Color(0xff173105);
  static const forestDeep = Color(0xff0a1b02);
  static const ink = Color(0xff151923);
  static const muted = Color(0xff747b8c);
  static const line = Color(0xffe7eaf0);
  static const softSurface = Color(0xfff7f8fa);
}

ThemeData soulTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SoulColors.lime,
        primary: SoulColors.lime,
        surface: Colors.white,
        onSurface: SoulColors.ink,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: SoulColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: 25,
          height: 1.15,
        ),
        bodyMedium: TextStyle(
          color: SoulColors.muted,
          fontSize: 14,
          height: 1.35,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: SoulColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: SoulColors.lime, width: 1.5),
        ),
      ),
    );
