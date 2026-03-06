import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/disease.dart';
import '../../core/state/conditions_provider.dart';
import '../../core/state/medication_provider.dart';
import '../../core/widgets/app_bar_widgets.dart';
import 'dialogs/medication_add_dialog.dart';
import 'tabs/all_medications_tab.dart';
import 'tabs/mar_tab.dart';
import 'utils/medication_sorter.dart';
import '../../core/services/pdf_export_service.dart';
import '../../core/theme/status_colors.dart';

class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conditionsAsync = ref.watch(conditionsProvider);
    final isAllMedsTab = _tabController.index == 1;
    final notifier = ref.read(medicationProvider.notifier);
    final currentSortOption = notifier.sortOption;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isAllMedsTab ? 112 : 48),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Daily MAR'),
                  Tab(text: 'My Medications'),
                ],
              ),
              if (isAllMedsTab)
                AppSearchBar(
                  searchQuery: _searchQuery,
                  hintText: 'Search medications...',
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                  onClear: () {
                    setState(() => _searchQuery = '');
                  },
                ),
            ],
          ),
        ),
        actions: [
          AppMoreMenu(
            additionalItems: isAllMedsTab
                ? [
                    PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, size: 20),
                          const SizedBox(width: 12),
                          const Text('Export to PDF'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'sort',
                      child: Row(
                        children: [
                          const Icon(Icons.sort, size: 20),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('Sort by')),
                          const Icon(Icons.arrow_right),
                        ],
                      ),
                    ),
                  ]
                : null,
            onSelected: (value) async {
              if (value == 'export') {
                try {
                  final service = PdfExportService();
                  await service.exportMedicationReport(
                    context: context,
                    ref: ref,
                  );
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
              } else if (value == 'sort') {
                final selected = await showMenu<MedicationSortOption>(
                  context: context,
                  position: const RelativeRect.fromLTRB(100, 100, 0, 0),
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
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const MarTab(),
          AllMedicationsTab(
            searchQuery: _searchQuery,
            onRefresh: () {
              // Refresh logic handled internally or via provider invalidation if needed
            },
          ),
        ],
      ),
      floatingActionButton: isAllMedsTab
          ? FloatingActionButton(
              onPressed: () =>
                  _showAddDialog(context, conditionsAsync.asData?.value ?? []),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddDialog(BuildContext context, List<Disease> conditions) async {
    if (conditions.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Add Medication'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please add at least one condition first from the Health tab.',
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the Health icon in the bottom navigation to get started.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const MedicationAddSheet(),
    );
  }
}
