import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/encryption_migration_service.dart';

/// Settings state class
class SettingsState {
  final bool notificationsEnabled;
  final bool hasCompletedOnboarding;
  final String morningTime;
  final String noonTime;
  final String eveningTime;
  final String nightTime;

  const SettingsState({
    this.notificationsEnabled = true,
    this.hasCompletedOnboarding = false,
    this.morningTime = '07:00',
    this.noonTime = '12:00',
    this.eveningTime = '17:00',
    this.nightTime = '21:00',
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? hasCompletedOnboarding,
    String? morningTime,
    String? noonTime,
    String? eveningTime,
    String? nightTime,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      morningTime: morningTime ?? this.morningTime,
      noonTime: noonTime ?? this.noonTime,
      eveningTime: eveningTime ?? this.eveningTime,
      nightTime: nightTime ?? this.nightTime,
    );
  }
}

/// Settings provider for managing app settings
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

/// Settings notifier for state management
class SettingsNotifier extends Notifier<SettingsState> {
  Box? _box;

  @override
  SettingsState build() {
    _initializeAndLoad();
    return const SettingsState();
  }

  Future<void> _initializeAndLoad() async {
    await _loadSettings();
  }

  Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }

    final key = await EncryptionMigrationService.getEncryptionKey();

    _box = await Hive.openBox('settings', encryptionCipher: HiveAesCipher(key));
    return _box!;
  }

  Future<void> _loadSettings() async {
    final box = await _getBox();
    final notificationsEnabled =
        box.get('notificationsEnabled', defaultValue: true) as bool;
    final hasCompletedOnboarding =
        box.get('hasCompletedOnboarding', defaultValue: false) as bool;
    final morningTime = box.get('morningTime', defaultValue: '07:00') as String;
    final noonTime = box.get('noonTime', defaultValue: '12:00') as String;
    final eveningTime = box.get('eveningTime', defaultValue: '17:00') as String;
    final nightTime = box.get('nightTime', defaultValue: '21:00') as String;

    state = SettingsState(
      notificationsEnabled: notificationsEnabled,
      hasCompletedOnboarding: hasCompletedOnboarding,
      morningTime: morningTime,
      noonTime: noonTime,
      eveningTime: eveningTime,
      nightTime: nightTime,
    );
  }

  Future<void> setDefaultTimes({
    String? morning,
    String? noon,
    String? evening,
    String? night,
  }) async {
    final box = await _getBox();
    if (morning != null) await box.put('morningTime', morning);
    if (noon != null) await box.put('noonTime', noon);
    if (evening != null) await box.put('eveningTime', evening);
    if (night != null) await box.put('nightTime', night);

    state = state.copyWith(
      morningTime: morning,
      noonTime: noon,
      eveningTime: evening,
      nightTime: night,
    );
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final box = await _getBox();
    await box.put('notificationsEnabled', enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    final box = await _getBox();
    await box.put('hasCompletedOnboarding', completed);
    state = state.copyWith(hasCompletedOnboarding: completed);
  }

  Future<void> clearAllData() async {
    // Clear all Hive boxes (using encryption cipher since boxes are encrypted)
    final key = await EncryptionMigrationService.getEncryptionKey();
    final boxNames = [
      'conditions',
      'medications',
      'profile',
      'medication_logs',
      'feedback',
      'settings',
      'theme',
    ];
    for (final name in boxNames) {
      try {
        final box = await Hive.openBox(
          name,
          encryptionCipher: HiveAesCipher(key),
        );
        await box.clear();
      } catch (e) {
        // Box might not exist or have different encryption - try without cipher
        try {
          final box = await Hive.openBox(name);
          await box.clear();
        } catch (innerError) {
          // Box doesn't exist or can't be opened - log for debugging
          assert(() {
            debugPrint(
              'clearAllData: Could not clear box "$name": $innerError',
            );
            return true;
          }());
        }
      }
    }
    state = const SettingsState();
  }
}
