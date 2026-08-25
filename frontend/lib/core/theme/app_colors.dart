import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Blue Primary Palette (#003087)
  static const Color primary = Color(0xFF003087); // Brand Blue
  static const Color primaryLight = Color(0xFF3B5BA5); // Lighter Brand Blue
  static const Color primaryDark = Color(0xFF002060); // Deep Brand Blue
  static const Color primarySurface = Color(0xFFE6EBF5); // Light Blue Surface
  static const Color primaryContainer = Color(0xFFCCD6EB);

  // Secondary Palette
  static const Color secondary = Color(0xFF003087); // Brand Blue
  static const Color secondaryLight = Color(0xFF3B5BA5); // Lighter Brand Blue
  static const Color secondaryDark = Color(0xFF002060); // Deep Brand Blue
  static const Color secondarySurface = Color(0xFFE6EBF5);

  static const Color accent = Color(0xFFF57C00);
  static const Color accentLight = Color(0xFFFFB74D);
  static const Color accentSurface = Color(0xFFFFF3E0);

  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color cardBackground = Colors.white;

  static const List<Color> primaryGradient = [
    Color(0xFF003087), // Brand Blue
    Color(0xFF3B5BA5), // Lighter Brand Blue
  ];
  static const List<Color> loginGradient = [
    Color(0xFF003087),
    Color(0xFF002869),
    Color(0xFF002060),
  ];
  static const List<Color> oceanGradient = [
    Color(0xFF003087),
    Color(0xFF002869),
  ];

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnDark = Color(0xFFF8FAFC);

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocused = Color(0xFF003087);
  static const Color divider = Color(0xFFE2E8F0);

  static const Color error = Color(0xFFD32F2F);
  static const Color danger = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color successSurface = Color(0xFFE8F5E9);
  static const Color errorSurface = Color(0xFFFFEBEE);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57F17);
  static const Color warningLight = Color(0xFFFFFDE7);
  static const Color info = Color(0xFF0277BD);
  static const Color infoLight = Color(0xFFE1F5FE);

  static const Color roleSuperAdmin = Color(0xFF002060);
  static const Color roleAgent = Color(0xFF003087);
  static const Color roleStaff = Color(0xFF3B5BA5);
  static const Color roleBuyer = Color(0xFFC62828);
  static const Color roleOwner = Color(0xFF002869);

  static const Color statusActive = Color(0xFF2E7D32);
  static const Color statusInactive = Color(0xFF616161);
  static const Color statusPending = Color(0xFFF57F17);
  static const Color statusPaid = Color(0xFF003087);
  static const Color statusOverdue = Color(0xFFD32F2F);

  static const Color glassBackground = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  static const Color shadow = Color(0x0D000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color shadowPurple = Color(0x26003087);
  static const Color shadowBlue = Color(0x26003087);
}
