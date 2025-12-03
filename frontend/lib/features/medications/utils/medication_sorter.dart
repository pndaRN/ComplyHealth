import '../../../core/models/medication.dart';
import '../../../core/utils/time_formatting_utils.dart';

/// Sorting options for medications list
enum MedicationSortOption { alphabetical, groupedByCondition, dueTime }

/// Utility class for sorting medications
class MedicationSorter {
  /// Sort medications based on the selected option
  static List<Medication> sort(
    List<Medication> medications,
    MedicationSortOption sortOption,
  ) {
    switch (sortOption) {
      case MedicationSortOption.alphabetical:
        return _sortAlphabetically(medications);
      case MedicationSortOption.groupedByCondition:
        return _sortByConditionGroups(medications);
      case MedicationSortOption.dueTime:
        return _sortByDueTime(medications);
    }
  }

  /// Sort medications alphabetically by name (A-Z)
  static List<Medication> _sortAlphabetically(List<Medication> medications) {
    final sorted = List<Medication>.from(medications);
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  /// Group medications by condition, then sort alphabetically within groups
  /// Medications with multiple conditions will appear under each condition group
  ///
  /// NOTE: This intentionally returns duplicate Medication objects (same instance
  /// appears multiple times in the result list). The UI layer handles this by
  /// transforming the list into MapEntry to preserve which condition each entry
  /// represents. See _createConditionGroupedMedications() in medications_screen.dart.
  static List<Medication> _sortByConditionGroups(List<Medication> medications) {
    if (medications.isEmpty) return [];

    // Create a map of condition name -> list of medications
    final Map<String, List<Medication>> conditionGroups = {};

    for (final med in medications) {
      for (final conditionName in med.conditionNames) {
        if (!conditionGroups.containsKey(conditionName)) {
          conditionGroups[conditionName] = [];
        }
        conditionGroups[conditionName]!.add(med);
      }
    }

    // Sort condition names alphabetically
    final sortedConditionNames = conditionGroups.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // Build final sorted list: for each condition group, add medications sorted alphabetically
    final List<Medication> result = [];
    for (final conditionName in sortedConditionNames) {
      final medsInGroup = conditionGroups[conditionName]!;
      // Sort medications within each group alphabetically
      medsInGroup.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      result.addAll(medsInGroup);
    }

    return result;
  }

  /// Sort medications by their next scheduled due time
  /// PRN medications are sorted last, scheduled medications by next due time (earliest first)
  static List<Medication> _sortByDueTime(List<Medication> medications) {
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute; // Current time in minutes since midnight

    return List.from(medications)..sort((a, b) {
      // PRN medications go last
      if (a.isPRN && !b.isPRN) return 1;
      if (!a.isPRN && b.isPRN) return -1;
      if (a.isPRN && b.isPRN) return 0;

      // Get next scheduled time for each medication
      final nextTimeA = TimeFormattingUtils.getNextScheduledTime(a.scheduledTimes, currentTime);
      final nextTimeB = TimeFormattingUtils.getNextScheduledTime(b.scheduledTimes, currentTime);

      // If no scheduled times, treat as later
      if (nextTimeA == null && nextTimeB == null) return 0;
      if (nextTimeA == null) return 1;
      if (nextTimeB == null) return -1;

      // Compare next scheduled times
      return nextTimeA.compareTo(nextTimeB);
    });
  }

  /// Get display name for sort option
  static String getDisplayName(MedicationSortOption option) {
    switch (option) {
      case MedicationSortOption.alphabetical:
        return 'Alphabetical';
      case MedicationSortOption.groupedByCondition:
        return 'Grouped by Condition';
      case MedicationSortOption.dueTime:
        return 'Due Times';
    }
  }
}
