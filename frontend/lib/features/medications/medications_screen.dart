import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/medication.dart';
import '../../core/state/medication_provider.dart';
import '../../core/state/conditions_provider.dart';
import '../conditions/add_condition_dialog.dart';
import 'dialogs/medication_add_dialog.dart';
import 'dialogs/medication_edit_dialog.dart';
import 'utils/medication_sorter.dart';

class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({super.key});

  String _getTimingSummary(Medication medication) {
    if (medication.isPRN) {
      return 'As needed (PRN)';
    }

    final count = medication.scheduledTimes.length;
    if (count == 0) {
      return 'No schedule';
    } else if (count == 1) {
      return 'Once daily';
    } else {
      return '$count times daily';
    }
  }

  String _formatTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final displayMinute = minute.toString().padLeft(2, '0');
        return '$displayHour:$displayMinute $period';
      }
    } catch (e) {
      // Return original if parsing fails
    }
    return timeString;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meds = ref.watch(medicationProvider);
    final notifier = ref.read(medicationProvider.notifier);
    final currentSortOption = notifier.sortOption;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        actions: [
          PopupMenuButton<MedicationSortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort medications',
            onSelected: (option) => notifier.setSortOption(option),
            itemBuilder: (context) => MedicationSortOption.values.map((option) {
              return PopupMenuItem(
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
          ),
        ],
      ),
      body: meds.isEmpty
          ? const Center(child: Text('No medications yet.'))
          : _buildMedicationsList(context, ref, meds, currentSortOption),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMedicationsList(
    BuildContext context,
    WidgetRef ref,
    List<Medication> meds,
    MedicationSortOption sortOption,
  ) {
    if (sortOption == MedicationSortOption.groupedByCondition) {
      return _buildGroupedList(context, ref, meds);
    } else {
      return _buildSimpleList(context, ref, meds);
    }
  }

  Widget _buildSimpleList(BuildContext context, WidgetRef ref, List<Medication> meds) {
    final notifier = ref.read(medicationProvider.notifier);

    return ListView.builder(
      itemCount: meds.length,
      itemBuilder: (context, i) {
        final m = meds[i];
        final conditions = ref.watch(conditionsProvider);

        // Get display names for conditions
        final conditionDisplayNames = m.conditionNames.map((name) {
          final matchingConditions = conditions.where((c) => c.name == name);
          if (matchingConditions.isEmpty) return name;
          final condition = matchingConditions.first;
          return condition.commonName.isNotEmpty ? condition.commonName : name;
        }).toList();

        final timingSummary = _getTimingSummary(m);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            title: Text('${m.name} — ${m.dosage}'),
            subtitle: Text('$timingSummary • For: ${conditionDisplayNames.join(", ")}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dosage section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.medical_services, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dosage',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Text(
                                m.dosage,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Conditions section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.healing, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.conditionNames.length > 1 ? 'Conditions' : 'Condition',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Text(
                                conditionDisplayNames.join(', '),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Timing section
                    if (m.isPRN) ...[
                      Row(
                        children: [
                          const Icon(Icons.warning_amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Take as needed (PRN)',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 28.0),
                        child: Text(
                          'Maximum: ${m.maxDailyDoses ?? 'Not specified'} doses per day',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Scheduled Times',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (m.scheduledTimes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(left: 28.0),
                          child: Text('No times scheduled', style: TextStyle(fontStyle: FontStyle.italic)),
                        )
                      else
                        ...m.scheduledTimes.map((time) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 28.0, bottom: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(time),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                    const SizedBox(height: 16),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                          onPressed: () => _showEditDialog(context, m),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                          onPressed: () => notifier.deleteMeds(m),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupedList(BuildContext context, WidgetRef ref, List<Medication> meds) {
    final notifier = ref.read(medicationProvider.notifier);
    final conditions = ref.watch(conditionsProvider);

    // Build a list of widgets with section headers
    final List<Widget> items = [];
    String? currentCondition;

    for (final m in meds) {
      // For grouped view, we need to determine which condition this medication instance belongs to
      // Since medications can have multiple conditions, we'll show the first condition as the group
      final firstConditionName = m.conditionNames.isNotEmpty ? m.conditionNames.first : 'Unknown';

      // Add section header if this is a new condition group
      if (currentCondition != firstConditionName) {
        currentCondition = firstConditionName;

        // Get display name for condition
        final matchingConditions = conditions.where((c) => c.name == firstConditionName);
        final displayName = matchingConditions.isNotEmpty && matchingConditions.first.commonName.isNotEmpty
            ? matchingConditions.first.commonName
            : firstConditionName;

        items.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              displayName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }

      // Get display names for all conditions
      final conditionDisplayNames = m.conditionNames.map((name) {
        final matchingConditions = conditions.where((c) => c.name == name);
        if (matchingConditions.isEmpty) return name;
        final condition = matchingConditions.first;
        return condition.commonName.isNotEmpty ? condition.commonName : name;
      }).toList();

      // Add medication tile
      final timingSummary = _getTimingSummary(m);
      items.add(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            title: Text('${m.name} — ${m.dosage}'),
            subtitle: Text(timingSummary),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dosage section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.medical_services, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dosage',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Text(
                                m.dosage,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Conditions section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.healing, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.conditionNames.length > 1 ? 'Conditions' : 'Condition',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Text(
                                conditionDisplayNames.join(', '),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Timing section
                    if (m.isPRN) ...[
                      Row(
                        children: [
                          const Icon(Icons.warning_amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Take as needed (PRN)',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 28.0),
                        child: Text(
                          'Maximum: ${m.maxDailyDoses ?? 'Not specified'} doses per day',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Scheduled Times',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (m.scheduledTimes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(left: 28.0),
                          child: Text('No times scheduled', style: TextStyle(fontStyle: FontStyle.italic)),
                        )
                      else
                        ...m.scheduledTimes.map((time) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 28.0, bottom: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(time),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                    const SizedBox(height: 16),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                          onPressed: () => _showEditDialog(context, m),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                          onPressed: () => notifier.deleteMeds(m),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(children: items);
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) async {
    final conditions = ref.read(conditionsProvider);

    if (conditions.isEmpty) {
      // Show simplified dialog to add condition first
      final shouldOpenConditionDialog = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Add Medication'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please add at least one condition first.'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Condition'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      // If user clicked "Add Condition", open the condition dialog
      if (shouldOpenConditionDialog == true && context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => const AddConditionDialog(),
        );

        // After condition dialog closes, check if conditions were added and reopen
        if (context.mounted) {
          final updatedConditions = ref.read(conditionsProvider);
          if (updatedConditions.isNotEmpty) {
            // Use addPostFrameCallback to ensure clean dialog transition
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                _showAddDialog(context, ref);
              }
            });
          }
        }
      }
      return;
    }

    // Normal flow when conditions exist
    showDialog(
      context: context,
      builder: (context) => const MedicationAddDialog(),
    );
  }

  void _showEditDialog(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (context) => MedicationEditDialog(medication: medication),
    );
  }
}
