import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/medication.dart';
import '../../core/state/medication_provider.dart';
import '../../core/state/conditions_provider.dart';
import '../../core/utils/condition_helper.dart';
import '../../core/utils/time_formatting_utils.dart';
import '../../core/widgets/empty_state_widget.dart';
import 'dialogs/medication_add_dialog.dart';
import 'dialogs/medication_edit_dialog.dart';
import 'utils/medication_sorter.dart';
import 'widgets/medication_expansion_tile.dart';

class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  // Dose count color thresholds
  static const double _maxDoseRatio = 1.0;
  static const double _warningDoseRatio = 0.75;

  String _searchQuery = '';

  String _getTimingSummary(Medication medication) {
    if (medication.isPRN) {
      final current = medication.currentDoseCount;
      final max = medication.maxDailyDoses ?? 0;
      return '$current/$max doses taken today';
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

  Color _getDoseCountColor(int current, int max) {
    if (max == 0) return Colors.grey;
    final ratio = current / max;
    if (ratio >= _maxDoseRatio) return Colors.red;
    if (ratio >= _warningDoseRatio) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meds = ref.watch(medicationProvider);
    final notifier = ref.read(medicationProvider.notifier);
    final currentSortOption = notifier.sortOption;

    // Filter medications by search query
    final filteredMeds = _searchQuery.isEmpty
        ? meds
        : meds.where((medication) {
            final searchLower = _searchQuery.toLowerCase();
            final conditions = ref.read(conditionsProvider);

            // Get display names for conditions
            final conditionDisplayNames = ConditionHelper.getDisplayNames(
              conditionNames: medication.conditionNames,
              conditions: conditions,
            );

            return medication.name.toLowerCase().contains(searchLower) ||
                medication.dosage.toLowerCase().contains(searchLower) ||
                conditionDisplayNames.any((name) => name.toLowerCase().contains(searchLower));
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
        ),
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
          ? EmptyStateWidget(
              icon: Icons.medication_outlined,
              title: 'No medications yet',
              subtitle: 'Tap + to add your first medication',
            )
          : filteredMeds.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.search_off,
                  title: 'No medications found',
                )
              : _buildMedicationsList(context, filteredMeds, currentSortOption),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMedicationsList(
    BuildContext context,
    List<Medication> meds,
    MedicationSortOption sortOption,
  ) {
    if (sortOption == MedicationSortOption.groupedByCondition) {
      return _buildGroupedList(context, meds);
    } else if (sortOption == MedicationSortOption.dueTime) {
      return _buildDueTimeGroupedList(context, meds);
    } else {
      return _buildSimpleList(context, meds);
    }
  }

  Widget _buildSimpleList(BuildContext context, List<Medication> meds) {
    final notifier = ref.read(medicationProvider.notifier);

    return ListView.builder(
      itemCount: meds.length,
      itemBuilder: (context, index) {
        final medication = meds[index];
        final conditions = ref.watch(conditionsProvider);

        // Get display names for conditions
        final conditionDisplayNames = ConditionHelper.getDisplayNames(
          conditionNames: medication.conditionNames,
          conditions: conditions,
        );

        final timingSummary = _getTimingSummary(medication);
        final doseColor = medication.isPRN
            ? _getDoseCountColor(medication.currentDoseCount, medication.maxDailyDoses ?? 0)
            : null;

        return MedicationExpansionTile(
          medication: medication,
          conditionDisplayNames: conditionDisplayNames,
          timingSummary: timingSummary,
          doseColor: doseColor,
          onEdit: () => _showEditDialog(context, medication),
          onDelete: () => notifier.deleteMeds(medication),
        );
      },
    );
  }

  Widget _buildGroupedList(BuildContext context, List<Medication> meds) {
    final notifier = ref.read(medicationProvider.notifier);
    final conditions = ref.watch(conditionsProvider);

    // Build a list of widgets with section headers
    final List<Widget> items = [];
    String? currentCondition;

    for (final medication in meds) {
      // For grouped view, we need to determine which condition this medication instance belongs to
      // Since medications can have multiple conditions, we'll show the first condition as the group
      final firstConditionName = medication.conditionNames.isNotEmpty ? medication.conditionNames.first : 'Unknown';

      // Add section header if this is a new condition group
      if (currentCondition != firstConditionName) {
        currentCondition = firstConditionName;

        // Get display name for condition
        final displayName = ConditionHelper.getDisplayNameByConditionName(
          conditionName: firstConditionName,
          conditions: conditions,
        );

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
      final conditionDisplayNames = ConditionHelper.getDisplayNames(
        conditionNames: medication.conditionNames,
        conditions: conditions,
      );

      // Add medication tile
      final timingSummary = _getTimingSummary(medication);
      final doseColor = medication.isPRN
          ? _getDoseCountColor(medication.currentDoseCount, medication.maxDailyDoses ?? 0)
          : null;

      items.add(
        MedicationExpansionTile(
          medication: medication,
          conditionDisplayNames: conditionDisplayNames,
          timingSummary: timingSummary,
          doseColor: doseColor,
          onEdit: () => _showEditDialog(context, medication),
          onDelete: () => notifier.deleteMeds(medication),
        ),
      );
    }

    return ListView(children: items);
  }

  /// Formats a time in minutes since midnight to a display string with optional "Tomorrow" suffix
  String _formatTimeGroup(int timeInMinutes, int currentTime) {
    final isNextDay = timeInMinutes <= currentTime;
    final hours = timeInMinutes ~/ TimeFormattingUtils.minutesPerHour;
    final minutes = timeInMinutes % TimeFormattingUtils.minutesPerHour;
    final period = hours >= TimeFormattingUtils.noonHour ? 'PM' : 'AM';
    final displayHour = hours == 0
        ? TimeFormattingUtils.noonHour
        : (hours > TimeFormattingUtils.noonHour ? hours - TimeFormattingUtils.noonHour : hours);
    final displayMinute = minutes.toString().padLeft(2, '0');
    return isNextDay
        ? '$displayHour:$displayMinute $period (Tomorrow)'
        : '$displayHour:$displayMinute $period';
  }

  /// Compares two time group keys for sorting (PRN and No Schedule go last, others chronologically)
  int _compareTimeGroups(String keyA, String keyB) {
    // PRN and No Schedule go last
    if (keyA == 'As Needed (PRN)' && keyB != 'As Needed (PRN)') return 1;
    if (keyA != 'As Needed (PRN)' && keyB == 'As Needed (PRN)') return -1;
    if (keyA == 'No Schedule' && keyB != 'No Schedule' && keyB != 'As Needed (PRN)') return 1;
    if (keyA != 'No Schedule' && keyA != 'As Needed (PRN)' && keyB == 'No Schedule') return -1;

    // Parse times and sort chronologically
    final timeA = TimeFormattingUtils.parseTimeGroupToMinutes(keyA);
    final timeB = TimeFormattingUtils.parseTimeGroupToMinutes(keyB);

    if (timeA == null && timeB == null) return 0;
    if (timeA == null) return 1;
    if (timeB == null) return -1;

    return timeA.compareTo(timeB);
  }

  /// Creates time-grouped medication entries
  List<MapEntry<String, Medication>> _createTimeGroupedMedications(
    List<Medication> meds,
    int currentTime,
  ) {
    final List<MapEntry<String, Medication>> timeGroupedMeds = [];

    for (final medication in meds) {
      if (medication.isPRN) {
        timeGroupedMeds.add(MapEntry('As Needed (PRN)', medication));
      } else if (medication.scheduledTimes.isEmpty) {
        timeGroupedMeds.add(MapEntry('No Schedule', medication));
      } else {
        // Add an entry for each scheduled time
        for (final timeStr in medication.scheduledTimes) {
          final timeInMinutes = TimeFormattingUtils.parseTimeToMinutes(timeStr);
          if (timeInMinutes != null) {
            final timeGroup = _formatTimeGroup(timeInMinutes, currentTime);
            timeGroupedMeds.add(MapEntry(timeGroup, medication));
          }
        }
      }
    }

    return timeGroupedMeds;
  }

  Widget _buildDueTimeGroupedList(BuildContext context, List<Medication> meds) {
    final notifier = ref.read(medicationProvider.notifier);
    final conditions = ref.watch(conditionsProvider);

    final now = DateTime.now();
    final currentTime = now.hour * TimeFormattingUtils.minutesPerHour + now.minute;

    // Create and sort time-grouped medications
    final timeGroupedMeds = _createTimeGroupedMedications(meds, currentTime);
    timeGroupedMeds.sort((a, b) => _compareTimeGroups(a.key, b.key));

    // Build a list of widgets with time headers
    final List<Widget> items = [];
    String? currentTimeGroup;

    for (final entry in timeGroupedMeds) {
      final timeGroup = entry.key;
      final medication = entry.value;

      // Add time header if this is a new time group
      if (currentTimeGroup != timeGroup) {
        currentTimeGroup = timeGroup;

        items.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              timeGroup,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }

      // Get display names for all conditions
      final conditionDisplayNames = ConditionHelper.getDisplayNames(
        conditionNames: medication.conditionNames,
        conditions: conditions,
      );

      // Add medication tile
      final timingSummary = _getTimingSummary(medication);
      final doseColor = medication.isPRN
          ? _getDoseCountColor(medication.currentDoseCount, medication.maxDailyDoses ?? 0)
          : null;

      items.add(
        MedicationExpansionTile(
          medication: medication,
          conditionDisplayNames: conditionDisplayNames,
          timingSummary: timingSummary,
          doseColor: doseColor,
          onEdit: () => _showEditDialog(context, medication),
          onDelete: () => notifier.deleteMeds(medication),
        ),
      );
    }

    return ListView(children: items);
  }

  void _showAddDialog(BuildContext context) async {
    final conditions = ref.read(conditionsProvider);

    if (conditions.isEmpty) {
      // Show dialog to prompt user to add condition from Health tab
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Add Medication'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Please add at least one condition first from the Health tab.'),
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
