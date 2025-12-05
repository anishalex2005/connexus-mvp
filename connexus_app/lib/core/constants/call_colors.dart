import 'package:flutter/material.dart';

/// Colors specifically for the call screens.
class CallColors {
  CallColors._();

  // Background gradient colors.
  static const Color backgroundStart = Color(0xFF1A1A2E);
  static const Color backgroundEnd = Color(0xFF16213E);

  // Action button colors.
  static const Color answerGreen = Color(0xFF4CAF50);
  static const Color answerGreenLight = Color(0xFF81C784);
  static const Color declineRed = Color(0xFFE53935);
  static const Color declineRedLight = Color(0xFFEF5350);

  // Text colors.
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFFB0B0B0);

  // Button background.
  static const Color buttonBackground = Color(0xFF2D2D44);
  static const Color buttonBackgroundActive = Color(0xFF3D3D54);

  // Avatar placeholder.
  static const Color avatarBackground = Color(0xFF3D3D54);
  static const Color avatarIcon = Color(0xFF808080);

  // Slide to answer.
  static const Color slideTrack = Color(0xFF2D2D44);
  static const Color slideThumb = answerGreen;
  static const Color slideThumbIcon = Colors.white;
}
