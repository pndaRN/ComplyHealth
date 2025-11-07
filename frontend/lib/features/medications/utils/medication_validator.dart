import 'package:flutter/material.dart';

/// Utility class for medication form validation
class MedicationValidator {
  /// Validates medication form fields and shows error messages if validation fails
  static bool validateForm({
    required BuildContext context,
    required String name,
    required String dosage,
    required String frequency,
    required List<String> conditions,
  }) {
    final List<Widget> errors = [];

    if (name.trim().isEmpty) {
      errors.add(Text('Please enter a medication name'));
    }
    if (dosage.trim().isEmpty) {
      errors.add(Text('Please enter a dosage'));
    }
    if (frequency.trim().isEmpty) {
      errors.add(Text('Please enter a frequency'));
    }
    if (conditions.isEmpty) {
      errors.add(Text('Please select at least one condition'));
    }

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: errors.map((error) => Padding(padding: const EdgeInsets.all(8.0), child: error)).toList(),
          ),
        ),
      );
      return false;
    }

    return true;
  }
}
