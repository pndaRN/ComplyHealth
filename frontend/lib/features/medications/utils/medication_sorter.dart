import '../../../core/models/medication.dart';

/// Sorting options for medications list
enum MedicationSortOption { alphabetical, groupedByCondition, frequency }

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
      case MedicationSortOption.frequency:
        return _sortByFrequency(medications);
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

  /// Sort medications by frequency (number of times per day)
  /// PRN medications are sorted last, scheduled medications by times per day (ascending)
  static List<Medication> _sortByFrequency(List<Medication> medications) {
    return List.from(medications)..sort((a, b) {
      // PRN medications go last
      if (a.isPRN && !b.isPRN) return 1;
      if (!a.isPRN && b.isPRN) return -1;
      if (a.isPRN && b.isPRN) return 0;

      // Sort by number of scheduled times (ascending)
      return a.scheduledTimes.length.compareTo(b.scheduledTimes.length);
    });
  }

  /// Get display name for sort option
  static String getDisplayName(MedicationSortOption option) {
    switch (option) {
      case MedicationSortOption.alphabetical:
        return 'Alphabetical';
      case MedicationSortOption.groupedByCondition:
        return 'Grouped by Condition';
      case MedicationSortOption.frequency:
        return 'Frequency';
    }
  }
}
