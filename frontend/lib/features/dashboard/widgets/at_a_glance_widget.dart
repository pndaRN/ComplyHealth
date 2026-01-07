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
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.textTheme.titleLarge?.color,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'At A Glance',
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
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1),
                if (widget.conditions.isEmpty)
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
                  ...widget.conditions.map((condition) {
                    final related = widget.medications
                        .where(
                          (medication) => medication.conditionNames.contains(
                            condition.name,
                          ),
                        )
                        .toList();
                    return ListTile(
                      leading: Icon(
                        Icons.healing,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(condition.commonName),
                      subtitle: related.isEmpty
                          ? const Text('No medications yet')
                          : Text(
                              related
                                  .map((m) => '▸ ${m.name} - ${m.dosage}')
                                  .join('\n'),
                            ),
                    );
                  }),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
