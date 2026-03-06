import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/core/state/medication_provider.dart';
import 'package:complyhealth/core/models/medication_log.dart';

class DoseLoggingDialog extends ConsumerStatefulWidget {
  final MedicationInstance instance;

  const DoseLoggingDialog({super.key, required this.instance});

  @override
  ConsumerState<DoseLoggingDialog> createState() => _DoseLoggingDialogState();
}

class _DoseLoggingDialogState extends ConsumerState<DoseLoggingDialog> {
  final _notesController = TextEditingController();
  String? _selectedSkipReason;
  DateTime? _customTime;
  bool _isSkipping = false;
  bool _isAddingNote = false;

  final List<String> _skipReasons = [
    'Forgot',
    'Side effects',
    'Unavailable',
    'Not needed',
    'Other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _markAsTaken() async {
    // For PRN medications, increment count first to ensure atomicity
    if (widget.instance.isPRN) {
      // Get the latest medication state from provider
      final medicationsAsync = ref.read(medicationProvider);
      final latestMed = (medicationsAsync.value ?? []).firstWhere(
        (m) => m.id == widget.instance.medication.id,
        orElse: () => widget.instance.medication,
      );

      try {
        // Increment dose count first
        await ref
            .read(medicationProvider.notifier)
            .incrementDoseCount(latestMed);

        // Then log the dose
        await ref
            .read(adherenceProvider.notifier)
            .logDoseTaken(
              medicationId: latestMed.id,
              medicationName: latestMed.name,
              dosage: latestMed.dosage,
              scheduledTime: widget.instance.scheduledTime,
              actualTakenTime: _customTime,
              notes: _notesController.text.isEmpty
                  ? null
                  : _notesController.text,
              isPRN: true,
            );
      } catch (e) {
        // Rollback dose count on error
        await ref
            .read(medicationProvider.notifier)
            .decrementDoseCount(latestMed);
        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to log dose: $e')));
        }
        return; // Don't close dialog on error
      }
    } else {
      // For scheduled medications, just log the dose
      try {
        await ref
            .read(adherenceProvider.notifier)
            .logDoseTaken(
              medicationId: widget.instance.medication.id,
              medicationName: widget.instance.medication.name,
              dosage: widget.instance.medication.dosage,
              scheduledTime: widget.instance.scheduledTime,
              actualTakenTime: _customTime,
              notes: _notesController.text.isEmpty
                  ? null
                  : _notesController.text,
            );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to log dose: $e')));
        }
        return; // Don't close dialog on error
      }
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _markAsSkipped() async {
    try {
      await ref
          .read(adherenceProvider.notifier)
          .logDoseSkipped(
            medicationId: widget.instance.medication.id,
            medicationName: widget.instance.medication.name,
            dosage: widget.instance.medication.dosage,
            scheduledTime: widget.instance.scheduledTime,
            skipReason: _selectedSkipReason,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            isPRN: widget.instance.isPRN,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to skip dose: $e')));
      }
    }
  }

  Future<void> _deleteLog() async {
    if (widget.instance.log != null) {
      final log = widget.instance.log!;

      try {
        // Delete the log first
        await ref.read(adherenceProvider.notifier).deleteLog(log.id);

        // Decrement dose count for PRN medications if the log was for a taken dose
        if (widget.instance.isPRN && log.status == DoseStatus.taken) {
          // Get the latest medication state from provider
          final medicationsAsync = ref.read(medicationProvider);
          final latestMed = (medicationsAsync.value ?? []).firstWhere(
            (m) => m.id == widget.instance.medication.id,
            orElse: () => widget.instance.medication,
          );
          await ref
              .read(medicationProvider.notifier)
              .decrementDoseCount(latestMed);
        }
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete log: $e')));
        }
      }
    }
  }

  Future<void> _selectCustomTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      final now = DateTime.now();
      setState(() {
        _customTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  String _formatDateTime(DateTime time) {
    return DateFormat('MMM d, h:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final instance = widget.instance;
    final log = instance.log;
    final theme = Theme.of(context);

    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                instance.medication.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                instance.medication.dosage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              if (!instance.isPRN)
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Scheduled: ${_formatTime(instance.scheduledTime)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              if (instance.isPRN)
                Row(
                  children: [
                    Icon(
                      Icons.medical_services,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PRN (As Needed)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              const Divider(height: 24),

              // Existing log info
              if (log != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: log.status == DoseStatus.taken
                        ? theme.colorScheme.tertiaryContainer
                        : log.status == DoseStatus.skipped
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: log.status == DoseStatus.taken
                          ? theme.colorScheme.tertiary
                          : log.status == DoseStatus.skipped
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.error,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            log.status == DoseStatus.taken
                                ? Icons.check_circle
                                : log.status == DoseStatus.skipped
                                ? Icons.cancel
                                : Icons.error,
                            color: log.status == DoseStatus.taken
                                ? theme.colorScheme.onTertiaryContainer
                                : log.status == DoseStatus.skipped
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            log.status == DoseStatus.taken
                                ? 'Taken'
                                : log.status == DoseStatus.skipped
                                ? 'Skipped'
                                : 'Missed',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: log.status == DoseStatus.taken
                                  ? theme.colorScheme.onTertiaryContainer
                                  : log.status == DoseStatus.skipped
                                  ? theme.colorScheme.onSecondaryContainer
                                  : theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                      if (log.actualTakenTime != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'At: ${_formatDateTime(log.actualTakenTime!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: log.status == DoseStatus.taken
                                ? theme.colorScheme.onTertiaryContainer
                                : log.status == DoseStatus.skipped
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                      if (log.skipReason != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Reason: ${log.skipReason}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: log.status == DoseStatus.taken
                                ? theme.colorScheme.onTertiaryContainer
                                : log.status == DoseStatus.skipped
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                      if (log.notes != null && log.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Notes: ${log.notes}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: log.status == DoseStatus.taken
                                ? theme.colorScheme.onTertiaryContainer
                                : log.status == DoseStatus.skipped
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _deleteLog,
                    icon: Icon(Icons.delete, color: theme.colorScheme.error),
                    label: Text(
                      'Delete Log',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],

              // Logging form (if no log exists)
              if (log == null) ...[
                if (_isSkipping) ...[
                  Text(
                    'Reason for skipping',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _skipReasons.map((reason) {
                      final isSelected = _selectedSkipReason == reason;
                      return ChoiceChip(
                        label: Text(reason),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedSkipReason = selected ? reason : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSkipping = false;
                            _selectedSkipReason = null;
                          });
                        },
                        child: const Text('Back'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _selectedSkipReason != null
                            ? _markAsSkipped
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                        child: const Text('Confirm Skip'),
                      ),
                    ],
                  ),
                ] else ...[
                  // Main View
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _markAsTaken,
                      icon: const Icon(Icons.check),
                      label: const Text('Mark as Taken'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Secondary Options Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _selectCustomTime,
                          child: Text(
                            _customTime != null
                                ? _formatTime(_customTime!)
                                : 'Change Time',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _isAddingNote = !_isAddingNote);
                          },
                          child: Text(
                            _isAddingNote || _notesController.text.isNotEmpty
                                ? 'Hide Note'
                                : 'Add Note',
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_isAddingNote || _notesController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Add any notes...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Skip Action
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _isSkipping = true),
                      icon: Icon(
                        Icons.block,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      label: Text(
                        'Skip this Dose',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
