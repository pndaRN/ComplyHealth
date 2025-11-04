import 'package:flutter/material.dart';

/// Utility class for medication form validation
class MedicationValidator {
  /// Validates medication form fields and shows error messages if validation fails
  static bool validateForm({
    required BuildContext context,
    required String name,
    required String dosage,
    required String frequency,
    required String? condition,
  }) {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a medication name')),
      );
      return false;
    }
    if (dosage.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a dosage')),
      );
      return false;
    }
    if (frequency.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a frequency')),
      );
      return false;
    }
    if (condition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a condition')),
      );
      return false;
    }
    return true;
  }
}
