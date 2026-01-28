import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../core/state/medication_provider.dart';
import '../../../core/theme/status_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../utils/medication_sorter.dart';

class MedicationsAppBarActions extends ConsumerWidget {
  const MedicationsAppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final notifier = ref.read(medicationProvider.notifier);
    final currentSortOption = notifier.sortOption;
    final isDark =
        themeState.themeMode == ThemeMode.dark ||
        (themeState.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'theme':
            ref.read(themeProvider.notifier).toggleTheme();
            break;
          case 'export':
            try {
              final service = PdfExportService();
              await service.exportMedicationReport(context: context, ref: ref);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('PDF exported successfully'),
                    backgroundColor: Theme.of(context).statusColors.success,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Export failed: $e'),
                    backgroundColor: Theme.of(context).statusColors.error,
                  ),
                );
              }
            }
            break;
          case 'sort':
            final RenderBox button = context.findRenderObject() as RenderBox;
            final RenderBox overlay =
                Navigator.of(context).overlay!.context.findRenderObject()
                    as RenderBox;
            final RelativeRect position = RelativeRect.fromRect(
              Rect.fromPoints(
                button.localToGlobal(Offset.zero, ancestor: overlay),
                button.localToGlobal(
                  button.size.bottomRight(Offset.zero),
                  ancestor: overlay,
                ),
              ),
              Offset.zero & overlay.size,
            );
            final selected = await showMenu<MedicationSortOption>(
              context: context,
              position: position,
              items: MedicationSortOption.values.map((option) {
                return PopupMenuItem<MedicationSortOption>(
                  value: option,
                  child: Row(
                    children: [
                      if (option == currentSortOption)
                        const Icon(Icons.check, size: 20)
                      else
                        const SizedBox(width: 20),
                      const SizedBox(width: 8),
                      Text(MedicationSorter.getDisplayName(option)),
                    ],
                  ),
                );
              }).toList(),
            );
            if (selected != null) {
              await notifier.setSortOption(selected);
            }
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'theme',
          child: Row(
            children: [
              Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              const SizedBox(width: 12),
              Text(isDark ? 'Light mode' : 'Dark mode'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf),
              SizedBox(width: 12),
              Text('Export to PDF'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'sort',
          child: Row(
            children: [
              const Icon(Icons.sort),
              const SizedBox(width: 12),
              const Expanded(child: Text('Sort by')),
              const Icon(Icons.arrow_right),
            ],
          ),
        ),
      ],
    );
  }
}
