import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/settings_provider.dart';
import '../../core/state/auth_provider.dart';
import '../../core/theme/theme_provider.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import 'dialogs/theme_picker_dialog.dart';
import 'dart:convert';
import 'package:hive_ce/hive_ce.dart';
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
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Notifications section
          _buildSectionHeader(context, 'Notifications'),
          SwitchListTile(
            title: const Text('Medication Reminders'),
            subtitle: const Text(
              'Receive notifications for scheduled medications',
            ),
            value: settings.notificationsEnabled,
            onChanged: (value) {
              ref
                  .read(settingsProvider.notifier)
                  .setNotificationsEnabled(value);
            },
          ),
          const Divider(),

          // Appearance section
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(themeState.themeType.displayName),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showThemePicker(context),
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
            subtitle: const Text(
              'Delete all conditions, medications, and settings',
            ),
            onTap: () => _showClearDataDialog(context, ref),
          ),
          const Divider(),

          // Account section
          _buildSectionHeader(context, 'Account'),
          _buildAccountSection(context, ref),
          const Divider(),

          // About section
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About ComplyHealth'),
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
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final userEmail = authState.whenOrNull(data: (user) => user?.email);

    return Column(
      children: [
        if (userEmail != null)
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(userEmail),
          ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign Out'),
          onTap: () => _showSignOutDialog(context, ref),
        ),
        ListTile(
          leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
          title: Text(
            'Delete Account',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          subtitle: const Text('Permanently delete your account and all data'),
          onTap: () => _showDeleteAccountDialog(context, ref),
        ),
      ],
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
          'Your data will remain on this device. You can sign back in anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              final syncService = ref.read(syncServiceProvider);
              syncService.stopRealtimeSync();
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account, all synced data, and local data. This action cannot be undone.',
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
              try {
                final uid = ref.read(userIdProvider);
                final authService = ref.read(authServiceProvider);
                final syncService = ref.read(syncServiceProvider);

                // Delete remote data
                if (uid != null) {
                  syncService.stopRealtimeSync();
                  await syncService.deleteAllRemoteData(uid);
                }

                // Clear local data
                await ref.read(settingsProvider.notifier).clearAllData();

                // Delete Firebase Auth account
                await authService.deleteAccount();

                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete account: $e')),
                  );
                }
              }
            },
            child: const Text('Delete Account'),
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

  void _showThemePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ThemePickerDialog(),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      // Collect data from all boxes
      final Map<String, dynamic> exportData = {};

      final boxNames = [
        'conditions',
        'medications',
        'profile',
        'medication_logs',
      ];
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
      final file = File('${directory.path}/complyhealth_backup.json');
      await file.writeAsString(jsonString);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'ComplyHealth Backup'),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
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
