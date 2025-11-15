import 'package:flutter/material.dart';

/// Utility class for feedback form validation
class FeedbackValidator {
  /// Validates feedback form fields and shows error messages if validation fails
  static bool validateForm({
    required BuildContext context,
    required String? type,
    required String subject,
    required String message,
  }) {
    final List<Widget> errors = [];

    if (type == null || type.isEmpty) {
      errors.add(const Text('Please select a feedback type'));
    }
    if (subject.trim().isEmpty) {
      errors.add(const Text('Please enter a subject'));
    }
    if (message.trim().isEmpty) {
      errors.add(const Text('Please enter your feedback message'));
    }

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors
                .map((error) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: error,
                    ))
                .toList(),
          ),
        ),
      );
      return false;
    }

    return true;
  }
}
