import '../models/disease.dart';

/// Utility class for condition/disease-related helper methods
class ConditionHelper {
  /// Gets the display name for a disease (commonName if available, otherwise name)
  static String getDisplayName(Disease condition) {
    return condition.commonName.isNotEmpty
        ? condition.commonName
        : condition.name;
  }

  /// Gets display names for a list of condition names by looking them up
  /// in the provided conditions list
  static List<String> getDisplayNames({
    required List<String> conditionNames,
    required List<Disease> conditions,
  }) {
    return conditionNames.map((name) {
      final matchingConditions = conditions.where((c) => c.name == name);
      if (matchingConditions.isEmpty) return name;
      return getDisplayName(matchingConditions.first);
    }).toList();
  }

  /// Finds a condition by name and returns its display name
  static String getDisplayNameByConditionName({
    required String conditionName,
    required List<Disease> conditions,
  }) {
    final matchingConditions =
        conditions.where((c) => c.name == conditionName);
    if (matchingConditions.isEmpty) return conditionName;
    return getDisplayName(matchingConditions.first);
  }
}
