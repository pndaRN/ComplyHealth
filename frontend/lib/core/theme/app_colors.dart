import 'package:flutter/material.dart';

/// App color palette for light and dark themes
/// Medical app color scheme with blue primary, purple secondary, emerald tertiary
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors (Brand Blue - Logo Color)
  static const Color primaryLight = Color(0xFF0000CC); // brand blue
  static const Color primaryDark = Color(0xFF668CFF); // lighter for dark mode

  // Secondary Colors (Purple - Health Tech)
  static const Color secondaryLight = Color(0xFF6600CC); // deep purple
  static const Color secondaryDark = Color(0xFFA366FF); // lighter for dark mode

  // Tertiary Colors (Emerald - Health & Wellness)
  static const Color tertiaryLight = Color(0xFF059669); // emerald-600
  static const Color tertiaryDark = Color(0xFF34D399); // emerald-400

  // Error Colors (Red - Medical Standard)
  static const Color errorLight = Color(0xFFDC2626); // red-600
  static const Color errorDark = Color(0xFFF87171); // red-400

  // Background Colors
  static const Color backgroundLight = Color(0xFFF8FAFC); // slate-50 (slightly off-white)
  static const Color backgroundDark = Color(0xFF0F172A); // slate-900

  // Surface Colors (cards, elevated content)
  static const Color surfaceLight = Color(0xFFFFFFFF); // white (cards pop against background)
  static const Color surfaceDark = Color(0xFF1E293B); // slate-800

  // Surface Variant Colors (secondary surfaces)
  static const Color surfaceVariantLight = Color(0xFFE2E8F0); // slate-200 (more visible)
  static const Color surfaceVariantDark = Color(0xFF334155); // slate-700

  // Outline Colors (Borders & Dividers) - more visible in light mode
  static const Color outlineLight = Color(0xFFCBD5E1); // slate-300 (stronger borders)
  static const Color outlineDark = Color(0xFF475569); // slate-600

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A); // slate-900
  static const Color textPrimaryDark = Color(0xFFF1F5F9); // slate-100

  static const Color textSecondaryLight = Color(0xFF475569); // slate-600 (darker for readability)
  static const Color textSecondaryDark = Color(0xFF94A3B8); // slate-400
}
