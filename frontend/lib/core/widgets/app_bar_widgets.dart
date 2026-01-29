import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_provider.dart';

/// A standardized PopupMenuButton for app bars that includes theme toggling
/// and supports additional screen-specific actions.
class AppMoreMenu extends ConsumerWidget {
  final List<PopupMenuEntry<String>>? additionalItems;
  final void Function(String)? onSelected;
  final Color? iconColor;

  const AppMoreMenu({
    super.key,
    this.additionalItems,
    this.onSelected,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final isCurrentlyDark =
        themeState.themeMode == ThemeMode.dark ||
        (themeState.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: iconColor),
      onSelected: (value) {
        if (value == 'theme') {
          ref.read(themeProvider.notifier).toggleTheme();
        } else if (onSelected != null) {
          onSelected!(value);
        }
      },
      itemBuilder: (context) => [
        if (additionalItems != null) ...additionalItems!,
        PopupMenuItem(
          value: 'theme',
          child: Row(
            children: [
              Icon(
                isCurrentlyDark ? Icons.light_mode : Icons.dark_mode,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(isCurrentlyDark ? 'Light mode' : 'Dark mode'),
            ],
          ),
        ),
      ],
    );
  }
}

/// A consistent search bar widget for use in AppBar bottoms or screen headers
class AppSearchBar extends StatelessWidget {
  final String searchQuery;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const AppSearchBar({
    super.key,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: onClear,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
