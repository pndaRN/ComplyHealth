import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/medication.dart';
import '../../../core/state/medication_provider.dart';
import '../../../core/state/conditions_provider.dart';
import '../widgets/medication_form_content.dart';
import '../utils/medication_validator.dart';

/// Dialog for adding a new medication
class MedicationAddDialog extends ConsumerStatefulWidget {
  const MedicationAddDialog({super.key});

  @override
  ConsumerState<MedicationAddDialog> createState() => _MedicationAddDialogState();
}

class _MedicationAddDialogState extends ConsumerState<MedicationAddDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController doseCtrl;
  late TextEditingController maxDosesCtrl;
  List<String> selectedConditions = [];
  bool isPRN = false;
  List<TimeOfDay> scheduledTimes = [];
  List<TimeOfDay>? _savedScheduledTimes;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController();
    doseCtrl = TextEditingController();
    maxDosesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    doseCtrl.dispose();
    maxDosesCtrl.dispose();
    super.dispose();
  }

  String _timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final conditions = ref.watch(conditionsProvider);
    final notifier = ref.read(medicationProvider.notifier);

    return AlertDialog(
      title: const Text('Add Medication'),
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
            if (value) {
              // Switching to PRN - save and clear times
              _savedScheduledTimes = List.from(scheduledTimes);
              scheduledTimes = [];
              isPRN = true;
            } else {
              // Switching from PRN - restore times
              if (_savedScheduledTimes != null) {
                scheduledTimes = _savedScheduledTimes!;
                _savedScheduledTimes = null;
              }
              isPRN = false;
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

            final newMedication = Medication(
              id: const Uuid().v4(),
              name: nameCtrl.text.trim(),
              dosage: doseCtrl.text.trim(),
              conditionNames: selectedConditions,
              isPRN: isPRN,
              scheduledTimes: scheduledTimes.map(_timeToString).toList(),
              maxDailyDoses: maxDosesCtrl.text.isEmpty ? null : int.tryParse(maxDosesCtrl.text),
            );
            notifier.addMeds(newMedication);
            Navigator.pop(context);
          },
          child: const Text('Add Medication'),
        ),
      ],
    );
  }
}
