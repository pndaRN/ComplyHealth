import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App typography configuration
/// Poppins: Headings (Display, Headline, TitleLarge)
/// Raleway: Body text (TitleMedium/Small, Body, Label)
class AppTextTheme {
  AppTextTheme._(); // Private constructor

  /// Light theme text styles
  static TextTheme lightTextTheme = TextTheme(
    // DISPLAY STYLES - Poppins (Largest headings)
    displayLarge: GoogleFonts.poppins(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      color: AppColors.textPrimaryLight,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimaryLight,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimaryLight,
    ),

    // HEADLINE STYLES - Poppins (Section headings)
    headlineLarge: GoogleFonts.poppins(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimaryLight,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimaryLight,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimaryLight,
    ),

    // TITLE STYLES - Mixed
    titleLarge: GoogleFonts.poppins(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: AppColors.textPrimaryLight,
    ),
    titleMedium: GoogleFonts.raleway(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      color: AppColors.textPrimaryLight,
    ),
    titleSmall: GoogleFonts.raleway(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: AppColors.textPrimaryLight,
    ),

    // BODY STYLES - Raleway (Main content text)
    bodyLarge: GoogleFonts.raleway(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: AppColors.textPrimaryLight,
    ),
    bodyMedium: GoogleFonts.raleway(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: AppColors.textPrimaryLight,
    ),
    bodySmall: GoogleFonts.raleway(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: AppColors.textSecondaryLight,
    ),

    // LABEL STYLES - Raleway (Buttons, tabs, labels)
    labelLarge: GoogleFonts.raleway(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: AppColors.textPrimaryLight,
    ),
    labelMedium: GoogleFonts.raleway(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: AppColors.textPrimaryLight,
    ),
    labelSmall: GoogleFonts.raleway(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: AppColors.textSecondaryLight,
    ),
  );

  /// Dark theme text styles
  static TextTheme darkTextTheme = TextTheme(
    // DISPLAY STYLES - Poppins (Largest headings)
    displayLarge: GoogleFonts.poppins(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      color: AppColors.textPrimaryDark,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimaryDark,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimaryDark,
    ),

    // HEADLINE STYLES - Poppins (Section headings)
    headlineLarge: GoogleFonts.poppins(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimaryDark,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimaryDark,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimaryDark,
    ),

    // TITLE STYLES - Mixed
    titleLarge: GoogleFonts.poppins(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: AppColors.textPrimaryDark,
    ),
    titleMedium: GoogleFonts.raleway(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      color: AppColors.textPrimaryDark,
    ),
    titleSmall: GoogleFonts.raleway(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: AppColors.textPrimaryDark,
    ),

    // BODY STYLES - Raleway (Main content text)
    bodyLarge: GoogleFonts.raleway(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: AppColors.textPrimaryDark,
    ),
    bodyMedium: GoogleFonts.raleway(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: AppColors.textPrimaryDark,
    ),
    bodySmall: GoogleFonts.raleway(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: AppColors.textSecondaryDark,
    ),

    // LABEL STYLES - Raleway (Buttons, tabs, labels)
    labelLarge: GoogleFonts.raleway(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: AppColors.textPrimaryDark,
    ),
    labelMedium: GoogleFonts.raleway(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: AppColors.textPrimaryDark,
    ),
    labelSmall: GoogleFonts.raleway(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: AppColors.textSecondaryDark,
    ),
  );
}
