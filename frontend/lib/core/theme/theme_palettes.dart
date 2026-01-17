import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Base class for theme color palettes
/// Each palette defines all the colors needed to build a complete ColorScheme
abstract class ThemePalette {
  const ThemePalette();

  Brightness get brightness;

  // Primary colors
  Color get primary;
  Color get onPrimary;
  Color get primaryContainer;
  Color get onPrimaryContainer;

  // Secondary colors
  Color get secondary;
  Color get onSecondary;
  Color get secondaryContainer;
  Color get onSecondaryContainer;

  // Tertiary colors
  Color get tertiary;
  Color get onTertiary;
  Color get tertiaryContainer;
  Color get onTertiaryContainer;

  // Error colors
  Color get error;
  Color get onError;
  Color get errorContainer;
  Color get onErrorContainer;

  // Surface colors
  Color get surface;
  Color get onSurface;
  Color get surfaceVariant;
  Color get onSurfaceVariant;
  Color get surfaceTint;

  // Background
  Color get background;

  // Outline
  Color get outline;
  Color get outlineVariant;

  // Shadow
  Color get shadow;

  // Text colors
  Color get textPrimary;
  Color get textSecondary;
}

// === Standard Light Palette ===
class LightPalette extends ThemePalette {
  const LightPalette();

  @override
  Brightness get brightness => Brightness.light;

  @override
  Color get primary => AppColors.primaryLight;
  @override
  Color get onPrimary => Colors.white;
  @override
  Color get primaryContainer =>
      AppColors.primaryGradientStart.withValues(alpha: 0.1);
  @override
  Color get onPrimaryContainer => AppColors.primaryGradientStart;

  @override
  Color get secondary => AppColors.secondaryLight;
  @override
  Color get onSecondary => Colors.white;
  @override
  Color get secondaryContainer =>
      AppColors.secondaryGradientStart.withValues(alpha: 0.1);
  @override
  Color get onSecondaryContainer => AppColors.secondaryGradientStart;

  @override
  Color get tertiary => AppColors.tertiaryLight;
  @override
  Color get onTertiary => Colors.white;
  @override
  Color get tertiaryContainer =>
      AppColors.tertiaryGradientStart.withValues(alpha: 0.1);
  @override
  Color get onTertiaryContainer => AppColors.tertiaryGradientStart;

  @override
  Color get error => AppColors.errorLight;
  @override
  Color get onError => Colors.white;
  @override
  Color get errorContainer =>
      AppColors.errorGradientStart.withValues(alpha: 0.1);
  @override
  Color get onErrorContainer => AppColors.errorGradientStart;

  @override
  Color get surface => AppColors.surfaceLight;
  @override
  Color get onSurface => AppColors.textPrimaryLight;
  @override
  Color get surfaceVariant => AppColors.surfaceVariantLight;
  @override
  Color get onSurfaceVariant => AppColors.textSecondaryLight;
  @override
  Color get surfaceTint => AppColors.primaryLight;

  @override
  Color get background => AppColors.backgroundLight;

  @override
  Color get outline => AppColors.outlineLight;
  @override
  Color get outlineVariant => AppColors.outlineGradientLight;

  @override
  Color get shadow => AppColors.shadowLight;

  @override
  Color get textPrimary => AppColors.textPrimaryLight;
  @override
  Color get textSecondary => AppColors.textSecondaryLight;
}

// === Standard Dark Palette ===
class DarkPalette extends ThemePalette {
  const DarkPalette();

  @override
  Brightness get brightness => Brightness.dark;

  @override
  Color get primary => AppColors.primaryDark;
  @override
  Color get onPrimary => const Color(0xFF001D36);
  @override
  Color get primaryContainer =>
      AppColors.primaryGradientEnd.withValues(alpha: 0.2);
  @override
  Color get onPrimaryContainer => AppColors.primaryDark;

  @override
  Color get secondary => AppColors.secondaryDark;
  @override
  Color get onSecondary => const Color(0xFF1A0033);
  @override
  Color get secondaryContainer =>
      AppColors.secondaryGradientEnd.withValues(alpha: 0.2);
  @override
  Color get onSecondaryContainer => AppColors.secondaryDark;

  @override
  Color get tertiary => AppColors.tertiaryDark;
  @override
  Color get onTertiary => const Color(0xFF064E3B);
  @override
  Color get tertiaryContainer =>
      AppColors.tertiaryGradientEnd.withValues(alpha: 0.2);
  @override
  Color get onTertiaryContainer => AppColors.tertiaryDark;

  @override
  Color get error => AppColors.errorDark;
  @override
  Color get onError => const Color(0xFF7F1D1D);
  @override
  Color get errorContainer =>
      AppColors.errorGradientEnd.withValues(alpha: 0.2);
  @override
  Color get onErrorContainer => AppColors.errorDark;

  @override
  Color get surface => AppColors.surfaceDark;
  @override
  Color get onSurface => AppColors.textPrimaryDark;
  @override
  Color get surfaceVariant => AppColors.surfaceVariantDark;
  @override
  Color get onSurfaceVariant => AppColors.textSecondaryDark;
  @override
  Color get surfaceTint => AppColors.primaryDark;

  @override
  Color get background => AppColors.backgroundDark;

  @override
  Color get outline => AppColors.outlineDark;
  @override
  Color get outlineVariant => AppColors.outlineGradientDark;

  @override
  Color get shadow => AppColors.shadowDark;

  @override
  Color get textPrimary => AppColors.textPrimaryDark;
  @override
  Color get textSecondary => AppColors.textSecondaryDark;
}

// === High Contrast Light Palette ===
class HighContrastLightPalette extends ThemePalette {
  const HighContrastLightPalette();

  @override
  Brightness get brightness => Brightness.light;

  @override
  Color get primary => const Color(0xFF000099); // Darker blue for contrast
  @override
  Color get onPrimary => Colors.white;
  @override
  Color get primaryContainer => const Color(0xFFCCCCFF);
  @override
  Color get onPrimaryContainer => const Color(0xFF000066);

  @override
  Color get secondary => const Color(0xFF4B0082); // Indigo
  @override
  Color get onSecondary => Colors.white;
  @override
  Color get secondaryContainer => const Color(0xFFE6CCFF);
  @override
  Color get onSecondaryContainer => const Color(0xFF2D004D);

  @override
  Color get tertiary => const Color(0xFF006400); // Dark green
  @override
  Color get onTertiary => Colors.white;
  @override
  Color get tertiaryContainer => const Color(0xFFCCFFCC);
  @override
  Color get onTertiaryContainer => const Color(0xFF003D00);

  @override
  Color get error => const Color(0xFFB00000); // Darker red
  @override
  Color get onError => Colors.white;
  @override
  Color get errorContainer => const Color(0xFFFFCCCC);
  @override
  Color get onErrorContainer => const Color(0xFF800000);

  @override
  Color get surface => Colors.white;
  @override
  Color get onSurface => Colors.black;
  @override
  Color get surfaceVariant => const Color(0xFFF0F0F0);
  @override
  Color get onSurfaceVariant => const Color(0xFF1A1A1A);
  @override
  Color get surfaceTint => const Color(0xFF000099);

  @override
  Color get background => Colors.white;

  @override
  Color get outline => const Color(0xFF333333);
  @override
  Color get outlineVariant => const Color(0xFF666666);

  @override
  Color get shadow => Colors.black;

  @override
  Color get textPrimary => Colors.black;
  @override
  Color get textSecondary => const Color(0xFF1A1A1A);
}

// === High Contrast Dark Palette ===
class HighContrastDarkPalette extends ThemePalette {
  const HighContrastDarkPalette();

  @override
  Brightness get brightness => Brightness.dark;

  @override
  Color get primary => const Color(0xFF99CCFF); // Bright blue
  @override
  Color get onPrimary => Colors.black;
  @override
  Color get primaryContainer => const Color(0xFF003366);
  @override
  Color get onPrimaryContainer => const Color(0xFFCCE5FF);

  @override
  Color get secondary => const Color(0xFFCC99FF); // Bright purple
  @override
  Color get onSecondary => Colors.black;
  @override
  Color get secondaryContainer => const Color(0xFF4B0082);
  @override
  Color get onSecondaryContainer => const Color(0xFFE5CCFF);

  @override
  Color get tertiary => const Color(0xFF66FF66); // Bright green
  @override
  Color get onTertiary => Colors.black;
  @override
  Color get tertiaryContainer => const Color(0xFF004D00);
  @override
  Color get onTertiaryContainer => const Color(0xFFCCFFCC);

  @override
  Color get error => const Color(0xFFFF6666); // Bright red
  @override
  Color get onError => Colors.black;
  @override
  Color get errorContainer => const Color(0xFF800000);
  @override
  Color get onErrorContainer => const Color(0xFFFFCCCC);

  @override
  Color get surface => Colors.black;
  @override
  Color get onSurface => Colors.white;
  @override
  Color get surfaceVariant => const Color(0xFF1A1A1A);
  @override
  Color get onSurfaceVariant => const Color(0xFFE5E5E5);
  @override
  Color get surfaceTint => const Color(0xFF99CCFF);

  @override
  Color get background => Colors.black;

  @override
  Color get outline => const Color(0xFFCCCCCC);
  @override
  Color get outlineVariant => const Color(0xFF999999);

  @override
  Color get shadow => Colors.black;

  @override
  Color get textPrimary => Colors.white;
  @override
  Color get textSecondary => const Color(0xFFE5E5E5);
}

// === AMOLED Black Palette ===
class AmoledBlackPalette extends ThemePalette {
  const AmoledBlackPalette();

  @override
  Brightness get brightness => Brightness.dark;

  @override
  Color get primary => const Color(0xFF668CFF); // Soft blue
  @override
  Color get onPrimary => Colors.black;
  @override
  Color get primaryContainer => const Color(0xFF1A1A2E);
  @override
  Color get onPrimaryContainer => const Color(0xFF99BBFF);

  @override
  Color get secondary => const Color(0xFFA366FF); // Soft purple
  @override
  Color get onSecondary => Colors.black;
  @override
  Color get secondaryContainer => const Color(0xFF1A0A2E);
  @override
  Color get onSecondaryContainer => const Color(0xFFCC99FF);

  @override
  Color get tertiary => const Color(0xFF34D399); // Emerald
  @override
  Color get onTertiary => Colors.black;
  @override
  Color get tertiaryContainer => const Color(0xFF0A1A14);
  @override
  Color get onTertiaryContainer => const Color(0xFF6EE7B7);

  @override
  Color get error => const Color(0xFFF87171); // Soft red
  @override
  Color get onError => Colors.black;
  @override
  Color get errorContainer => const Color(0xFF2A0A0A);
  @override
  Color get onErrorContainer => const Color(0xFFFCA5A5);

  @override
  Color get surface => Colors.black;
  @override
  Color get onSurface => const Color(0xFFF0F0F0);
  @override
  Color get surfaceVariant => const Color(0xFF0D0D0D);
  @override
  Color get onSurfaceVariant => const Color(0xFFB0B0B0);
  @override
  Color get surfaceTint => const Color(0xFF668CFF);

  @override
  Color get background => Colors.black;

  @override
  Color get outline => const Color(0xFF333333);
  @override
  Color get outlineVariant => const Color(0xFF1A1A1A);

  @override
  Color get shadow => Colors.black;

  @override
  Color get textPrimary => const Color(0xFFF0F0F0);
  @override
  Color get textSecondary => const Color(0xFFB0B0B0);
}

// === Ocean Palette ===
class OceanPalette extends ThemePalette {
  const OceanPalette();

  @override
  Brightness get brightness => Brightness.light;

  @override
  Color get primary => const Color(0xFF0077B6); // Ocean blue
  @override
  Color get onPrimary => Colors.white;
  @override
  Color get primaryContainer => const Color(0xFFCAF0F8);
  @override
  Color get onPrimaryContainer => const Color(0xFF023E8A);

  @override
  Color get secondary => const Color(0xFF00B4D8); // Cyan
  @override
  Color get onSecondary => Colors.white;
  @override
  Color get secondaryContainer => const Color(0xFFE0F7FA);
  @override
  Color get onSecondaryContainer => const Color(0xFF0077B6);

  @override
  Color get tertiary => const Color(0xFF48CAE4); // Light cyan
  @override
  Color get onTertiary => const Color(0xFF023E8A);
  @override
  Color get tertiaryContainer => const Color(0xFFE0F7FA);
  @override
  Color get onTertiaryContainer => const Color(0xFF0096C7);

  @override
  Color get error => const Color(0xFFDC2626);
  @override
  Color get onError => Colors.white;
  @override
  Color get errorContainer => const Color(0xFFFEE2E2);
  @override
  Color get onErrorContainer => const Color(0xFF991B1B);

  @override
  Color get surface => const Color(0xFFFAFDFF);
  @override
  Color get onSurface => const Color(0xFF0A1628);
  @override
  Color get surfaceVariant => const Color(0xFFE8F6FA);
  @override
  Color get onSurfaceVariant => const Color(0xFF3D5A6C);
  @override
  Color get surfaceTint => const Color(0xFF0077B6);

  @override
  Color get background => const Color(0xFFF0F9FF);

  @override
  Color get outline => const Color(0xFF90CDF4);
  @override
  Color get outlineVariant => const Color(0xFFBEE3F8);

  @override
  Color get shadow => const Color(0xFF0077B6);

  @override
  Color get textPrimary => const Color(0xFF0A1628);
  @override
  Color get textSecondary => const Color(0xFF3D5A6C);
}

// === Forest Palette ===
class ForestPalette extends ThemePalette {
  const ForestPalette();

  @override
  Brightness get brightness => Brightness.light;

  @override
  Color get primary => const Color(0xFF2D6A4F); // Forest green
  @override
  Color get onPrimary => Colors.white;
  @override
  Color get primaryContainer => const Color(0xFFD8F3DC);
  @override
  Color get onPrimaryContainer => const Color(0xFF1B4332);

  @override
  Color get secondary => const Color(0xFF52B788); // Mint green
  @override
  Color get onSecondary => Colors.white;
  @override
  Color get secondaryContainer => const Color(0xFFE8F5E9);
  @override
  Color get onSecondaryContainer => const Color(0xFF2D6A4F);

  @override
  Color get tertiary => const Color(0xFF8B4513); // Saddle brown
  @override
  Color get onTertiary => Colors.white;
  @override
  Color get tertiaryContainer => const Color(0xFFF5EBE0);
  @override
  Color get onTertiaryContainer => const Color(0xFF5D2E0D);

  @override
  Color get error => const Color(0xFFDC2626);
  @override
  Color get onError => Colors.white;
  @override
  Color get errorContainer => const Color(0xFFFEE2E2);
  @override
  Color get onErrorContainer => const Color(0xFF991B1B);

  @override
  Color get surface => const Color(0xFFFCFDF7);
  @override
  Color get onSurface => const Color(0xFF1A2E1A);
  @override
  Color get surfaceVariant => const Color(0xFFF1F8E9);
  @override
  Color get onSurfaceVariant => const Color(0xFF4A5D4A);
  @override
  Color get surfaceTint => const Color(0xFF2D6A4F);

  @override
  Color get background => const Color(0xFFF5FAF5);

  @override
  Color get outline => const Color(0xFFA5D6A7);
  @override
  Color get outlineVariant => const Color(0xFFC8E6C9);

  @override
  Color get shadow => const Color(0xFF2D6A4F);

  @override
  Color get textPrimary => const Color(0xFF1A2E1A);
  @override
  Color get textSecondary => const Color(0xFF4A5D4A);
}

// === Lavender Palette ===
class LavenderPalette extends ThemePalette {
  const LavenderPalette();

  @override
  Brightness get brightness => Brightness.light;

  @override
  Color get primary => const Color(0xFF7C3AED); // Violet
  @override
  Color get onPrimary => Colors.white;
  @override
  Color get primaryContainer => const Color(0xFFEDE9FE);
  @override
  Color get onPrimaryContainer => const Color(0xFF5B21B6);

  @override
  Color get secondary => const Color(0xFFA78BFA); // Light violet
  @override
  Color get onSecondary => Colors.white;
  @override
  Color get secondaryContainer => const Color(0xFFF3E8FF);
  @override
  Color get onSecondaryContainer => const Color(0xFF7C3AED);

  @override
  Color get tertiary => const Color(0xFFF472B6); // Pink
  @override
  Color get onTertiary => Colors.white;
  @override
  Color get tertiaryContainer => const Color(0xFFFCE7F3);
  @override
  Color get onTertiaryContainer => const Color(0xFFDB2777);

  @override
  Color get error => const Color(0xFFDC2626);
  @override
  Color get onError => Colors.white;
  @override
  Color get errorContainer => const Color(0xFFFEE2E2);
  @override
  Color get onErrorContainer => const Color(0xFF991B1B);

  @override
  Color get surface => const Color(0xFFFCFAFF);
  @override
  Color get onSurface => const Color(0xFF1E1A2E);
  @override
  Color get surfaceVariant => const Color(0xFFF5F3FF);
  @override
  Color get onSurfaceVariant => const Color(0xFF5B5575);
  @override
  Color get surfaceTint => const Color(0xFF7C3AED);

  @override
  Color get background => const Color(0xFFFAF5FF);

  @override
  Color get outline => const Color(0xFFDDD6FE);
  @override
  Color get outlineVariant => const Color(0xFFE9E3FF);

  @override
  Color get shadow => const Color(0xFF7C3AED);

  @override
  Color get textPrimary => const Color(0xFF1E1A2E);
  @override
  Color get textSecondary => const Color(0xFF5B5575);
}

// === Sepia Palette ===
class SepiaPalette extends ThemePalette {
  const SepiaPalette();

  @override
  Brightness get brightness => Brightness.light;

  @override
  Color get primary => const Color(0xFF8B4513); // Saddle brown
  @override
  Color get onPrimary => Colors.white;
  @override
  Color get primaryContainer => const Color(0xFFF5DEB3);
  @override
  Color get onPrimaryContainer => const Color(0xFF5D2E0D);

  @override
  Color get secondary => const Color(0xFFA0522D); // Sienna
  @override
  Color get onSecondary => Colors.white;
  @override
  Color get secondaryContainer => const Color(0xFFFAEBD7);
  @override
  Color get onSecondaryContainer => const Color(0xFF6B3810);

  @override
  Color get tertiary => const Color(0xFF6B8E23); // Olive drab
  @override
  Color get onTertiary => Colors.white;
  @override
  Color get tertiaryContainer => const Color(0xFFEEF5DB);
  @override
  Color get onTertiaryContainer => const Color(0xFF4A6310);

  @override
  Color get error => const Color(0xFFB22222); // Fire brick
  @override
  Color get onError => Colors.white;
  @override
  Color get errorContainer => const Color(0xFFFEE2E2);
  @override
  Color get onErrorContainer => const Color(0xFF8B0000);

  @override
  Color get surface => const Color(0xFFFDF5E6); // Old lace
  @override
  Color get onSurface => const Color(0xFF3D2B1F);
  @override
  Color get surfaceVariant => const Color(0xFFF5E6D3);
  @override
  Color get onSurfaceVariant => const Color(0xFF5D4E3A);
  @override
  Color get surfaceTint => const Color(0xFF8B4513);

  @override
  Color get background => const Color(0xFFFAF0E6); // Linen

  @override
  Color get outline => const Color(0xFFD2B48C); // Tan
  @override
  Color get outlineVariant => const Color(0xFFE6D5C3);

  @override
  Color get shadow => const Color(0xFF8B4513);

  @override
  Color get textPrimary => const Color(0xFF3D2B1F);
  @override
  Color get textSecondary => const Color(0xFF5D4E3A);
}

// === Muted Palette ===
class MutedPalette extends ThemePalette {
  const MutedPalette();

  @override
  Brightness get brightness => Brightness.light;

  @override
  Color get primary => const Color(0xFF6B7280); // Gray-500
  @override
  Color get onPrimary => Colors.white;
  @override
  Color get primaryContainer => const Color(0xFFE5E7EB);
  @override
  Color get onPrimaryContainer => const Color(0xFF374151);

  @override
  Color get secondary => const Color(0xFF9CA3AF); // Gray-400
  @override
  Color get onSecondary => Colors.white;
  @override
  Color get secondaryContainer => const Color(0xFFF3F4F6);
  @override
  Color get onSecondaryContainer => const Color(0xFF4B5563);

  @override
  Color get tertiary => const Color(0xFF78716C); // Stone-500
  @override
  Color get onTertiary => Colors.white;
  @override
  Color get tertiaryContainer => const Color(0xFFE7E5E4);
  @override
  Color get onTertiaryContainer => const Color(0xFF44403C);

  @override
  Color get error => const Color(0xFFB91C1C); // Red-700 (muted)
  @override
  Color get onError => Colors.white;
  @override
  Color get errorContainer => const Color(0xFFFEE2E2);
  @override
  Color get onErrorContainer => const Color(0xFF7F1D1D);

  @override
  Color get surface => const Color(0xFFFAFAFA);
  @override
  Color get onSurface => const Color(0xFF1F2937);
  @override
  Color get surfaceVariant => const Color(0xFFF3F4F6);
  @override
  Color get onSurfaceVariant => const Color(0xFF4B5563);
  @override
  Color get surfaceTint => const Color(0xFF6B7280);

  @override
  Color get background => const Color(0xFFF9FAFB);

  @override
  Color get outline => const Color(0xFFD1D5DB);
  @override
  Color get outlineVariant => const Color(0xFFE5E7EB);

  @override
  Color get shadow => const Color(0xFF6B7280);

  @override
  Color get textPrimary => const Color(0xFF1F2937);
  @override
  Color get textSecondary => const Color(0xFF4B5563);
}

/// Helper to get the palette for a theme type
ThemePalette getPaletteForThemeId(String themeId) {
  return switch (themeId) {
    'light' => const LightPalette(),
    'dark' => const DarkPalette(),
    'high_contrast_light' => const HighContrastLightPalette(),
    'high_contrast_dark' => const HighContrastDarkPalette(),
    'amoled_black' => const AmoledBlackPalette(),
    'ocean' => const OceanPalette(),
    'forest' => const ForestPalette(),
    'lavender' => const LavenderPalette(),
    'sepia' => const SepiaPalette(),
    'muted' => const MutedPalette(),
    _ => const LightPalette(),
  };
}
