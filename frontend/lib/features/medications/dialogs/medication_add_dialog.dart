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
  late TextEditingController freqCtrl;
  String? selectCondition;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController();
    doseCtrl = TextEditingController();
    freqCtrl = TextEditingController();
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
      title: const Text('Add Medication'),
      content: MedicationFormContent(
        nameController: nameCtrl,
        dosageController: doseCtrl,
        frequencyController: freqCtrl,
        conditions: conditions,
        selectedCondition: selectCondition,
        onConditionChanged: (value) {
          setState(() {
            selectCondition = value;
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
              condition: selectCondition,
            )) {
              return;
            }

            final newMedication = Medication(
              id: const Uuid().v4(),
              name: nameCtrl.text.trim(),
              dosage: doseCtrl.text.trim(),
              frequency: freqCtrl.text.trim(),
              conditionName: selectCondition!,
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
