import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/disease.dart';
import '../../core/services/icd_service.dart';
import '../../core/state/conditions_provider.dart';
import '../../core/state/medication_provider.dart';
import 'condition_detail_screen.dart';
import 'widgets/condition_card.dart';

enum HealthViewMode { myConditions, browseAll }

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
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
    final theme = Theme.of(context);
    final userConditions = ref.watch(conditionsProvider);
    final medications = ref.watch(medicationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Filter chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('My Conditions (${userConditions.length})'),
                      selected: _viewMode == HealthViewMode.myConditions,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _viewMode = HealthViewMode.myConditions);
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

  Widget _buildMyConditionsView(List<Disease> userConditions, List medications) {
    final theme = Theme.of(context);

    // Filter by search query
    final filteredConditions = _searchQuery.isEmpty
        ? userConditions
        : userConditions.where((condition) {
            final searchLower = _searchQuery.toLowerCase();
            return condition.name.toLowerCase().contains(searchLower) ||
                (condition.commonName?.toLowerCase().contains(searchLower) ??
                    false) ||
                condition.code.toLowerCase().contains(searchLower);
          }).toList();

    if (userConditions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.healing_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No conditions yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Browse All" to add your first condition',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (filteredConditions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No conditions found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
        );
      },
    );
  }

  Widget _buildBrowseAllView(List<Disease> userConditions, List medications) {
    final theme = Theme.of(context);

    // Filter by search query
    final filteredConditions = _searchQuery.isEmpty
        ? _allConditions
        : _allConditions.where((condition) {
            final searchLower = _searchQuery.toLowerCase();
            return condition.name.toLowerCase().contains(searchLower) ||
                (condition.commonName?.toLowerCase().contains(searchLower) ??
                    false) ||
                condition.code.toLowerCase().contains(searchLower);
          }).toList();

    if (filteredConditions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No conditions found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Group by category
    final groupedConditions = <String, List<Disease>>{};
    for (final condition in filteredConditions) {
      groupedConditions.putIfAbsent(condition.category, () => []).add(condition);
    }

    // Sort categories alphabetically
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
          subtitle: Text('${conditions.length} condition${conditions.length != 1 ? 's' : ''}'),
          initiallyExpanded: _searchQuery.isNotEmpty || sortedCategories.length == 1,
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
          content: Text('Added ${condition.commonName != null && condition.commonName!.isNotEmpty ? condition.commonName : condition.name}'),
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
          content: Text('Removed ${condition.commonName != null && condition.commonName!.isNotEmpty ? condition.commonName : condition.name}'),
        ),
      );
    }
  }
}
