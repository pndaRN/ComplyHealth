import 'package:flutter/material.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/features/dashboard/utils/todays_medications_utils.dart';

/// Dialog for recovering a missed dose as "taken" with time selection.
/// Returns the DateTime when the dose was actually taken, or null if cancelled.
class RecoveryTakenDialog extends StatefulWidget {
  final MedicationInstance instance;

  const RecoveryTakenDialog({
    super.key,
    required this.instance,
  });

  @override
  State<RecoveryTakenDialog> createState() => _RecoveryTakenDialogState();
}

class _RecoveryTakenDialogState extends State<RecoveryTakenDialog> {
  late DateTime _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = DateTime.now();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = DateTime(
          _selectedTime.year,
          _selectedTime.month,
          _selectedTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark as Taken'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.instance.medication.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Originally scheduled: ${formatMedicationTime(widget.instance.scheduledTime)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'When did you actually take it?',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    formatMedicationTime(_selectedTime),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.edit, size: 18, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedTime),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

/// Shows the recovery taken dialog and returns the selected time.
/// Returns null if the user cancels.
Future<DateTime?> showRecoveryTakenDialog({
  required BuildContext context,
  required MedicationInstance instance,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => RecoveryTakenDialog(instance: instance),
  );
}
