import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Theme state class
class ThemeState {
  final ThemeMode themeMode;

  const ThemeState({this.themeMode = ThemeMode.system});

  ThemeState copyWith({ThemeMode? themeMode}) {
    return ThemeState(themeMode: themeMode ?? this.themeMode);
  }
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
    return const ThemeState(themeMode: ThemeMode.system);
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

    _box = await Hive.openBox(
      'theme',
      encryptionCipher: HiveAesCipher(key),
      );
    return _box!;
  }

  /// Load theme preference from Hive
  Future<void> _loadTheme() async {
    final box = await _getBox();
    final savedMode = box.get('themeMode', defaultValue: 'system') as String;
    state = ThemeState(themeMode: _parseThemeMode(savedMode));
  }

  /// Set theme mode and persist to Hive
  Future<void> setThemeMode(ThemeMode mode) async {
    final box = await _getBox();
    await box.put('themeMode', _themeModeToString(mode));
    state = ThemeState(themeMode: mode);
  }

  /// Toggle between light and dark modes
  /// If currently in system mode, switches to light mode first
  Future<void> toggleTheme() async {
    ThemeMode newMode;

    switch (state.themeMode) {
      case ThemeMode.system:
        // Default to light when toggling from system
        newMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        newMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newMode = ThemeMode.light;
        break;
    }

    await setThemeMode(newMode);
  }

  /// Parse string to ThemeMode
  ThemeMode _parseThemeMode(String value) {
    switch (value.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Convert ThemeMode to string for storage
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
