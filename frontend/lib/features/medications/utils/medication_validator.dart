import 'package:flutter/material.dart';

/// Utility class for medication form validation
class MedicationValidator {
  /// Validates medication form fields and shows error messages if validation fails
  static bool validateForm({
    required BuildContext context,
    required String name,
    required String dosage,
    required List<String> conditions,
    required bool isPRN,
    required List<TimeOfDay> scheduledTimes,
    required int? maxDailyDoses,
  }) {
    final List<Widget> errors = [];

    if (name.trim().isEmpty) {
      errors.add(const Text('Please enter a medication name'));
    }
    if (dosage.trim().isEmpty) {
      errors.add(const Text('Please enter a dosage'));
    }
    if (conditions.isEmpty) {
      errors.add(const Text('Please select at least one condition'));
    }

    // Timing validation
    if (isPRN) {
      // PRN medications require max daily doses
      if (maxDailyDoses == null || maxDailyDoses <= 0) {
        errors.add(const Text('Please enter maximum doses per day for PRN medication'));
      }
    } else {
      // Scheduled medications require at least one time
      if (scheduledTimes.isEmpty) {
        errors.add(const Text('Please add at least one scheduled time or mark as PRN'));
      }
    }

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors.map((error) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: error)).toList(),
          ),
        ),
      );
      return false;
    }

    return true;
  }
}
