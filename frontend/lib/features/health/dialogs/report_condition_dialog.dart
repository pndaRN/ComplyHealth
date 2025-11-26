import 'package:flutter/material.dart';
import '../../../core/services/condition_report_service.dart';

/// Dialog prompting user to report a custom condition to Firebase
class ReportConditionDialog extends StatefulWidget {
  final String conditionName;
  final String? userId;

  const ReportConditionDialog({
    super.key,
    required this.conditionName,
    this.userId,
  });

  @override
  State<ReportConditionDialog> createState() => _ReportConditionDialogState();
}

class _ReportConditionDialogState extends State<ReportConditionDialog> {
  bool _isSubmitting = false;

  Future<void> _submitReport() async {
    setState(() {
      _isSubmitting = true;
    });

    final success = await ConditionReportService.submitConditionRequest(
      conditionName: widget.conditionName,
      userId: widget.userId,
    );

    if (!mounted) return;

    if (success) {
      // Show success message and close dialog
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully! We will review your request.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Show error message but keep dialog open
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit report. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Help Us Improve'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The condition "${widget.conditionName}" is not currently in our database.',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text(
            'Would you like to submit a request to have it added to our official condition list? This helps other users find and track this condition.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submitReport,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }
}
