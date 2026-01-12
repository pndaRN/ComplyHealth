import 'package:flutter/material.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/features/dashboard/utils/todays_medications_utils.dart';

/// Dialog for confirming skipping a medication dose with reason selection.
/// Returns the selected skip reason, or null if cancelled.
class SkipDoseDialog extends StatelessWidget {
  final MedicationInstance instance;

  const SkipDoseDialog({
    super.key,
    required this.instance,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Skip Medication'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skip ${instance.medication.name}?'),
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

/// Shows the skip dose dialog and returns the selected reason.
/// Returns null if the user cancels.
Future<String?> showSkipDoseDialog({
  required BuildContext context,
  required MedicationInstance instance,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => SkipDoseDialog(instance: instance),
  );
}
