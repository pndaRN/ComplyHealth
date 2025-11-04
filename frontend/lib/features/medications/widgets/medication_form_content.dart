import 'package:flutter/material.dart';
import '../../../core/models/disease.dart';

/// Reusable form content for medication dialogs (add/edit)
class MedicationFormContent extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController dosageController;
  final TextEditingController frequencyController;
  final List<Disease> conditions;
  final String? selectedCondition;
  final ValueChanged<String?> onConditionChanged;

  const MedicationFormContent({
    super.key,
    required this.nameController,
    required this.dosageController,
    required this.frequencyController,
    required this.conditions,
    required this.selectedCondition,
    required this.onConditionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Medication Name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dosageController,
            decoration: const InputDecoration(labelText: 'Dosage'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: frequencyController,
            decoration: const InputDecoration(
              labelText: 'Frequency',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedCondition,
            hint: const Text('Select Condition'),
            items: conditions.map((condition) {
              return DropdownMenuItem<String>(
                value: condition.name,
                child: Text(condition.name),
              );
            }).toList(),
            onChanged: onConditionChanged,
            decoration: const InputDecoration(
              labelText: 'Condition',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
