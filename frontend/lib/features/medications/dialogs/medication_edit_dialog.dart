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
  late TextEditingController freqCtrl;
  late List<String> selectedConditions;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.medication.name);
    doseCtrl = TextEditingController(text: widget.medication.dosage);
    freqCtrl = TextEditingController(text: widget.medication.frequency);
    selectedConditions = List<String>.from(widget.medication.conditionNames);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    doseCtrl.dispose();
    freqCtrl.dispose();
    super.dispose();
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
        frequencyController: freqCtrl,
        conditions: conditions,
        selectedConditions: selectedConditions,
        onConditionsChanged: (value) {
          setState(() {
            selectedConditions = value;
          });
        },
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
              frequency: freqCtrl.text,
              conditions: selectedConditions,
            )) {
              return;
            }

            final updatedMedication = Medication(
              id: widget.medication.id,
              name: nameCtrl.text.trim(),
              dosage: doseCtrl.text.trim(),
              frequency: freqCtrl.text.trim(),
              conditionNames: selectedConditions,
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
