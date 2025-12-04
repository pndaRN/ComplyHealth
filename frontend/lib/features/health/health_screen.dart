import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/disease.dart';
import '../../core/services/icd_service.dart';
import '../../core/state/conditions_provider.dart';
import '../../core/state/medication_provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/condition_helper.dart';
import '../../core/widgets/empty_state_widget.dart';
import 'condition_detail_screen.dart';
import 'widgets/condition_card.dart';
import 'dialogs/add_custom_condition_dialog.dart';
import 'dialogs/report_condition_dialog.dart';

enum HealthViewMode { myConditions, browseAll }

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  // UI sizing constants
  static const double _appBarBottomHeight = 120.0;

  HealthViewMode _viewMode = HealthViewMode.myConditions;
  String _searchQuery = '';
  List<Disease> _allConditions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllConditions();
  }

  Future<void> _loadAllConditions() async {
    setState(() => _isLoading = true);
    final conditions = await ICDService.loadAll();
    setState(() {
      _allConditions = conditions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userConditions = ref.watch(conditionsProvider);
    final medications = ref.watch(medicationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final themeState = ref.watch(themeProvider);
              final isDark = themeState.themeMode == ThemeMode.dark ||
                  (themeState.themeMode == ThemeMode.system &&
                      MediaQuery.of(context).platformBrightness == Brightness.dark);

              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(_appBarBottomHeight),
          child: Column(
            children: [
              // Filter chips
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('My Conditions (${userConditions.length})'),
                      selected: _viewMode == HealthViewMode.myConditions,
                      onSelected: (selected) {
                        if (selected) {
                          setState(
                            () => _viewMode = HealthViewMode.myConditions,
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Browse All'),
                      selected: _viewMode == HealthViewMode.browseAll,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _viewMode = HealthViewMode.browseAll);
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search conditions...',
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
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(userConditions, medications),
    );
  }

  Widget _buildBody(List<Disease> userConditions, List medications) {
    if (_viewMode == HealthViewMode.myConditions) {
      return _buildMyConditionsView(userConditions, medications);
    } else {
      return _buildBrowseAllView(userConditions, medications);
    }
  }

  Widget _buildMyConditionsView(
    List<Disease> userConditions,
    List medications,
  ) {
    // Filter by search query
    final filteredConditions = _filterConditionsBySearch(userConditions);

    if (userConditions.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.healing_outlined,
        title: 'No conditions yet',
        subtitle: 'Tap "Browse All" to add your first condition',
      );
    }

    if (filteredConditions.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off,
        title: 'No conditions found',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredConditions.length,
      itemBuilder: (context, index) {
        final condition = filteredConditions[index];
        final medCount = medications
            .where((m) => m.conditionNames.contains(condition.name))
            .length;

        return ConditionCard(
          condition: condition,
          isAdded: true,
          medicationCount: medCount,
          onTap: () => _navigateToDetail(condition),
          onToggle: () => _removeCondition(condition),
          showToggle: false,
        );
      },
    );
  }

  /// Filters conditions by search query across name, common name, and code
  List<Disease> _filterConditionsBySearch(List<Disease> conditions) {
    if (_searchQuery.isEmpty) return conditions;

    return conditions.where((condition) {
      final searchLower = _searchQuery.toLowerCase();
      return condition.name.toLowerCase().contains(searchLower) ||
          condition.commonName.toLowerCase().contains(searchLower) ||
          condition.code.toLowerCase().contains(searchLower);
    }).toList();
  }

  /// Groups conditions by category and returns sorted category list
  Map<String, List<Disease>> _groupConditionsByCategory(
    List<Disease> conditions,
  ) {
    final groupedConditions = <String, List<Disease>>{};
    for (final condition in conditions) {
      groupedConditions.putIfAbsent(condition.category, () => []).add(condition);
    }
    return groupedConditions;
  }

  Widget _buildBrowseAllView(List<Disease> userConditions, List medications) {
    final theme = Theme.of(context);

    // Filter by search query
    final filteredConditions = _filterConditionsBySearch(_allConditions);

    if (filteredConditions.isEmpty && _searchQuery.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: EmptyStateWidget(
          icon: Icons.search_off,
          title: 'No conditions found',
          action: Card(
            child: InkWell(
              onTap: _addCustomCondition,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Can\'t find your condition?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add it as a custom condition',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Group by category and sort
    final groupedConditions = _groupConditionsByCategory(filteredConditions);
    final sortedCategories = groupedConditions.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedCategories.length,
      itemBuilder: (context, categoryIndex) {
        final category = sortedCategories[categoryIndex];
        final conditions = groupedConditions[category]!;

        return ExpansionTile(
          title: Text(
            category,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${conditions.length} condition${conditions.length != 1 ? 's' : ''}',
          ),
          initiallyExpanded:
              _searchQuery.isNotEmpty || sortedCategories.length == 1,
          children: conditions.map((condition) {
            final isAdded = userConditions.any((c) => c.code == condition.code);
            final medCount = isAdded
                ? medications
                      .where((m) => m.conditionNames.contains(condition.name))
                      .length
                : 0;

            return ConditionCard(
              condition: condition,
              isAdded: isAdded,
              medicationCount: medCount,
              onTap: () => _navigateToDetail(condition),
              onToggle: () => isAdded
                  ? _removeCondition(condition)
                  : _addCondition(condition),
            );
          }).toList(),
        );
      },
    );
  }

  void _navigateToDetail(Disease condition) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConditionDetailScreen(condition: condition),
      ),
    );
  }

  Future<void> _addCondition(Disease condition) async {
    final notifier = ref.read(conditionsProvider.notifier);
    await notifier.addCondition(condition);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${ConditionHelper.getDisplayName(condition)}',
          ),
        ),
      );
    }
  }

  Future<void> _removeCondition(Disease condition) async {
    final notifier = ref.read(conditionsProvider.notifier);
    await notifier.removeCondition(condition);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Removed ${ConditionHelper.getDisplayName(condition)}',
          ),
        ),
      );
    }
  }

  Future<void> _addCustomCondition() async {
    // Show dialog to create custom condition
    final customCondition = await showDialog<Disease>(
      context: context,
      builder: (context) => const AddCustomConditionDialog(),
    );

    // If user canceled, return early
    if (customCondition == null || !mounted) return;

    // Show report prompt dialog
    await showDialog(
      context: context,
      builder: (context) => ReportConditionDialog(
        conditionName: customCondition.name,
        userId: null, // Can be set if user authentication is implemented
      ),
    );

    // Add the custom condition to user's conditions
    if (mounted) {
      await _addCondition(customCondition);
    }
  }
}
