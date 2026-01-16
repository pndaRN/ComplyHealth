import 'package:flutter/material.dart';

/// Modern gradient color palette for sleek, contemporary themes
/// Maintains #0000CC as primary brand color while adding sophisticated gradients
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // === PRIMARY COLORS (Brand Blue - #0000CC with gradients) ===
  static const Color primaryLight = Color(0xFF0000CC); // brand blue
  static const Color primaryDark = Color(0xFF668CFF); // lighter for dark mode

  // Primary gradient colors
  static const Color primaryGradientStart = Color(0xFF0000CC); // brand blue
  static const Color primaryGradientEnd = Color(0xFF3366FF); // lighter blue

  // === SECONDARY COLORS (Purple with gradients) ===
  static const Color secondaryLight = Color(0xFF6600CC); // deep purple
  static const Color secondaryDark = Color(0xFFA366FF); // lighter for dark mode

  // Secondary gradient colors
  static const Color secondaryGradientStart = Color(0xFF6600CC); // deep purple
  static const Color secondaryGradientEnd = Color(0xFF9966FF); // lighter purple

  // === TERTIARY COLORS (Emerald with gradients) ===
  static const Color tertiaryLight = Color(0xFF059669); // emerald-600
  static const Color tertiaryDark = Color(0xFF34D399); // emerald-400

  // Tertiary gradient colors
  static const Color tertiaryGradientStart = Color(0xFF059669); // emerald-600
  static const Color tertiaryGradientEnd = Color(0xFF10B981); // emerald-500

  // === ERROR COLORS (Red with modern variants) ===
  static const Color errorLight = Color(0xFFDC2626); // red-600
  static const Color errorDark = Color(0xFFF87171); // red-400

  // Error gradient colors
  static const Color errorGradientStart = Color(0xFFDC2626); // red-600
  static const Color errorGradientEnd = Color(0xFFEF4444); // red-500

  // === MODERN BACKGROUND COLORS ===
  // Enhanced backgrounds with subtle warmth/coolness
  static const Color backgroundLight = Color(
    0xFFFAFBFC,
  ); // slightly warmer white
  static const Color backgroundDark = Color(
    0xFF0C111A,
  ); // deep slate with blue tint

  // === MODERN SURFACE COLORS ===
  // Enhanced surfaces with depth and sophistication
  static const Color surfaceLight = Color(0xFFFFFFFF); // pure white
  static const Color surfaceDark = Color(0xFF1A2332); // deep blue-tinted slate

  // Surface gradient overlays
  static const Color surfaceOverlayLight = Color(
    0xFFF8FAFF,
  ); // very subtle blue tint
  static const Color surfaceOverlayDark = Color(
    0xFF1E2A3A,
  ); // subtle blue gradient

  // === SURFACE VARIANT COLORS ===
  static const Color surfaceVariantLight = Color(
    0xFFF1F5F9,
  ); // refined slate-100
  static const Color surfaceVariantDark = Color(
    0xFF2D3748,
  ); // sophisticated slate-700

  // === MODERN OUTLINE COLORS ===
  // Enhanced outlines with better visibility
  static const Color outlineLight = Color(0xFFE2E8F0); // refined slate-200
  static const Color outlineDark = Color(0xFF4A5568); // enhanced slate-600

  // Gradient outline colors
  static const Color outlineGradientLight = Color(
    0xFFCBD5E1,
  ); // subtle gradient
  static const Color outlineGradientDark = Color(
    0xFF718096,
  ); // gradient outline

  // === MODERN TEXT COLORS ===
  // Enhanced text colors with better contrast
  static const Color textPrimaryLight = Color(0xFF0D1421); // deep slate-900
  static const Color textPrimaryDark = Color(0xFFF7FAFC); // refined slate-50

  static const Color textSecondaryLight = Color(
    0xFF4A5568,
  ); // enhanced slate-600
  static const Color textSecondaryDark = Color(0xFFA0AEC0); // refined slate-400

  // === ACCENT COLORS ===
  // Modern accent colors for highlights and emphasis
  static const Color accentLight = Color(0xFFEBF4FF); // subtle blue accent
  static const Color accentDark = Color(0xFF1E3A8A); // deep blue accent

  // === SHADOW COLORS ===
  // Colored shadows for modern depth
  static const Color shadowLight = Color(0xFF0000CC); // primary blue shadow
  static const Color shadowDark = Color(0xFF3366FF); // lighter blue shadow

  // === GLOW COLORS ===
  // Glow effects for focus states and interactions
  static const Color glowLight = Color(0xFF668CFF); // soft blue glow
  static const Color glowDark = Color(0xFF99BBFF); // lighter glow

  // === GRADIENT DEFINITIONS ===

  /// Primary brand gradient (blue)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGradientStart, primaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Secondary gradient (purple)
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryGradientStart, secondaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Tertiary gradient (emerald)
  static const LinearGradient tertiaryGradient = LinearGradient(
    colors: [tertiaryGradientStart, tertiaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Error gradient (red)
  static const LinearGradient errorGradient = LinearGradient(
    colors: [errorGradientStart, errorGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Surface gradient for cards and containers
  static const LinearGradient surfaceGradientLight = LinearGradient(
    colors: [surfaceLight, surfaceOverlayLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient surfaceGradientDark = LinearGradient(
    colors: [surfaceDark, surfaceOverlayDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Background gradient for subtle depth
  static const LinearGradient backgroundGradientLight = LinearGradient(
    colors: [backgroundLight, surfaceOverlayLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradientDark = LinearGradient(
    colors: [backgroundDark, surfaceOverlayDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === UTILITY GRADIENTS ===

  /// Subtle accent gradient for highlights
  static const LinearGradient accentGradientLight = LinearGradient(
    colors: [accentLight, surfaceLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradientDark = LinearGradient(
    colors: [accentDark, surfaceDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Glow gradient for focus states
  static RadialGradient glowGradientLight = RadialGradient(
    colors: [
      glowLight.withValues(alpha: 0.3),
      glowLight.withValues(alpha: 0.1),
      Colors.transparent,
    ],
    radius: 1.0,
  );

  static RadialGradient glowGradientDark = RadialGradient(
    colors: [
      glowDark.withValues(alpha: 0.4),
      glowDark.withValues(alpha: 0.1),
      Colors.transparent,
    ],
    radius: 1.0,
  );

  // === HELPER METHODS ===

  /// Get gradient with opacity
  static LinearGradient primaryGradientWithOpacity(double opacity) {
    return LinearGradient(
      colors: [
        primaryGradientStart.withValues(alpha: opacity),
        primaryGradientEnd.withValues(alpha: opacity),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Get shadow color with opacity
  static Color shadowColorWithOpacity(double opacity) {
    return shadowLight.withValues(alpha: opacity);
  }

  /// Get glow color with opacity
  static Color glowColorWithOpacity(double opacity) {
    return glowLight.withValues(alpha: opacity);
  }
}
