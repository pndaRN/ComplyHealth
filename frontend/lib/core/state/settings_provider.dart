import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Settings state class
class SettingsState {
  final bool notificationsEnabled;
  final bool hasCompletedOnboarding;

  const SettingsState({
    this.notificationsEnabled = true,
    this.hasCompletedOnboarding = false,
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? hasCompletedOnboarding,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
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
    _box = await Hive.openBox('settings');
    return _box!;
  }

  Future<void> _loadSettings() async {
    final box = await _getBox();
    final notificationsEnabled = box.get('notificationsEnabled', defaultValue: true) as bool;
    final hasCompletedOnboarding = box.get('hasCompletedOnboarding', defaultValue: false) as bool;
    state = SettingsState(
      notificationsEnabled: notificationsEnabled,
      hasCompletedOnboarding: hasCompletedOnboarding,
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
    // Clear all Hive boxes
    final boxNames = ['conditions', 'medications', 'profile', 'medication_logs', 'feedback', 'settings', 'theme'];
    for (final name in boxNames) {
      try {
        final box = await Hive.openBox(name);
        await box.clear();
      } catch (_) {
        // Box might not exist
      }
    }
    state = const SettingsState();
  }
}
