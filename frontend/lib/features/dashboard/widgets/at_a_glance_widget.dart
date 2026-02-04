import 'package:flutter/material.dart';
import '../../../core/models/disease.dart';
import '../../../core/models/medication.dart';

class AtAGlanceWidget extends StatelessWidget {
  final List<Disease> conditions;
  final List<Medication> medications;

  const AtAGlanceWidget({
    super.key,
    required this.conditions,
    required this.medications,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Health Overview',
                      maxLines: 1,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (conditions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No conditions tracked yet.\nAdd a condition to get started!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: conditions.map((condition) {
                  final related = medications
                      .where(
                        (medication) =>
                            medication.conditionNames.contains(condition.name),
                      )
                      .toList();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.healing,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        condition.commonName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: related.isEmpty
                          ? const Text('No medications yet')
                          : Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                related
                                    .map((m) => '▸ ${m.name} - ${m.dosage}')
                                    .join('\n'),
                              ),
                            ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
