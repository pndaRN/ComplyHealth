import 'package:flutter/material.dart';
import '../../../core/theme/app_theme_type.dart';
import '../../../core/theme/theme_palettes.dart';

/// Visual preview card showing theme colors
class ThemePreviewCard extends StatelessWidget {
  final AppThemeType themeType;
  final bool isSelected;
  final VoidCallback onTap;

  const ThemePreviewCard({
    super.key,
    required this.themeType,
    required this.isSelected,
    required this.onTap,
  });

  ThemePalette _getPalette() {
    return getPaletteForThemeId(themeType.id);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _getPalette();
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSelected ? 13 : 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color swatches preview
              SizedBox(
                height: 50,
                child: Row(
                  children: [
                    Expanded(child: Container(color: palette.primary)),
                    Expanded(child: Container(color: palette.secondary)),
                    Expanded(child: Container(color: palette.surface)),
                    Expanded(child: Container(color: palette.background)),
                  ],
                ),
              ),
              // Theme name and icon
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: palette.surface,
                ),
                child: Row(
                  children: [
                    Icon(
                      themeType.icon,
                      size: 16,
                      color: palette.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        themeType.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: palette.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
