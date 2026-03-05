import 'package:flutter/material.dart';
import '../../../core/models/disease.dart';
import '../../../core/models/medication.dart';

class AtAGlanceWidget extends StatefulWidget {
  final List<Disease> conditions;
  final List<Medication> medications;

  const AtAGlanceWidget({
    super.key,
    required this.conditions,
    required this.medications,
  });

  @override
  State<AtAGlanceWidget> createState() => _AtAGlanceWidgetState();
}

class _AtAGlanceWidgetState extends State<AtAGlanceWidget> {
  final Map<String, bool> _expandedStates = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.conditions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No conditions tracked yet.\nAdd a condition to get started!',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: widget.conditions.map((condition) {
          final related = widget.medications
              .where(
                (medication) =>
                    medication.conditionNames.contains(condition.name),
              )
              .toList();

          final isExpanded = _expandedStates[condition.code] ?? false;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              key: PageStorageKey(condition.code),
              leading: Icon(
                Icons.healing,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                condition.commonName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${related.length} medication${related.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              initiallyExpanded: isExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandedStates[condition.code] = expanded;
                });
              },
              children: [
                if (related.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No medications yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                else
                  ...related.map(
                    (medication) => ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.medication,
                        size: 20,
                        color: theme.colorScheme.secondary,
                      ),
                      title: Text(medication.name),
                      subtitle: Text(medication.dosage),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
