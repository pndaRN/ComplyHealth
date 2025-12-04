import 'package:flutter/material.dart';
import '../../../core/models/disease.dart';

class ConditionCard extends StatelessWidget {
  final Disease condition;
  final bool isAdded;
  final int medicationCount;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final bool showToggle;

  const ConditionCard({
    super.key,
    required this.condition,
    required this.isAdded,
    required this.medicationCount,
    required this.onTap,
    required this.onToggle,
    this.showToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = condition.commonName.isNotEmpty == true
        ? condition.commonName
        : condition.name;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Condition info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display name
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Category and code
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            condition.category,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          condition.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          condition.code,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    // Show medication count if added
                    if (isAdded && medicationCount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.medication,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$medicationCount medication${medicationCount != 1 ? 's' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Add/Remove toggle and arrow
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showToggle)
                    IconButton(
                      icon: Icon(
                        isAdded ? Icons.check_circle : Icons.add_circle_outline,
                        color: isAdded
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      onPressed: onToggle,
                      tooltip: isAdded ? 'Remove condition' : 'Add condition',
                    ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
