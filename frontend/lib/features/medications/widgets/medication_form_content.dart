import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/disease.dart';
import 'timing_preset_buttons.dart';
import 'time_picker_section.dart';

/// Reusable form content for medication dialogs (add/edit)
class MedicationFormContent extends StatefulWidget {
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
  final Set<String> autoSelectedConditions;

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
    this.autoSelectedConditions = const {},
  });

  @override
  State<MedicationFormContent> createState() => _MedicationFormContentState();
}

class _MedicationFormContentState extends State<MedicationFormContent>
    with TickerProviderStateMixin {
  bool _showScrollbar = true;
  late AnimationController _autoSelectAnimationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _autoSelectAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _autoSelectAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showScrollbar = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoSelectAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MedicationFormContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger animation when new auto-selected conditions appear
    if (widget.autoSelectedConditions.isNotEmpty &&
        oldWidget.autoSelectedConditions.isEmpty) {
      _autoSelectAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: _showScrollbar,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widget.nameController,
              decoration: const InputDecoration(labelText: 'Medication Name'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.dosageController,
              decoration: const InputDecoration(labelText: 'Dosage'),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            TimingPresetButtons(
              scheduledTimes: widget.scheduledTimes,
              isPRN: widget.isPRN,
              onTimeAdded: (time) {
                // Add time if it doesn't exist
                final exists = widget.scheduledTimes.any(
                  (t) => t.hour == time.hour && t.minute == time.minute,
                );
                if (!exists) {
                  widget.onTimesChanged([...widget.scheduledTimes, time]);
                }
              },
              onTimeRemoved: (time) {
                // Remove time
                final updated = widget.scheduledTimes
                    .where(
                      (t) => !(t.hour == time.hour && t.minute == time.minute),
                    )
                    .toList();
                widget.onTimesChanged(updated);
              },
              onPRNChanged: widget.onPRNChanged,
            ),
            if (widget.isPRN) ...[
              const SizedBox(height: 16),
              TextField(
                controller: widget.maxDosesController,
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
                selectedTimes: widget.scheduledTimes,
                onAddTime: (time) {
                  final exists = widget.scheduledTimes.any(
                    (t) => t.hour == time.hour && t.minute == time.minute,
                  );
                  if (!exists) {
                    widget.onTimesChanged([...widget.scheduledTimes, time]);
                  }
                },
                onRemoveTime: (time) {
                  final updated = widget.scheduledTimes
                      .where(
                        (t) =>
                            !(t.hour == time.hour && t.minute == time.minute),
                      )
                      .toList();
                  widget.onTimesChanged(updated);
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
                  children: widget.selectedConditions.isEmpty
                      ? [
                          const Text(
                            'Tap to select conditions',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ]
                      : widget.selectedConditions.map((conditionName) {
                          final condition = widget.conditions.firstWhere(
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
                          return AnimatedBuilder(
                            animation: _scaleAnimation,
                            builder: (context, child) {
                              final isAutoSelected = widget
                                  .autoSelectedConditions
                                  .contains(conditionName);
                              return Transform.scale(
                                scale: isAutoSelected
                                    ? _scaleAnimation.value
                                    : 1.0,
                                child: Chip(
                                  label: Text(
                                    displayName,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  backgroundColor: isAutoSelected
                                      ? Colors.blue.shade50
                                      : null,
                                  side: isAutoSelected
                                      ? BorderSide(
                                          color: Colors.blue.shade200,
                                          width: 1.5,
                                        )
                                      : null,
                                  avatar: isAutoSelected
                                      ? Icon(
                                          Icons.auto_awesome,
                                          size: 12,
                                          color: Colors.blue.shade600,
                                        )
                                      : null,
                                  onDeleted: () {
                                    final updated = List<String>.from(
                                      widget.selectedConditions,
                                    )..remove(conditionName);
                                    widget.onConditionsChanged(updated);
                                  },
                                ),
                              );
                            },
                          );
                        }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConditionSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ConditionSelectorDialog(
        conditions: widget.conditions,
        selectedConditions: widget.selectedConditions,
        onConditionsChanged: widget.onConditionsChanged,
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
