import 'package:flutter/material.dart';
import '../../../core/models/medication.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final List<String> conditionDisplayNames;
  final String timingSummary;
  final Color? doseColor;
  final VoidCallback onTap;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.conditionDisplayNames,
    required this.timingSummary,
    this.doseColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Medication info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and dosage
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            medication.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (medication.isPRN)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PRN',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Dosage
                    Text(
                      medication.dosage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Timing and conditions
                    Row(
                      children: [
                        Icon(
                          medication.isPRN ? Icons.warning_amber : Icons.schedule,
                          size: 16,
                          color: doseColor ?? theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timingSummary,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: doseColor ?? theme.colorScheme.onSurfaceVariant,
                            fontWeight: medication.isPRN ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                    if (conditionDisplayNames.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.healing,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              conditionDisplayNames.join(', '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
