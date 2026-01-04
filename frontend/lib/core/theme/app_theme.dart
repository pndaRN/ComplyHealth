import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';

/// App theme configuration for light and dark modes
/// Implements Material Design 3 with custom colors and typography
class AppTheme {
  AppTheme._(); // Private constructor

  /// Light theme configuration
  static ThemeData lightTheme() {
    final ColorScheme colorScheme = ColorScheme.light(
      primary: AppColors.primaryLight,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFCCCCFF), // light blue tint
      onPrimaryContainer: const Color(0xFF000066), // dark blue

      secondary: AppColors.secondaryLight,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFE6CCFF), // light purple tint
      onSecondaryContainer: const Color(0xFF330066), // dark purple

      tertiary: AppColors.tertiaryLight,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFD1FAE5), // emerald-100
      onTertiaryContainer: const Color(0xFF065F46), // emerald-800

      error: AppColors.errorLight,
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2), // red-100
      onErrorContainer: const Color(0xFF991B1B), // red-800

      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,

      surfaceContainerHighest: AppColors.surfaceVariantLight,
      onSurfaceVariant: AppColors.textSecondaryLight,

      outline: AppColors.outlineLight,
      outlineVariant: const Color(0xFFE2E8F0), // slate-200 (visible dividers)

      shadow: Colors.black,
      scrim: Colors.black,

      inverseSurface: AppColors.textPrimaryLight,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.primaryDark,

      surfaceTint: AppColors.primaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTextTheme.lightTextTheme,
      brightness: Brightness.light,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimaryLight,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
        titleTextStyle: AppTextTheme.lightTextTheme.titleLarge,
      ),

      // Card Theme - stronger shadow for better separation
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.outlineLight.withValues(alpha: 0.5), width: 1),
        ),
        color: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundLight,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // FloatingActionButton Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Input Decoration Theme - stronger borders for visibility
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.outlineLight, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.outlineLight, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.errorLight, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.errorLight, width: 2),
        ),
        hintStyle: TextStyle(color: AppColors.textSecondaryLight),
        labelStyle: TextStyle(color: AppColors.textSecondaryLight),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Chip Theme - more visible chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariantLight,
        selectedColor: AppColors.primaryLight.withValues(alpha: 0.25),
        labelStyle: AppTextTheme.lightTextTheme.labelMedium!.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        side: BorderSide(color: AppColors.outlineLight),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Dialog Theme - cleaner dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimaryLight,
        contentTextStyle: AppTextTheme.lightTextTheme.bodyMedium!.copyWith(
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Divider Theme - more visible dividers
      dividerTheme: DividerThemeData(
        color: AppColors.outlineLight,
        thickness: 1,
        space: 1,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.primaryLight.withValues(alpha: 0.1),
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData darkTheme() {
    final ColorScheme colorScheme = ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: const Color(0xFF000033),
      primaryContainer: const Color(0xFF000066), // dark blue
      onPrimaryContainer: const Color(0xFFCCCCFF), // light blue

      secondary: AppColors.secondaryDark,
      onSecondary: const Color(0xFF1A0033),
      secondaryContainer: const Color(0xFF330066), // dark purple
      onSecondaryContainer: const Color(0xFFE6CCFF), // light purple

      tertiary: AppColors.tertiaryDark,
      onTertiary: const Color(0xFF064E3B),
      tertiaryContainer: const Color(0xFF065F46), // emerald-800 equivalent
      onTertiaryContainer: const Color(0xFFD1FAE5),

      error: AppColors.errorDark,
      onError: const Color(0xFF7F1D1D),
      errorContainer: const Color(0xFF991B1B), // red-800 equivalent
      onErrorContainer: const Color(0xFFFEE2E2),

      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,

      surfaceContainerHighest: AppColors.surfaceVariantDark,
      onSurfaceVariant: AppColors.textSecondaryDark,

      outline: AppColors.outlineDark,
      outlineVariant: const Color(0xFF475569), // slate-600

      shadow: Colors.black,
      scrim: Colors.black,

      inverseSurface: AppColors.textPrimaryDark,
      onInverseSurface: AppColors.backgroundDark,
      inversePrimary: AppColors.primaryLight,

      surfaceTint: AppColors.primaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTextTheme.darkTextTheme,
      brightness: Brightness.dark,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        surfaceTintColor: AppColors.primaryDark,
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: AppTextTheme.darkTextTheme.titleLarge,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppColors.surfaceDark,
        surfaceTintColor: AppColors.primaryDark,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundDark,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // FloatingActionButton Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: const Color(0xFF001D36),
        elevation: 4,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.outlineDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.outlineDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.errorDark),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: const Color(0xFF001D36),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariantDark,
        selectedColor: AppColors.primaryDark.withValues(alpha: 0.3),
        labelStyle: AppTextTheme.darkTextTheme.labelMedium!,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: AppColors.primaryDark,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: AppTextTheme.darkTextTheme.bodyMedium!.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
