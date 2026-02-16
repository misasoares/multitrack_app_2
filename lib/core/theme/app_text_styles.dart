import 'package:flutter/material.dart';
import 'app_colors.dart';

// Note: Ensure google_fonts package is added or fonts are imported in pubspec.yaml
// for now we use standard TextStyle, assuming fonts will be loaded.

class AppTextStyles {
  static const String fontMono = 'JetBrains Mono';
  static const String fontSans = 'Inter';

  // Mono Styles (Displays, BPM, Clocks)
  static const TextStyle digitalDisplay = TextStyle(
    fontFamily: fontMono,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    letterSpacing: 1.5,
  );

  static const TextStyle tempoDisplay = TextStyle(
    fontFamily: fontMono,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Sans Styles (UI, Buttons, Labels)
  static const TextStyle headingS = TextStyle(
    fontFamily: fontSans,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyM = TextStyle(
    fontFamily: fontSans,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontFamily: fontSans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, // Or darker if on primary background
  );

  static const TextStyle labelMuted = TextStyle(
    fontFamily: fontSans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
}
