import 'package:flutter/material.dart';

/// ConnexUS App Color Palette
///
/// Shared brand and semantic colors used across the app.
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // === Brand Colors ===
  static const Color primary = Color(0xFF2563EB); // Blue 600
  static const Color primaryLight = Color(0xFF3B82F6); // Blue 500
  static const Color primaryDark = Color(0xFF1D4ED8); // Blue 700

  static const Color secondary = Color(0xFF7C3AED); // Violet 600
  static const Color secondaryLight = Color(0xFF8B5CF6); // Violet 500

  // === Background Colors ===
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate 100

  // === Text Colors ===
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White

  // === Status Colors ===
  static const Color success = Color(0xFF22C55E); // Green 500
  static const Color successLight = Color(0xFFDCFCE7); // Green 100
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorLight = Color(0xFFFEE2E2); // Red 100
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoLight = Color(0xFFDBEAFE); // Blue 100

  // === Border Colors ===
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderFocused = Color(0xFF2563EB); // Primary
  static const Color borderError = Color(0xFFEF4444); // Error

  // === Input Colors ===
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputDisabled = Color(0xFFF1F5F9); // Slate 100

  // === Misc ===
  static const Color divider = Color(0xFFE2E8F0); // Slate 200
  static const Color shadow = Color(0x1A000000); // 10% black
  static const Color overlay = Color(0x80000000); // 50% black
}


