import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/services/encryption_migration_service.dart';
import 'app_theme_type.dart';

/// Theme state class
class ThemeState {
  final AppThemeType themeType;

  const ThemeState({this.themeType = const SystemTheme()});

  ThemeState copyWith({AppThemeType? themeType}) {
    return ThemeState(themeType: themeType ?? this.themeType);
  }

  /// Convenience getter for MaterialApp themeMode
  ThemeMode get themeMode => switch (themeType) {
        SystemTheme() => ThemeMode.system,
        _ => themeType.baseBrightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
      };
}

/// Theme provider for managing app theme mode
/// Persists theme preference using Hive
final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);

/// Theme notifier for state management
class ThemeNotifier extends Notifier<ThemeState> {
  Box? _box;

  @override
  ThemeState build() {
    _initializeAndLoad();
    return const ThemeState(themeType: SystemTheme());
  }

  /// Initialize and load theme from Hive
  Future<void> _initializeAndLoad() async {
    await _loadTheme();
  }

  /// Get or open the Hive box (cached)
  Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    final key = await EncryptionMigrationService.getEncryptionKey();

    _box = await Hive.openBox('theme', encryptionCipher: HiveAesCipher(key));
    return _box!;
  }

  /// Load theme preference from Hive with migration support
  Future<void> _loadTheme() async {
    final box = await _getBox();

    // Check for old format first (migration)
    final oldThemeMode = box.get('themeMode');
    if (oldThemeMode != null) {
      // Migrate from old format
      final type = switch (oldThemeMode as String) {
        'light' => const LightTheme(),
        'dark' => const DarkTheme(),
        _ => const SystemTheme(),
      };
      await box.put('themeType', type.id);
      await box.delete('themeMode'); // Clean up old key
      state = ThemeState(themeType: type);
      return;
    }

    // New format
    final savedId = box.get('themeType', defaultValue: 'system') as String;
    state = ThemeState(themeType: AppThemeType.fromId(savedId));
  }

  /// Set theme and persist to Hive
  Future<void> setTheme(AppThemeType type) async {
    final box = await _getBox();
    await box.put('themeType', type.id);
    state = ThemeState(themeType: type);
  }

  /// Set theme mode (for backward compatibility)
  Future<void> setThemeMode(ThemeMode mode) async {
    final type = switch (mode) {
      ThemeMode.light => const LightTheme(),
      ThemeMode.dark => const DarkTheme(),
      ThemeMode.system => const SystemTheme(),
    };
    await setTheme(type);
  }

  /// Toggle between light and dark modes
  /// If currently in system mode, switches to light mode first
  Future<void> toggleTheme() async {
    AppThemeType newType;

    switch (state.themeType) {
      case SystemTheme():
        newType = const LightTheme();
        break;
      case LightTheme():
        newType = const DarkTheme();
        break;
      case DarkTheme():
        newType = const LightTheme();
        break;
      default:
        // For other themes, toggle based on brightness
        if (state.themeType.baseBrightness == Brightness.light) {
          newType = const DarkTheme();
        } else {
          newType = const LightTheme();
        }
    }

    await setTheme(newType);
  }
}
