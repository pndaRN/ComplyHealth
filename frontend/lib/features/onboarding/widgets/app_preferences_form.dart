import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/settings_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_theme_type.dart';

class AppPreferencesForm extends ConsumerWidget {
  const AppPreferencesForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visual Style',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildThemeOption(
          context,
          ref,
          'Light Mode',
          Icons.light_mode_outlined,
          const LightTheme(),
          themeState.themeType is LightTheme,
        ),
        _buildThemeOption(
          context,
          ref,
          'Dark Mode',
          Icons.dark_mode_outlined,
          const DarkTheme(),
          themeState.themeType is DarkTheme,
        ),
        _buildThemeOption(
          context,
          ref,
          'Follow System',
          Icons.settings_brightness,
          const SystemTheme(),
          themeState.themeType is SystemTheme,
        ),
        const SizedBox(height: 24),
        Text(
          'Reminders',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Medication Reminders'),
          subtitle: const Text('Receive alerts when it\'s time for your doses'),
          value: settings.notificationsEnabled,
          onChanged: (value) => ref
              .read(settingsProvider.notifier)
              .setNotificationsEnabled(value),
          secondary: Icon(
            settings.notificationsEnabled
                ? Icons.notifications_active
                : Icons.notifications_off_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    AppThemeType type,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : null),
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
      onTap: () => ref.read(themeProvider.notifier).setTheme(type),
    );
  }
}
