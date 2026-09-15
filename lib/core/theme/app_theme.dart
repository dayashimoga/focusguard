import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Premium adaptive design system for FocusGuard.
/// Meets accessibility contrast standards (WCAG AAA/AA) and supports Light, Dark, and OLED Obsidian modes.
class AppTheme {
  AppTheme._();

  /// Obsidian Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppConstants.darkBg,
      primaryColor: AppConstants.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.primary,
        onPrimary: Colors.white,
        secondary: AppConstants.accent,
        onSecondary: Colors.white,
        surface: AppConstants.darkSurface,
        onSurface: AppConstants.textPrimaryDark,
        error: AppConstants.error,
        onError: Colors.white,
      ),
      cardTheme: CardTheme(
        color: AppConstants.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppConstants.darkBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.darkBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppConstants.textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppConstants.textPrimaryDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.textPrimaryDark,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppConstants.darkBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.darkCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.primary, width: 2),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppConstants.primary,
        inactiveTrackColor: AppConstants.darkBorder,
        thumbColor: AppConstants.primary,
        overlayColor: Color(0x336366F1),
        trackHeight: 6,
      ),
    );
  }

  /// Crisp Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppConstants.lightBg,
      primaryColor: AppConstants.primary,
      colorScheme: const ColorScheme.light(
        primary: AppConstants.primary,
        onPrimary: Colors.white,
        secondary: AppConstants.accent,
        onSecondary: Colors.white,
        surface: AppConstants.lightSurface,
        onSurface: AppConstants.textPrimaryLight,
        error: AppConstants.error,
        onError: Colors.white,
      ),
      cardTheme: CardTheme(
        color: AppConstants.lightSurface,
        elevation: 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppConstants.lightBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.lightBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppConstants.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppConstants.textPrimaryLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.textPrimaryLight,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppConstants.lightBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.lightCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.primary, width: 2),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppConstants.primary,
        inactiveTrackColor: AppConstants.lightBorder,
        thumbColor: AppConstants.primary,
        overlayColor: Color(0x336366F1),
        trackHeight: 6,
      ),
    );
  }
}
