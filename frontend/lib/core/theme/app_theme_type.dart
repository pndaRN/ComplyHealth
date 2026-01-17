import 'package:flutter/material.dart';

/// Categories for grouping themes in the picker UI
enum ThemeCategory {
  standard('Standard'),
  accessibility('Accessibility'),
  calming('Calming & Wellness'),
  practical('Practical');

  final String displayName;
  const ThemeCategory(this.displayName);
}

/// Sealed class representing all available app themes
sealed class AppThemeType {
  const AppThemeType();

  /// Unique identifier for Hive storage
  String get id;

  /// Human-readable display name
  String get displayName;

  /// Icon to show in picker
  IconData get icon;

  /// Theme category for grouping in UI
  ThemeCategory get category;

  /// Base brightness (for system preference fallback)
  Brightness get baseBrightness;

  /// Factory to create from stored string ID
  static AppThemeType fromId(String id) => switch (id) {
        'system' => const SystemTheme(),
        'light' => const LightTheme(),
        'dark' => const DarkTheme(),
        'high_contrast_light' => const HighContrastLightTheme(),
        'high_contrast_dark' => const HighContrastDarkTheme(),
        'amoled_black' => const AmoledBlackTheme(),
        'ocean' => const OceanTheme(),
        'forest' => const ForestTheme(),
        'lavender' => const LavenderTheme(),
        'sepia' => const SepiaTheme(),
        'muted' => const MutedTheme(),
        _ => const SystemTheme(),
      };

  /// List of all available themes
  static const List<AppThemeType> allThemes = [
    SystemTheme(),
    LightTheme(),
    DarkTheme(),
    HighContrastLightTheme(),
    HighContrastDarkTheme(),
    AmoledBlackTheme(),
    OceanTheme(),
    ForestTheme(),
    LavenderTheme(),
    SepiaTheme(),
    MutedTheme(),
  ];
}

// === Standard Themes ===

final class SystemTheme extends AppThemeType {
  const SystemTheme();

  @override
  String get id => 'system';

  @override
  String get displayName => 'System';

  @override
  IconData get icon => Icons.settings_suggest;

  @override
  ThemeCategory get category => ThemeCategory.standard;

  @override
  Brightness get baseBrightness => Brightness.light;
}

final class LightTheme extends AppThemeType {
  const LightTheme();

  @override
  String get id => 'light';

  @override
  String get displayName => 'Light';

  @override
  IconData get icon => Icons.light_mode;

  @override
  ThemeCategory get category => ThemeCategory.standard;

  @override
  Brightness get baseBrightness => Brightness.light;
}

final class DarkTheme extends AppThemeType {
  const DarkTheme();

  @override
  String get id => 'dark';

  @override
  String get displayName => 'Dark';

  @override
  IconData get icon => Icons.dark_mode;

  @override
  ThemeCategory get category => ThemeCategory.standard;

  @override
  Brightness get baseBrightness => Brightness.dark;
}

// === Accessibility Themes ===

final class HighContrastLightTheme extends AppThemeType {
  const HighContrastLightTheme();

  @override
  String get id => 'high_contrast_light';

  @override
  String get displayName => 'High Contrast';

  @override
  IconData get icon => Icons.contrast;

  @override
  ThemeCategory get category => ThemeCategory.accessibility;

  @override
  Brightness get baseBrightness => Brightness.light;
}

final class HighContrastDarkTheme extends AppThemeType {
  const HighContrastDarkTheme();

  @override
  String get id => 'high_contrast_dark';

  @override
  String get displayName => 'High Contrast Dark';

  @override
  IconData get icon => Icons.contrast;

  @override
  ThemeCategory get category => ThemeCategory.accessibility;

  @override
  Brightness get baseBrightness => Brightness.dark;
}

final class AmoledBlackTheme extends AppThemeType {
  const AmoledBlackTheme();

  @override
  String get id => 'amoled_black';

  @override
  String get displayName => 'AMOLED Black';

  @override
  IconData get icon => Icons.smartphone;

  @override
  ThemeCategory get category => ThemeCategory.accessibility;

  @override
  Brightness get baseBrightness => Brightness.dark;
}

// === Calming & Wellness Themes ===

final class OceanTheme extends AppThemeType {
  const OceanTheme();

  @override
  String get id => 'ocean';

  @override
  String get displayName => 'Ocean';

  @override
  IconData get icon => Icons.water;

  @override
  ThemeCategory get category => ThemeCategory.calming;

  @override
  Brightness get baseBrightness => Brightness.light;
}

final class ForestTheme extends AppThemeType {
  const ForestTheme();

  @override
  String get id => 'forest';

  @override
  String get displayName => 'Forest';

  @override
  IconData get icon => Icons.forest;

  @override
  ThemeCategory get category => ThemeCategory.calming;

  @override
  Brightness get baseBrightness => Brightness.light;
}

final class LavenderTheme extends AppThemeType {
  const LavenderTheme();

  @override
  String get id => 'lavender';

  @override
  String get displayName => 'Lavender';

  @override
  IconData get icon => Icons.local_florist;

  @override
  ThemeCategory get category => ThemeCategory.calming;

  @override
  Brightness get baseBrightness => Brightness.light;
}

// === Practical Themes ===

final class SepiaTheme extends AppThemeType {
  const SepiaTheme();

  @override
  String get id => 'sepia';

  @override
  String get displayName => 'Sepia';

  @override
  IconData get icon => Icons.auto_stories;

  @override
  ThemeCategory get category => ThemeCategory.practical;

  @override
  Brightness get baseBrightness => Brightness.light;
}

final class MutedTheme extends AppThemeType {
  const MutedTheme();

  @override
  String get id => 'muted';

  @override
  String get displayName => 'Muted';

  @override
  IconData get icon => Icons.blur_on;

  @override
  ThemeCategory get category => ThemeCategory.practical;

  @override
  Brightness get baseBrightness => Brightness.light;
}
