import 'package:flutter/material.dart';

class AppColors {
  // Pure Black - Mandatory for OLED screens
  static const Color background = Color(0xFF000000);

  // Rack tones (from Amber Stage Commander design system)
  static const Color rackBlack = Color(0xFF0F0C05);
  static const Color rackDark = Color(0xFF1A160B);

  // Surfaces
  static const Color surface = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF2A2412);
  static const Color surfaceHighlight = Color(0xFF222222);

  // Primary - Amber
  static const Color primary = Color(0xFFFFB000);
  static const Color primaryDim = Color(0xFF4A3600);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF666666);

  // Functional
  static const Color alert = Color(0xFFFF3333);
  static const Color mutedRed = Color(0xFF4D1010); // Mute button active bg
  static const Color solo = Color(0xFF00CCFF);
}
