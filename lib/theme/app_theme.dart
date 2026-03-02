import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  /* 
   *  PALETA BASE — EVENTCONTROL
    */

  // ---------- DARK THEME ----------
  static const Color darkBackground = Color(0xFF0B0F1A);
  static const Color darkBackgroundSecondary = Color(0xFF11172A);
  static const Color darkSurface = Color(0xFF161E36);

  static const Color neonCyan = Color(0xFF27F5E0);
  static const Color neonCyanVariant = Color(0xFF1CC8D4);

  static const Color neonViolet = Color(0xFF9B7CFF);
  static const Color neonVioletVariant = Color(0xFF7B5CFF);

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFC7C9D9);
  static const Color darkTextDisabled = Color(0xFF7A7F9D);

  // Estados
  static const Color success = Color(0xFF2DFF9B);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFFF5C5C);
  static const Color info = Color(0xFF4DA3FF);

  // ---------- LIGHT THEME ----------
  static const Color lightBackground = Color(0xFFF5F7FB);
  static const Color lightBackgroundSecondary = Color(0xFFECEFF6);
  static const Color lightSurface = Color(0xFFFFFFFF);

  static const Color lightPrimary = Color(0xFF00BFD4);
  static const Color lightPrimaryVariant = Color(0xFF0097A7);

  static const Color lightSecondary = Color(0xFF6A5CFF);
  static const Color lightSecondaryVariant = Color(0xFF4F46E5);

  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextDisabled = Color(0xFF94A3B8);

   // DARK THEME

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,

    primaryColor: neonCyan,
    colorScheme: const ColorScheme.dark(
      primary: neonCyan,
      secondary: neonViolet,
      background: darkBackground,
      surface: darkSurface,
      error: error,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackgroundSecondary,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: darkTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: neonCyan),
    ),

    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 6,
      shadowColor: neonCyan.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonCyan,
        foregroundColor: Colors.black,
        elevation: 6,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: darkTextPrimary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: darkTextPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: darkTextSecondary,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: darkTextSecondary,
        fontSize: 14,
      ),
      labelLarge: TextStyle(
        color: darkTextPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkBackgroundSecondary,
      labelStyle: const TextStyle(color: darkTextSecondary),
      hintStyle: const TextStyle(color: darkTextDisabled),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: neonCyan, width: 1.5),
      ),
    ),
  );
  // LIGHT THEME

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,

    primaryColor: lightPrimary,
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      secondary: lightSecondary,
      background: lightBackground,
      surface: lightSurface,
      error: error,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: lightSurface,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: lightTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: lightPrimary),
    ),

    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: lightTextPrimary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: lightTextPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: lightTextSecondary,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: lightTextSecondary,
        fontSize: 14,
      ),
      labelLarge: TextStyle(
        color: lightTextPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightBackgroundSecondary,
      labelStyle: const TextStyle(color: lightTextSecondary),
      hintStyle: const TextStyle(color: lightTextDisabled),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lightPrimary, width: 1.5),
      ),
    ),
  );
}
