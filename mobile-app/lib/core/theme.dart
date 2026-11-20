import 'package:flutter/material.dart';

/// Valley Express Flutter Theme — Industrial Utility & Food App Design System
/// Derived from Figma reference screenshots:
///   Background: #FFFFFF
///   Dark Navy:   #181C2E / #1F2A44 (Headers, title text, dark pills)
///   Orange:      #FF7622 / #FF6B1A (Primary accent, action buttons, active chips)
///   Brand Blue:  #003893 (Nepal Flag Blue, trust & verified badges)
///   Soft Input:  #F0F5FA / #F6F8FA (Search bar, form input backgrounds)
///   Border:      #E2E8F0 / #D1D5DB
///   Muted Text:  #646982
/// Touch targets: >= 48px on mobile, >= 56px for rider screens
class AppTheme {
  // Brand Palette Tokens
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color scaffoldBg = Color(0xFFFAFBFC);
  static const Color textMain = Color(0xFF181C2E);
  static const Color textMuted = Color(0xFF646982);
  static const Color textSubtle = Color(0xFFA0A5BA);
  static const Color accent = Color(0xFFFF7622); // Figma vibrant food orange
  static const Color orangePrimary = Color(0xFFFF6B1A);
  static const Color darkNavy = Color(0xFF181C2E);
  static const Color brandBlue = Color(0xFF003893); // Nepal Flag Blue
  static const Color border = Color(0xFFE2E8F0);
  static const Color inputBg = Color(0xFFF0F5FA); // Soft gray-blue container
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Backward-compatible alias helpers
  static const Color primaryColor = accent;
  static const Color cardBg = background;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: scaffoldBg,
    primaryColor: brandBlue,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: brandBlue,
      onPrimary: background,
      secondary: accent,
      onSecondary: background,
      error: danger,
      onError: background,
      surface: surface,
      onSurface: textMain,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textMain,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        color: textMain,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: textMain),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: background,
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textMain,
        minimumSize: const Size(double.infinity, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: const BorderSide(color: border, width: 1.2),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textMuted,
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSubtle,
      ),
    ),
  );
}
