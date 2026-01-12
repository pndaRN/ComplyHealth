import 'package:flutter/material.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/features/dashboard/utils/todays_medications_utils.dart';

/// Dialog for recovering a missed dose as "skipped" with reason selection.
/// Returns the selected skip reason, or null if cancelled.
class RecoverySkippedDialog extends StatelessWidget {
  final MedicationInstance instance;

  const RecoverySkippedDialog({
    super.key,
    required this.instance,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark as Skipped'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            instance.medication.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a reason:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...kSkipReasons.map(
            (reason) => ListTile(
              dense: true,
              title: Text(reason),
              onTap: () => Navigator.pop(context, reason),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Shows the recovery skipped dialog and returns the selected reason.
/// Returns null if the user cancels.
Future<String?> showRecoverySkippedDialog({
  required BuildContext context,
  required MedicationInstance instance,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => RecoverySkippedDialog(instance: instance),
  );
}
