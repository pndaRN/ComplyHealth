import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/disease.dart';
import '../../core/services/icd_service.dart';
import '../../core/state/settings_provider.dart';
import '../../core/state/conditions_provider.dart';
import '../../core/state/medication_provider.dart';
import '../../core/utils/condition_helper.dart';
import '../medications/dialogs/medication_add_dialog.dart';
import 'widgets/onboarding_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    await ref.read(settingsProvider.notifier).setOnboardingCompleted(true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == 3;
    final conditionsAsync = ref.watch(conditionsProvider);
    final medicationsAsync = ref.watch(medicationProvider);

    final conditions = conditionsAsync.value ?? [];
    final medications = medicationsAsync.value ?? [];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text('Skip'),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  // Page 1: Welcome
                  OnboardingPage(
                    icon: Icons.health_and_safety,
                    title: 'Welcome to ComplyHealth',
                    description:
                        'Your personal health companion for tracking chronic conditions and medications.',
                  ),
                  // Page 2: Conditions
                  _buildConditionsPage(conditions),
                  // Page 3: Medications
                  _buildMedicationsPage(conditions, medications),
                  // Page 4: Get Started
                  OnboardingPage(
                    icon: Icons.insights,
                    title: 'You\'re All Set!',
                    description:
                        'Track your medication adherence and view your health journey over time. You can always add more conditions and medications later.',
                    action: _buildSummary(conditions, medications),
                  ),
                ],
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _nextPage,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(isLastPage ? 'Get Started' : 'Next'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsPage(List<Disease> userConditions) {
    return OnboardingPage(
      icon: Icons.healing,
      title: 'Track Your Conditions',
      description: 'Add your chronic conditions from our curated database.',
      action: Column(
        children: [
          if (userConditions.isNotEmpty) ...[
            _buildAddedConditionsChips(userConditions),
            const SizedBox(height: 16),
          ],
          OutlinedButton.icon(
            onPressed: () => _showConditionPicker(),
            icon: const Icon(Icons.add),
            label: Text(
              userConditions.isEmpty
                  ? 'Add Your Conditions'
                  : 'Add More Conditions',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddedConditionsChips(List<Disease> conditions) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: conditions.map((condition) {
            return Chip(
              label: Text(
                ConditionHelper.getDisplayName(condition),
                style: theme.textTheme.bodySmall,
              ),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => _removeCondition(condition),
              backgroundColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMedicationsPage(List<Disease> conditions, List medications) {
    final theme = Theme.of(context);

    return OnboardingPage(
      icon: Icons.medication,
      title: 'Manage Medications',
      description: 'Add your medications with dosages and schedules.',
      action: Column(
        children: [
          if (medications.isNotEmpty) ...[
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: medications.map((med) {
                    return Chip(
                      label: Text(
                        '${med.name} (${med.dosage})',
                        style: theme.textTheme.bodySmall,
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeMedication(med.id),
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (conditions.isEmpty)
            Text(
              'Add conditions first to link medications',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _showAddMedicationDialog(),
              icon: const Icon(Icons.add),
              label: Text(
                medications.isEmpty
                    ? 'Add Your Medications'
                    : 'Add More Medications',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary(List<Disease> conditions, List medications) {
    final theme = Theme.of(context);

    if (conditions.isEmpty && medications.isEmpty) {
      return Text(
        'You can add conditions and medications anytime from the app.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      );
    }

    return Column(
      children: [
        if (conditions.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${conditions.length} condition${conditions.length != 1 ? 's' : ''} added',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        if (medications.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${medications.length} medication${medications.length != 1 ? 's' : ''} added',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _showConditionPicker() async {
    final allConditions = await ICDService.loadAll();
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => _ConditionPickerDialog(
        allConditions: allConditions,
        onAdd: _addCondition,
        onRemove: _removeCondition,
      ),
    );
  }

  Future<void> _addCondition(Disease condition) async {
    await ref.read(conditionsProvider.notifier).addCondition(condition);
  }

  Future<void> _removeCondition(Disease condition) async {
    await ref.read(conditionsProvider.notifier).removeCondition(condition);
  }

  void _showAddMedicationDialog() {
    showDialog(
      context: context,
      builder: (context) => const MedicationAddDialog(),
    );
  }

  void _removeMedication(String id) {
    final medications = ref.read(medicationProvider).value ?? [];
    final med = medications.firstWhere((m) => m.id == id);
    ref.read(medicationProvider.notifier).deleteMeds(med);
  }
}

/// Dialog for picking conditions
class _ConditionPickerDialog extends ConsumerStatefulWidget {
  final List<Disease> allConditions;
  final Future<void> Function(Disease) onAdd;
  final Future<void> Function(Disease) onRemove;

  const _ConditionPickerDialog({
    required this.allConditions,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  ConsumerState<_ConditionPickerDialog> createState() =>
      _ConditionPickerDialogState();
}

class _ConditionPickerDialogState
    extends ConsumerState<_ConditionPickerDialog> {
  String _searchQuery = '';

  List<Disease> get _filteredConditions {
    if (_searchQuery.isEmpty) return widget.allConditions;
    final query = _searchQuery.toLowerCase();
    return widget.allConditions.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.commonName.toLowerCase().contains(query) ||
          c.code.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userConditions = ref.watch(conditionsProvider).value ?? [];
    final grouped = _groupByCategory(_filteredConditions);
    final sortedCategories = grouped.keys.toList()..sort();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add Conditions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search conditions...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
            // List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sortedCategories.length,
                itemBuilder: (context, index) {
                  final category = sortedCategories[index];
                  final conditions = grouped[category]!;

                  return ExpansionTile(
                    title: Text(
                      category,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text('${conditions.length} conditions'),
                    initiallyExpanded: _searchQuery.isNotEmpty,
                    children: conditions.map((condition) {
                      final isAdded = userConditions.any(
                        (c) => c.code == condition.code,
                      );
                      return ListTile(
                        title: Text(ConditionHelper.getDisplayName(condition)),
                        subtitle: Text('${condition.name} • ${condition.code}'),
                        trailing: isAdded
                            ? Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                              )
                            : Icon(
                                Icons.add_circle_outline,
                                color: theme.colorScheme.outline,
                              ),
                        onTap: () {
                          if (isAdded) {
                            widget.onRemove(condition);
                          } else {
                            widget.onAdd(condition);
                          }
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Disease>> _groupByCategory(List<Disease> conditions) {
    final grouped = <String, List<Disease>>{};
    for (final condition in conditions) {
      grouped.putIfAbsent(condition.category, () => []).add(condition);
    }
    return grouped;
  }
}
