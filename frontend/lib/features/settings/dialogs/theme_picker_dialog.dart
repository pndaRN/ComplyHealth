import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme_type.dart';
import '../../../core/theme/theme_provider.dart';
import '../widgets/theme_preview_card.dart';

/// Dialog for selecting app theme with visual preview cards
class ThemePickerDialog extends ConsumerWidget {
  const ThemePickerDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider).themeType;
    final theme = Theme.of(context);

    // Group themes by category
    final groupedThemes = <ThemeCategory, List<AppThemeType>>{};
    for (final t in AppThemeType.allThemes) {
      groupedThemes.putIfAbsent(t.category, () => []).add(t);
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 550),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.palette, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Choose Theme',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final category in ThemeCategory.values) ...[
                        if (groupedThemes[category]?.isNotEmpty ?? false) ...[
                          // Category header
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 12),
                            child: Text(
                              category.displayName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Theme cards grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.4,
                            children: [
                              for (final t in groupedThemes[category]!)
                                ThemePreviewCard(
                                  themeType: t,
                                  isSelected: t.id == currentTheme.id,
                                  onTap: () {
                                    ref.read(themeProvider.notifier).setTheme(t);
                                    Navigator.pop(context);
                                  },
                                ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Close button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
