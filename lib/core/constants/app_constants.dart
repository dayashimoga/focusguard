import 'package:flutter/material.dart';

/// FocusGuard application constants, design tokens, and session configuration parameters.
class AppConstants {
  AppConstants._();

  static const String appName = 'FocusGuard';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Quick session duration presets in minutes
  static const List<int> quickSessionMinutes = [15, 30, 45, 60, 90, 120];

  // Break duration options in minutes
  static const List<int> breakDurationMinutes = [5, 10, 15];

  // Default grace period in seconds before hard enforcement starts
  static const int defaultGracePeriodSeconds = 10;

  // Maximum allowed breaks per session by default
  static const int defaultMaxBreaksPerSession = 2;

  // Delayed override countdown cooldown in seconds
  static const int defaultOverrideCooldownSeconds = 30;

  // Emergency safety confirmation phrase
  static const String defaultSafetyPhrase =
      'I deliberately choose to exit focus';

  // Standard Colors
  static const Color primary = Color(0xFF6366F1); // Vibrant Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  static const Color accent = Color(0xFF10B981); // Emerald Green
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Crimson Red
  static const Color emergency = Color(0xFFDC2626); // Deep Emergency Red

  // Dark Theme Obsidian Palette
  static const Color darkBg = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF21262D);
  static const Color darkBorder = Color(0xFF30363D);
  static const Color textPrimaryDark = Color(0xFFF0F6FC);
  static const Color textSecondaryDark = Color(0xFF8B949E);

  // Light Theme Palette
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Storage and Channel keys
  static const String methodChannelName = 'com.focusguard/enforcement';
  static const String databaseName = 'focusguard.db';
  static const int databaseVersion = 1;
}
