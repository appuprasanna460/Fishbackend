import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Display
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.25,
      );

  // Headings
  static TextStyle get headlineLarge => h2;
  static TextStyle get headlineMedium => h3;
  static TextStyle get headlineSmall => h4;

  // Titles
  static TextStyle get titleLarge => h4;
  static TextStyle get titleMedium => labelLarge;
  static TextStyle get titleSmall => labelMedium;

  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.25,
        height: 1.3,
      );

  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get h4 => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // Body
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // Labels
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      );

  // Button
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonSmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
        letterSpacing: 0.5,
      );

  // Caption / Overline
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
      );

  static TextStyle get overline => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 1.5,
      );

  // Numbers / Data
  static TextStyle get metricValue => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get metricValueSmall => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get monospace => const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      );
}
