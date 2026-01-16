import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Modern typography configuration with Inter font
/// Sleek, contemporary text styles for modern gradient themes
class AppTextTheme {
  AppTextTheme._(); // Private constructor

  /// Modern light theme text styles
  static TextTheme lightTextTheme = TextTheme(
    // DISPLAY STYLES - Inter (Largest headings with dramatic weight)
    displayLarge: GoogleFonts.inter(
      fontSize: 64,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.5,
      height: 1.1,
      color: AppColors.textPrimaryLight,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 52,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.0,
      height: 1.15,
      color: AppColors.textPrimaryLight,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 44,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      height: 1.2,
      color: AppColors.textPrimaryLight,
    ),

    // HEADLINE STYLES - Inter (Section headings with refined weights)
    headlineLarge: GoogleFonts.inter(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.25,
      height: 1.25,
      color: AppColors.textPrimaryLight,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 30,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.3,
      color: AppColors.textPrimaryLight,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 26,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.35,
      color: AppColors.textPrimaryLight,
    ),

    // TITLE STYLES - Inter (Enhanced hierarchy with weight variations)
    titleLarge: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.4,
      color: AppColors.textPrimaryLight,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.45,
      color: AppColors.textPrimaryLight,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.5,
      color: AppColors.textPrimaryLight,
    ),

    // BODY STYLES - Inter (Enhanced readability with optimized spacing)
    bodyLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.6,
      color: AppColors.textPrimaryLight,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.5,
      color: AppColors.textPrimaryLight,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.45,
      color: AppColors.textSecondaryLight,
    ),

    // LABEL STYLES - Inter (Modern UI elements with refined spacing)
    labelLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.4,
      color: AppColors.textPrimaryLight,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.35,
      color: AppColors.textPrimaryLight,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.3,
      color: AppColors.textSecondaryLight,
    ),
  );

  /// Modern dark theme text styles
  static TextTheme darkTextTheme = TextTheme(
    // DISPLAY STYLES - Inter (Largest headings with dramatic weight)
    displayLarge: GoogleFonts.inter(
      fontSize: 64,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.5,
      height: 1.1,
      color: AppColors.textPrimaryDark,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 52,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.0,
      height: 1.15,
      color: AppColors.textPrimaryDark,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 44,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      height: 1.2,
      color: AppColors.textPrimaryDark,
    ),

    // HEADLINE STYLES - Inter (Section headings with refined weights)
    headlineLarge: GoogleFonts.inter(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.25,
      height: 1.25,
      color: AppColors.textPrimaryDark,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 30,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.3,
      color: AppColors.textPrimaryDark,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 26,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.35,
      color: AppColors.textPrimaryDark,
    ),

    // TITLE STYLES - Inter (Enhanced hierarchy with weight variations)
    titleLarge: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.4,
      color: AppColors.textPrimaryDark,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.45,
      color: AppColors.textPrimaryDark,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.5,
      color: AppColors.textPrimaryDark,
    ),

    // BODY STYLES - Inter (Enhanced readability with optimized spacing)
    bodyLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.1,
      height: 1.6,
      color: AppColors.textPrimaryDark,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.5,
      color: AppColors.textPrimaryDark,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.45,
      color: AppColors.textSecondaryDark,
    ),

    // LABEL STYLES - Inter (Modern UI elements with refined spacing)
    labelLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.4,
      color: AppColors.textPrimaryDark,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.35,
      color: AppColors.textPrimaryDark,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.3,
      color: AppColors.textSecondaryDark,
    ),
  );

  // === MODERN TYPOGRAPHY VARIANTS ===

  /// Bold display variant for emphasis
  static TextStyle get boldDisplayLight => GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    height: 1.1,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get boldDisplayDark => GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    height: 1.1,
    color: AppColors.textPrimaryDark,
  );

  /// Light body variant for secondary content
  static TextStyle get lightBodyLight => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w300,
    letterSpacing: 0.25,
    height: 1.6,
    color: AppColors.textSecondaryLight,
  );

  static TextStyle get lightBodyDark => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w300,
    letterSpacing: 0.25,
    height: 1.6,
    color: AppColors.textSecondaryDark,
  );

  /// Compact label variant for tight spaces
  static TextStyle get compactLabelLight => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get compactLabelDark => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
    color: AppColors.textPrimaryDark,
  );

  // === TYPOGRAPHY HELPERS ===

  /// Get responsive font size based on screen size
  static double getResponsiveFontSize(
    double baseSize, {
    double scaleFactor = 1.0,
  }) {
    // This can be enhanced with media query logic if needed
    return baseSize * scaleFactor;
  }

  /// Get text style with custom color
  static TextStyle withColor(TextStyle baseStyle, Color color) {
    return baseStyle.copyWith(color: color);
  }

  /// Get text style with custom weight
  static TextStyle withWeight(TextStyle baseStyle, FontWeight weight) {
    return baseStyle.copyWith(fontWeight: weight);
  }

  /// Get text style with opacity
  static TextStyle withOpacity(TextStyle baseStyle, double opacity) {
    return baseStyle.copyWith(
      color: baseStyle.color?.withValues(alpha: opacity),
    );
  }
}
