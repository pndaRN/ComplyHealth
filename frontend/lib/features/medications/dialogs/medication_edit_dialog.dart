import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/medication.dart';
import '../../../core/state/medication_provider.dart';
import '../../../core/state/conditions_provider.dart';
import '../widgets/medication_form_content.dart';
import '../utils/medication_validator.dart';

/// Dialog for editing an existing medication
class MedicationEditDialog extends ConsumerStatefulWidget {
  final Medication medication;

  const MedicationEditDialog({super.key, required this.medication});

  @override
  ConsumerState<MedicationEditDialog> createState() => _MedicationEditDialogState();
}

class _MedicationEditDialogState extends ConsumerState<MedicationEditDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController doseCtrl;
  late TextEditingController maxDosesCtrl;
  late List<String> selectedConditions;
  late bool isPRN;
  late List<TimeOfDay> scheduledTimes;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.medication.name);
    doseCtrl = TextEditingController(text: widget.medication.dosage);
    maxDosesCtrl = TextEditingController(
      text: widget.medication.maxDailyDoses?.toString() ?? '',
    );
    selectedConditions = List<String>.from(widget.medication.conditionNames);
    isPRN = widget.medication.isPRN;
    scheduledTimes = widget.medication.scheduledTimes
        .map(_stringToTime)
        .whereType<TimeOfDay>()
        .toList();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    doseCtrl.dispose();
    maxDosesCtrl.dispose();
    super.dispose();
  }

  TimeOfDay? _stringToTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (e) {
      // Invalid time string
    }
    return null;
  }

  String _timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final conditions = ref.watch(conditionsProvider);
    final notifier = ref.read(medicationProvider.notifier);

    return AlertDialog(
      title: const Text('Edit Medication'),
      content: MedicationFormContent(
        nameController: nameCtrl,
        dosageController: doseCtrl,
        conditions: conditions,
        selectedConditions: selectedConditions,
        onConditionsChanged: (value) {
          setState(() {
            selectedConditions = value;
          });
        },
        isPRN: isPRN,
        onPRNChanged: (value) {
          setState(() {
            isPRN = value;
            if (value) {
              scheduledTimes = [];
            } else {
              maxDosesCtrl.clear();
            }
          });
        },
        scheduledTimes: scheduledTimes,
        onTimesChanged: (value) {
          setState(() {
            scheduledTimes = value;
          });
        },
        maxDosesController: maxDosesCtrl,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!MedicationValidator.validateForm(
              context: context,
              name: nameCtrl.text,
              dosage: doseCtrl.text,
              conditions: selectedConditions,
              isPRN: isPRN,
              scheduledTimes: scheduledTimes,
              maxDailyDoses: maxDosesCtrl.text.isEmpty ? null : int.tryParse(maxDosesCtrl.text),
            )) {
              return;
            }

            final updatedMedication = Medication(
              id: widget.medication.id,
              name: nameCtrl.text.trim(),
              dosage: doseCtrl.text.trim(),
              conditionNames: selectedConditions,
              isPRN: isPRN,
              scheduledTimes: scheduledTimes.map(_timeToString).toList(),
              maxDailyDoses: maxDosesCtrl.text.isEmpty ? null : int.tryParse(maxDosesCtrl.text),
            );
            notifier.updateMeds(updatedMedication);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
