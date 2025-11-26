import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/medication.dart';
import '../../../core/state/medication_provider.dart';
import '../../../core/utils/time_formatting_utils.dart';

/// Reusable expansion tile widget for displaying medication details
class MedicationExpansionTile extends ConsumerWidget {
  final Medication medication;
  final List<String> conditionDisplayNames;
  final String timingSummary;
  final Color? doseColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicationExpansionTile({
    super.key,
    required this.medication,
    required this.conditionDisplayNames,
    required this.timingSummary,
    this.doseColor,
    required this.onEdit,
    required this.onDelete,
  });


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(medicationProvider.notifier);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        title: Text('${medication.name} — ${medication.dosage}'),
        subtitle: RichText(
          text: TextSpan(
            style: theme.textTheme.bodySmall,
            children: [
              TextSpan(
                text: timingSummary,
                style: medication.isPRN
                    ? TextStyle(color: doseColor, fontWeight: FontWeight.bold)
                    : null,
              ),
              TextSpan(text: ' • For: ${conditionDisplayNames.join(", ")}'),
            ],
          ),
        ),
        trailing: medication.isPRN
            ? IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => notifier.incrementDoseCount(medication),
                tooltip: 'Add dose',
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dosage section
                _buildInfoRow(
                  context: context,
                  icon: Icons.medical_services,
                  label: 'Dosage',
                  value: medication.dosage,
                ),
                const SizedBox(height: 12),

                // Conditions section
                _buildInfoRow(
                  context: context,
                  icon: Icons.healing,
                  label: medication.conditionNames.length > 1
                      ? 'Conditions'
                      : 'Condition',
                  value: conditionDisplayNames.join(', '),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Timing section
                if (medication.isPRN)
                  _buildPRNSection(context, notifier)
                else
                  _buildScheduledSection(context),

                const SizedBox(height: 16),

                // Action buttons
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPRNSection(BuildContext context, MedicationNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber, size: 20),
            const SizedBox(width: 8),
            Text(
              'Take as needed (PRN)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Maximum: ${medication.maxDailyDoses ?? 'Not specified'} doses per day',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: medication.currentDoseCount > 0
                        ? () => notifier.decrementDoseCount(medication)
                        : null,
                    icon: const Icon(Icons.remove, size: 18),
                    label: const Text('Decrease'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => notifier.incrementDoseCount(medication),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Increase'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: medication.currentDoseCount > 0
                        ? () => notifier.resetDoseCount(medication)
                        : null,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduledSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.schedule, size: 20),
            const SizedBox(width: 8),
            Text(
              'Scheduled Times',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (medication.scheduledTimes.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 28.0),
            child: Text(
              'No times scheduled',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          )
        else
          ...medication.scheduledTimes.map((time) {
            return Padding(
              padding: const EdgeInsets.only(left: 28.0, bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    TimeFormattingUtils.formatTime(time),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit'),
          onPressed: onEdit,
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete'),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
