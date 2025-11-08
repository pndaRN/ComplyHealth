import 'package:flutter/material.dart';
import '../../../core/models/medication.dart';
import '../../../core/models/disease.dart';

class MedicationDetailDialog extends StatelessWidget {
  final Medication medication;
  final List<Disease> conditions;

  const MedicationDetailDialog({
    super.key,
    required this.medication,
    required this.conditions,
  });

  String _formatTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final displayMinute = minute.toString().padLeft(2, '0');
        return '$displayHour:$displayMinute $period';
      }
    } catch (e) {
      // Return original if parsing fails
    }
    return timeString;
  }

  @override
  Widget build(BuildContext context) {
    // Get display names for conditions
    final conditionDisplayNames = medication.conditionNames.map((name) {
      final matchingConditions = conditions.where((c) => c.name == name);
      if (matchingConditions.isEmpty) return name;
      final condition = matchingConditions.first;
      return condition.commonName.isNotEmpty ? condition.commonName : name;
    }).toList();

    return AlertDialog(
      title: Text(medication.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(
              icon: Icons.medical_services,
              label: 'Dosage',
              value: medication.dosage,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.healing,
              label: medication.conditionNames.length > 1 ? 'Conditions' : 'Condition',
              value: conditionDisplayNames.join(', '),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            if (medication.isPRN) ...[
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
              _DetailRow(
                icon: Icons.repeat,
                label: 'Maximum per day',
                value: medication.maxDailyDoses != null
                    ? '${medication.maxDailyDoses} doses'
                    : 'Not specified',
              ),
            ] else ...[
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
                  child: Text('No times scheduled', style: TextStyle(fontStyle: FontStyle.italic)),
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
                          _formatTime(time),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
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
}
