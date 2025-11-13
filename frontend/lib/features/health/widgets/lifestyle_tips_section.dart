import 'package:flutter/material.dart';

class LifestyleTipsSection extends StatelessWidget {
  final List<String> tips;

  const LifestyleTipsSection({
    super.key,
    required this.tips,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (tips.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'No lifestyle tips available yet',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lifestyle Tips',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...tips.asMap().entries.map((entry) {
          final index = entry.key;
          final tip = entry.value;
          return _buildTipCard(context, tip, index);
        }),
      ],
    );
  }

  Widget _buildTipCard(BuildContext context, String tip, int index) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                tip,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
