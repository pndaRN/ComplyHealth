import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/settings_provider.dart';

class DefaultTimesForm extends ConsumerWidget {
  const DefaultTimesForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      children: [
        _buildTimeTile(
          context: context,
          ref: ref,
          label: 'Morning',
          icon: Icons.wb_sunny_outlined,
          timeStr: settings.morningTime,
          onChanged: (time) => ref
              .read(settingsProvider.notifier)
              .setDefaultTimes(morning: time),
        ),
        const SizedBox(height: 12),
        _buildTimeTile(
          context: context,
          ref: ref,
          label: 'Noon',
          icon: Icons.wb_cloudy_outlined,
          timeStr: settings.noonTime,
          onChanged: (time) =>
              ref.read(settingsProvider.notifier).setDefaultTimes(noon: time),
        ),
        const SizedBox(height: 12),
        _buildTimeTile(
          context: context,
          ref: ref,
          label: 'Evening',
          icon: Icons.wb_twilight_outlined,
          timeStr: settings.eveningTime,
          onChanged: (time) => ref
              .read(settingsProvider.notifier)
              .setDefaultTimes(evening: time),
        ),
        const SizedBox(height: 12),
        _buildTimeTile(
          context: context,
          ref: ref,
          label: 'Night',
          icon: Icons.nightlight_outlined,
          timeStr: settings.nightTime,
          onChanged: (time) =>
              ref.read(settingsProvider.notifier).setDefaultTimes(night: time),
        ),
      ],
    );
  }

  Widget _buildTimeTile({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required IconData icon,
    required String timeStr,
    required ValueChanged<String> onChanged,
  }) {
    final theme = Theme.of(context);
    final parts = timeStr.split(':');
    final timeOfDay = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: timeOfDay,
        );
        if (picked != null) {
          onChanged(
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Text(label, style: theme.textTheme.titleMedium),
            const Spacer(),
            Text(
              timeOfDay.format(context),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit, size: 16),
          ],
        ),
      ),
    );
  }
}
