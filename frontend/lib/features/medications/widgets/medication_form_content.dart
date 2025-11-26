import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/disease.dart';
import 'timing_preset_buttons.dart';
import 'time_picker_section.dart';

/// Reusable form content for medication dialogs (add/edit)
class MedicationFormContent extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController dosageController;
  final List<Disease> conditions;
  final List<String> selectedConditions;
  final ValueChanged<List<String>> onConditionsChanged;
  final bool isPRN;
  final ValueChanged<bool> onPRNChanged;
  final List<TimeOfDay> scheduledTimes;
  final ValueChanged<List<TimeOfDay>> onTimesChanged;
  final TextEditingController maxDosesController;

  const MedicationFormContent({
    super.key,
    required this.nameController,
    required this.dosageController,
    required this.conditions,
    required this.selectedConditions,
    required this.onConditionsChanged,
    required this.isPRN,
    required this.onPRNChanged,
    required this.scheduledTimes,
    required this.onTimesChanged,
    required this.maxDosesController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Medication Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dosageController,
            decoration: const InputDecoration(labelText: 'Dosage'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          TimingPresetButtons(
            scheduledTimes: scheduledTimes,
            isPRN: isPRN,
            onTimeAdded: (time) {
              // Add time if it doesn't exist
              final exists = scheduledTimes.any(
                (t) => t.hour == time.hour && t.minute == time.minute,
              );
              if (!exists) {
                onTimesChanged([...scheduledTimes, time]);
              }
            },
            onTimeRemoved: (time) {
              // Remove time
              final updated = scheduledTimes
                  .where(
                    (t) => !(t.hour == time.hour && t.minute == time.minute),
                  )
                  .toList();
              onTimesChanged(updated);
            },
            onPRNChanged: onPRNChanged,
          ),
          if (isPRN) ...[
            const SizedBox(height: 16),
            TextField(
              controller: maxDosesController,
              decoration: const InputDecoration(
                labelText: 'Maximum doses per day',
                hintText: 'e.g., 4',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ] else ...[
            const SizedBox(height: 16),
            TimePickerSection(
              selectedTimes: scheduledTimes,
              onAddTime: (time) {
                final exists = scheduledTimes.any(
                  (t) => t.hour == time.hour && t.minute == time.minute,
                );
                if (!exists) {
                  onTimesChanged([...scheduledTimes, time]);
                }
              },
              onRemoveTime: (time) {
                final updated = scheduledTimes
                    .where(
                      (t) => !(t.hour == time.hour && t.minute == time.minute),
                    )
                    .toList();
                onTimesChanged(updated);
              },
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showConditionSelector(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Conditions',
                border: OutlineInputBorder(),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: selectedConditions.isEmpty
                    ? [
                        const Text(
                          'Tap to select conditions',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ]
                    : selectedConditions.map((conditionName) {
                        final condition = conditions.firstWhere(
                          (c) => c.name == conditionName,
                          orElse: () => Disease(
                            code: '',
                            name: conditionName,
                            category: '',
                            commonName: '',
                            description: '',
                          ),
                        );
                        final displayName = condition.commonName.isNotEmpty
                            ? condition.commonName
                            : condition.name;
                        return Chip(
                          label: Text(
                            displayName,
                            style: const TextStyle(fontSize: 12),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            final updated = List<String>.from(
                              selectedConditions,
                            )..remove(conditionName);
                            onConditionsChanged(updated);
                          },
                        );
                      }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConditionSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ConditionSelectorDialog(
        conditions: conditions,
        selectedConditions: selectedConditions,
        onConditionsChanged: onConditionsChanged,
      ),
    );
  }
}

class _ConditionSelectorDialog extends StatefulWidget {
  final List<Disease> conditions;
  final List<String> selectedConditions;
  final ValueChanged<List<String>> onConditionsChanged;

  const _ConditionSelectorDialog({
    required this.conditions,
    required this.selectedConditions,
    required this.onConditionsChanged,
  });

  @override
  State<_ConditionSelectorDialog> createState() =>
      _ConditionSelectorDialogState();
}

class _ConditionSelectorDialogState extends State<_ConditionSelectorDialog> {
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List<String>.from(widget.selectedConditions);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Conditions'),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.conditions.isEmpty
            ? const Text('No conditions available. Add conditions first.')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.conditions.length,
                itemBuilder: (context, index) {
                  final condition = widget.conditions[index];
                  final displayName = condition.commonName.isNotEmpty
                      ? condition.commonName
                      : condition.name;
                  final isSelected = _tempSelected.contains(condition.name);

                  return CheckboxListTile(
                    title: Text(displayName),
                    subtitle: Text(
                      '${condition.code} • ${condition.category}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _tempSelected.add(condition.name);
                        } else {
                          _tempSelected.remove(condition.name);
                        }
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConditionsChanged(_tempSelected);
            Navigator.pop(context);
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}
