import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/medication.dart';
import '../../core/models/disease.dart';
import '../../core/state/medication_provider.dart';
import '../../core/state/conditions_provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/pdf_export_service.dart';
import '../../core/theme/status_colors.dart';
import '../../core/utils/condition_helper.dart';
import '../../core/utils/time_formatting_utils.dart';
import '../../core/widgets/empty_state_widget.dart';
import 'dialogs/medication_add_dialog.dart';
import 'medication_detail_screen.dart';
import 'utils/medication_sorter.dart';
import 'widgets/medication_card.dart';

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

  Color _getDoseCountColor(int current, int max, ThemeData theme) {
    if (max == 0) return theme.colorScheme.onSurfaceVariant;
    final ratio = current / max;
    if (ratio >= _maxDoseRatio) return theme.statusColors.error;
    if (ratio >= _warningDoseRatio) return theme.statusColors.warning;
    return theme.statusColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final medsAsync = ref.watch(medicationProvider);
    final conditionsAsync = ref.watch(conditionsProvider);
    final notifier = ref.read(medicationProvider.notifier);
    final currentSortOption = notifier.sortOption;

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
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFFF0F7FF)
                    : const Color(0xFF1E3A5F),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final themeState = ref.watch(themeProvider);
              final isDark = themeState.themeMode == ThemeMode.dark ||
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
                      break;
                    case 'sort':
                      final RenderBox button = context.findRenderObject() as RenderBox;
                      final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
                      final RelativeRect position = RelativeRect.fromRect(
                        Rect.fromPoints(
                          button.localToGlobal(Offset.zero, ancestor: overlay),
                          button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
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
            },
          ),
        ],
      ),
      body: medsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (meds) {
          final conditions = conditionsAsync.asData?.value ?? [];

          final filteredMeds = _searchQuery.isEmpty
              ? meds
              : meds.where((medication) {
                  final searchLower = _searchQuery.toLowerCase();
                  final conditionDisplayNames = ConditionHelper.getDisplayNames(
                    conditionNames: medication.conditionNames,
                    conditions: conditions,
                  );

                  return medication.name.toLowerCase().contains(searchLower) ||
                      medication.dosage.toLowerCase().contains(searchLower) ||
                      conditionDisplayNames.any((name) => name.toLowerCase().contains(searchLower));
                }).toList();

          if (meds.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.medication_outlined,
              title: 'No medications yet',
              subtitle: 'Tap + to add your first medication',
            );
          }
          if (filteredMeds.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.search_off,
              title: 'No medications found',
            );
          }
          return _buildMedicationsList(context, filteredMeds, currentSortOption, conditions);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, conditionsAsync.asData?.value ?? []),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMedicationsList(
    BuildContext context,
    List<Medication> meds,
    MedicationSortOption sortOption,
    List<Disease> conditions,
  ) {
    if (sortOption == MedicationSortOption.groupedByCondition) {
      return _buildGroupedList(context, meds, conditions);
    } else if (sortOption == MedicationSortOption.dueTime) {
      return _buildDueTimeGroupedList(context, meds, conditions);
    } else {
      return _buildSimpleList(context, meds, conditions);
    }
  }

  Widget _buildSimpleList(BuildContext context, List<Medication> meds, List<Disease> conditions) {
    return ListView.builder(
      itemCount: meds.length,
      itemBuilder: (context, index) {
        final medication = meds[index];
        final conditionDisplayNames = ConditionHelper.getDisplayNames(
          conditionNames: medication.conditionNames,
          conditions: conditions,
        );

        final timingSummary = _getTimingSummary(medication);
        final doseColor = medication.isPRN
            ? _getDoseCountColor(medication.currentDoseCount, medication.maxDailyDoses ?? 0, Theme.of(context))
            : null;

        return MedicationCard(
          medication: medication,
          conditionDisplayNames: conditionDisplayNames,
          timingSummary: timingSummary,
          doseColor: doseColor,
          onTap: () => _navigateToDetail(medication),
        );
      },
    );
  }

  void _navigateToDetail(Medication medication) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MedicationDetailScreen(medication: medication),
      ),
    );
  }

  Widget _buildGroupedList(BuildContext context, List<Medication> meds, List<Disease> conditions) {
    final conditionGroupedMeds = _createConditionGroupedMedications(meds);
    conditionGroupedMeds.sort((a, b) =>
      a.key.toLowerCase().compareTo(b.key.toLowerCase())
    );

    final List<Widget> items = [];
    String? currentCondition;

    for (final entry in conditionGroupedMeds) {
      final conditionName = entry.key;
      final medication = entry.value;

      if (currentCondition != conditionName) {
        currentCondition = conditionName;
        final displayName = ConditionHelper.getDisplayNameByConditionName(
          conditionName: conditionName,
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

      final conditionDisplayNames = ConditionHelper.getDisplayNames(
        conditionNames: medication.conditionNames,
        conditions: conditions,
      );

      final timingSummary = _getTimingSummary(medication);
      final doseColor = medication.isPRN
          ? _getDoseCountColor(medication.currentDoseCount, medication.maxDailyDoses ?? 0, Theme.of(context))
          : null;

      items.add(
        MedicationCard(
          medication: medication,
          conditionDisplayNames: conditionDisplayNames,
          timingSummary: timingSummary,
          doseColor: doseColor,
          onTap: () => _navigateToDetail(medication),
        ),
      );
    }

    return ListView(children: items);
  }

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

  int _compareTimeGroups(String keyA, String keyB) {
    if (keyA == 'As Needed (PRN)' && keyB != 'As Needed (PRN)') return 1;
    if (keyA != 'As Needed (PRN)' && keyB == 'As Needed (PRN)') return -1;
    if (keyA == 'No Schedule' && keyB != 'No Schedule' && keyB != 'As Needed (PRN)') return 1;
    if (keyA != 'No Schedule' && keyA != 'As Needed (PRN)' && keyB == 'No Schedule') return -1;

    final timeA = TimeFormattingUtils.parseTimeGroupToMinutes(keyA);
    final timeB = TimeFormattingUtils.parseTimeGroupToMinutes(keyB);

    if (timeA == null && timeB == null) return 0;
    if (timeA == null) return 1;
    if (timeB == null) return -1;

    return timeA.compareTo(timeB);
  }

  List<MapEntry<String, Medication>> _createConditionGroupedMedications(
    List<Medication> meds,
  ) {
    final List<MapEntry<String, Medication>> conditionGroupedMeds = [];
    for (final medication in meds) {
      if (medication.conditionNames.isEmpty) {
        conditionGroupedMeds.add(MapEntry('Unknown', medication));
      } else {
        for (final conditionName in medication.conditionNames) {
          conditionGroupedMeds.add(MapEntry(conditionName, medication));
        }
      }
    }
    return conditionGroupedMeds;
  }

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

  Widget _buildDueTimeGroupedList(BuildContext context, List<Medication> meds, List<Disease> conditions) {
    final now = DateTime.now();
    final currentTime = now.hour * TimeFormattingUtils.minutesPerHour + now.minute;

    final timeGroupedMeds = _createTimeGroupedMedications(meds, currentTime);
    timeGroupedMeds.sort((a, b) => _compareTimeGroups(a.key, b.key));

    final List<Widget> items = [];
    String? currentTimeGroup;

    for (final entry in timeGroupedMeds) {
      final timeGroup = entry.key;
      final medication = entry.value;

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

      final conditionDisplayNames = ConditionHelper.getDisplayNames(
        conditionNames: medication.conditionNames,
        conditions: conditions,
      );

      final timingSummary = _getTimingSummary(medication);
      final doseColor = medication.isPRN
          ? _getDoseCountColor(medication.currentDoseCount, medication.maxDailyDoses ?? 0, Theme.of(context))
          : null;

      items.add(
        MedicationCard(
          medication: medication,
          conditionDisplayNames: conditionDisplayNames,
          timingSummary: timingSummary,
          doseColor: doseColor,
          onTap: () => _navigateToDetail(medication),
        ),
      );
    }
    return ListView(children: items);
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

    showDialog(
      context: context,
      builder: (context) => const MedicationAddDialog(),
    );
  }
}
