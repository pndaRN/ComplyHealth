import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/disease.dart';
import '../../core/state/conditions_provider.dart';
import 'dialogs/medication_add_dialog.dart';
import 'tabs/all_medications_tab.dart';
import 'tabs/mar_tab.dart';
import 'widgets/medications_app_bar_actions.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isAllMedsTab ? 128 : 48),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search medications...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor:
                          Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFFF0F7FF)
                          : const Color(0xFF1E3A5F),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: isAllMedsTab ? const [MedicationsAppBarActions()] : null,
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

    showDialog(
      context: context,
      builder: (context) => const MedicationAddDialog(),
    );
  }
}
