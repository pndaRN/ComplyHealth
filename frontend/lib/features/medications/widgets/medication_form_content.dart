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
  final bool isTimeSensitive;
  final ValueChanged<bool> onTimeSensitiveChanged;

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
    this.isTimeSensitive = true,
    required this.onTimeSensitiveChanged,
  });

  @override
  State<MedicationFormContent> createState() => _MedicationFormContentState();
}

class _MedicationFormContentState extends State<MedicationFormContent>
    with TickerProviderStateMixin {
  bool _showScrollbar = true;
  late final ScrollController _scrollController;
  late AnimationController _autoSelectAnimationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _autoSelectAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
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
    _scrollController.dispose();
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
    final theme = Theme.of(context);

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: _showScrollbar,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Basics Section
            Text(
              'Basics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                hintText: 'e.g. 10mg, 1 pill',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.scale),
              ),
            ),

            const SizedBox(height: 24),

            // Conditions Section
            Text(
              'Conditions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.conditions.isEmpty)
              Text(
                'No conditions added yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.conditions.map((condition) {
                  final isSelected = widget.selectedConditions.contains(
                    condition.name,
                  );
                  final isAutoSelected = widget.autoSelectedConditions.contains(
                    condition.name,
                  );

                  return FilterChip(
                    label: Text(
                      condition.commonName.isNotEmpty
                          ? condition.commonName
                          : condition.name,
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      final updated = List<String>.from(
                        widget.selectedConditions,
                      );
                      if (selected) {
                        updated.add(condition.name);
                      } else {
                        updated.remove(condition.name);
                      }
                      widget.onConditionsChanged(updated);
                    },
                    avatar: isAutoSelected
                        ? Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: theme.colorScheme.onPrimaryContainer,
                          )
                        : null,
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),

            // Schedule Section
            Text(
              'Schedule',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Schedule Type Toggle
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Scheduled'),
                    icon: Icon(Icons.access_time),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('As Needed'),
                    icon: Icon(Icons.healing),
                  ),
                ],
                selected: {widget.isPRN},
                onSelectionChanged: (Set<bool> newSelection) {
                  widget.onPRNChanged(newSelection.first);
                },
              ),
            ),
            const SizedBox(height: 16),

            if (widget.isPRN) ...[
              // PRN Details
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        'As Needed (PRN)',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This medication will appear in the "As Needed" section and won\'t trigger scheduled reminders.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: widget.maxDosesController,
                        decoration: const InputDecoration(
                          labelText: 'Max doses per day (Optional)',
                          hintText: 'e.g., 4',
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Scheduled Details
              TimingPresetButtons(
                scheduledTimes: widget.scheduledTimes,
                isPRN: false, // Always false in this branch
                onTimeAdded: (time) {
                  final exists = widget.scheduledTimes.any(
                    (t) => t.hour == time.hour && t.minute == time.minute,
                  );
                  if (!exists) {
                    widget.onTimesChanged([...widget.scheduledTimes, time]);
                  }
                },
                onTimeRemoved: (time) {
                  final updated = widget.scheduledTimes
                      .where(
                        (t) =>
                            !(t.hour == time.hour && t.minute == time.minute),
                      )
                      .toList();
                  widget.onTimesChanged(updated);
                },
                onPRNChanged:
                    (_) {}, // No-op as we handle toggle externally now
              ),
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
              const SizedBox(height: 16),

              // Time Sensitive Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Time Sensitive'),
                subtitle: const Text(
                  'Mark as late if missed. Turn off for flexible timing.',
                ),
                value: widget.isTimeSensitive,
                onChanged: widget.onTimeSensitiveChanged,
              ),
            ],

            // Bottom padding for scroll
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
