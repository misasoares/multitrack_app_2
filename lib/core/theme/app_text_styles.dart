import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Mono Styles (Displays, BPM, Clocks)
  static final TextStyle digitalDisplay = GoogleFonts.jetBrainsMono(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    letterSpacing: 1.5,
  );

  static final TextStyle tempoDisplay = GoogleFonts.jetBrainsMono(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Sans Styles (UI, Buttons, Labels)
  static final TextStyle headingS = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle h1 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: 1.2,
  );

  static final TextStyle bodyM = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static final TextStyle buttonLabel = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle labelMuted = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static final TextStyle bodyMuted = GoogleFonts.inter(
    fontSize: 14,
    color: AppColors.textMuted,
  );

  static final TextStyle bodyPrimary = GoogleFonts.inter(
    fontSize: 14,
    color: AppColors.textPrimary,
  );
}
