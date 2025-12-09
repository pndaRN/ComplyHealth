import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/settings_provider.dart';
import '../../core/theme/theme_provider.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Notifications section
          _buildSectionHeader(context, 'Notifications'),
          SwitchListTile(
            title: const Text('Medication Reminders'),
            subtitle: const Text('Receive notifications for scheduled medications'),
            value: settings.notificationsEnabled,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setNotificationsEnabled(value);
            },
          ),
          const Divider(),

          // Appearance section
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_getThemeName(themeState.themeMode)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showThemeDialog(context, ref, themeState.themeMode),
          ),
          const Divider(),

          // Data section
          _buildSectionHeader(context, 'Data'),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export Data'),
            subtitle: const Text('Save your data as a backup file'),
            onTap: () => _exportData(context),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            title: Text(
              'Clear All Data',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text('Delete all conditions, medications, and settings'),
            onTap: () => _showClearDataDialog(context, ref),
          ),
          const Divider(),

          // About section
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About SmartPatient'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Theme'),
        children: [
          _buildThemeOption(context, ref, 'Light', ThemeMode.light, currentMode),
          _buildThemeOption(context, ref, 'Dark', ThemeMode.dark, currentMode),
          _buildThemeOption(context, ref, 'System default', ThemeMode.system, currentMode),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    String title,
    ThemeMode mode,
    ThemeMode currentMode,
  ) {
    final isSelected = mode == currentMode;
    return SimpleDialogOption(
      onPressed: () {
        ref.read(themeProvider.notifier).setThemeMode(mode);
        Navigator.of(context).pop();
      },
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
          const SizedBox(width: 16),
          Text(title),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      // Collect data from all boxes
      final Map<String, dynamic> exportData = {};

      final boxNames = ['conditions', 'medications', 'profile', 'medication_logs'];
      for (final name in boxNames) {
        try {
          final box = await Hive.openBox(name);
          final Map<String, dynamic> boxData = {};
          for (final key in box.keys) {
            final value = box.get(key);
            if (value != null) {
              boxData[key.toString()] = value.toString();
            }
          }
          exportData[name] = boxData;
        } catch (_) {
          // Skip boxes that can't be opened
        }
      }

      exportData['exportDate'] = DateTime.now().toIso8601String();
      exportData['appVersion'] = '1.0.0';

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Save to file and share
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/smartpatient_backup.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'SmartPatient Backup',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your conditions, medications, medication logs, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              await ref.read(settingsProvider.notifier).clearAllData();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data has been cleared')),
                );
              }
            },
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }
}
