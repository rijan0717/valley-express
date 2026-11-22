import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Valley Express Flutter Design System & Theme
/// Directly derived from the Valley Express interactive redesign prototype
/// Supports Clean Modern Light Theme & Midnight Dark Theme
class AppTheme {
  // Brand Primary & Accent Colors
  static const Color primaryOrange = Color(0xFFFF4B26); // Vibrant red-orange
  static const Color primaryDeep = Color(0xFFE03612);
  static const Color primaryGlow = Color(0x47FF4B26);
  static const Color navyBrand = Color(0xFF003893); // Nepal Flag Navy
  static const Color chilledIce = Color(0xFF0284C7);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color alertRed = Color(0xFFEF4444);

  // Backward-compatible aliases
  static const Color accent = primaryOrange;
  static const Color orangePrimary = primaryOrange;
  static const Color brandBlue = navyBrand;
  static const Color success = successGreen;
  static const Color warning = warningYellow;
  static const Color danger = alertRed;
  static const Color darkNavy = Color(0xFF0F172A);

  // Light Theme Tokens
  static const Color lightBgApp = Color(0xFFF5F7FB);
  static const Color lightBgDevice = Color(0xFFF8FAFC);
  static const Color lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color lightSurfaceHover = Color(0xFFF1F5F9);
  static const Color lightBorderCard = Color(0xFFE2E8F0);
  static const Color lightBorderSubtle = Color(0xFFEDF2F7);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Midnight Dark Theme Tokens
  static const Color darkBgApp = Color(0xFF06080C);
  static const Color darkBgDevice = Color(0xFF0D0F14);
  static const Color darkSurfaceCard = Color(0xFF161922);
  static const Color darkSurfaceHover = Color(0xFF1E2330);
  static const Color darkBorderCard = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)
  static const Color darkBorderSubtle = Color(0x0DFFFFFF); // rgba(255, 255, 255, 0.05)
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF6B7280);

  // Backward compatibility aliases
  static const Color background = lightSurfaceCard;
  static const Color surface = lightSurfaceCard;
  static const Color scaffoldBg = lightBgApp;
  static const Color textMain = lightTextPrimary;
  static const Color textMuted = lightTextSecondary;
  static const Color textSubtle = lightTextMuted;
  static const Color border = lightBorderCard;
  static const Color inputBg = Color(0xFFF0F5FA);
  static const Color cardBg = lightSurfaceCard;
  static const Color primaryColor = primaryOrange;

  /// Typography Helpers
  static TextStyle displayFont({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle bodyFont({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// LIGHT THEME CONFIGURATION
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBgApp,
    primaryColor: primaryOrange,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
    colorScheme: const ColorScheme.light(
      primary: primaryOrange,
      onPrimary: Colors.white,
      secondary: navyBrand,
      onSecondary: Colors.white,
      surface: lightSurfaceCard,
      onSurface: lightTextPrimary,
      error: alertRed,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightSurfaceCard,
      foregroundColor: lightTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: displayFont(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: lightTextPrimary,
      ),
      iconTheme: const IconThemeData(color: lightTextPrimary),
    ),
    cardTheme: CardThemeData(
      color: lightSurfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: lightBorderCard, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: displayFont(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightTextPrimary,
        minimumSize: const Size(double.infinity, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: const BorderSide(color: lightBorderCard, width: 1.2),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: displayFont(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightBgDevice,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      // Fields are defined by their fill alone — no outline in any state,
      // including focus, so nothing draws a ring around the input.
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
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      labelStyle: bodyFont(fontSize: 12, fontWeight: FontWeight.w500, color: lightTextSecondary),
      hintStyle: bodyFont(fontSize: 13, fontWeight: FontWeight.w400, color: lightTextMuted),
    ),
  );

  /// MIDNIGHT DARK THEME CONFIGURATION
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBgApp,
    primaryColor: primaryOrange,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
    colorScheme: const ColorScheme.dark(
      primary: primaryOrange,
      onPrimary: Colors.white,
      secondary: navyBrand,
      onSecondary: Colors.white,
      surface: darkSurfaceCard,
      onSurface: darkTextPrimary,
      error: alertRed,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurfaceCard,
      foregroundColor: darkTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: displayFont(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: darkTextPrimary,
      ),
      iconTheme: const IconThemeData(color: darkTextPrimary),
    ),
    cardTheme: CardThemeData(
      color: darkSurfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: darkBorderCard, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: displayFont(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkTextPrimary,
        minimumSize: const Size(double.infinity, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: const BorderSide(color: darkBorderCard, width: 1.2),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: displayFont(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkBgDevice,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      // Borderless to match the light theme; the fill carries the field.
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
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      labelStyle: bodyFont(fontSize: 12, fontWeight: FontWeight.w500, color: darkTextSecondary),
      hintStyle: bodyFont(fontSize: 13, fontWeight: FontWeight.w400, color: darkTextMuted),
    ),
  );
}
