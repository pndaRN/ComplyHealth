import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartpatient/core/state/adherence_provider.dart';
import 'package:smartpatient/core/state/medication_provider.dart';
import 'package:smartpatient/core/models/medication_log.dart';

class DoseLoggingDialog extends ConsumerStatefulWidget {
  final MedicationInstance instance;

  const DoseLoggingDialog({
    super.key,
    required this.instance,
  });

  @override
  ConsumerState<DoseLoggingDialog> createState() => _DoseLoggingDialogState();
}

class _DoseLoggingDialogState extends ConsumerState<DoseLoggingDialog> {
  final _notesController = TextEditingController();
  String? _selectedSkipReason;
  DateTime? _customTime;

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
    await ref.read(adherenceProvider.notifier).logDoseTaken(
          medicationId: widget.instance.medication.id,
          medicationName: widget.instance.medication.name,
          dosage: widget.instance.medication.dosage,
          scheduledTime: widget.instance.scheduledTime,
          actualTakenTime: _customTime,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

    // Increment dose count for PRN medications
    if (widget.instance.isPRN) {
      await ref.read(medicationProvider.notifier).incrementDoseCount(widget.instance.medication);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _markAsSkipped() async {
    await ref.read(adherenceProvider.notifier).logDoseSkipped(
          medicationId: widget.instance.medication.id,
          medicationName: widget.instance.medication.name,
          dosage: widget.instance.medication.dosage,
          scheduledTime: widget.instance.scheduledTime,
          skipReason: _selectedSkipReason,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _deleteLog() async {
    if (widget.instance.log != null) {
      final log = widget.instance.log!;

      // Decrement dose count for PRN medications if the log was for a taken dose
      if (widget.instance.isPRN && log.status == DoseStatus.taken) {
        await ref.read(medicationProvider.notifier).decrementDoseCount(widget.instance.medication);
      }

      await ref.read(adherenceProvider.notifier).deleteLog(log.id);
      if (mounted) Navigator.of(context).pop(true);
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                instance.medication.dosage,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              if (!instance.isPRN)
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Scheduled: ${_formatTime(instance.scheduledTime)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              if (instance.isPRN)
                Row(
                  children: [
                    Icon(Icons.medical_services, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'PRN (As Needed)',
                      style: TextStyle(color: Colors.grey[600]),
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
                        ? Colors.green.shade50
                        : log.status == DoseStatus.skipped
                            ? Colors.orange.shade50
                            : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: log.status == DoseStatus.taken
                          ? Colors.green
                          : log.status == DoseStatus.skipped
                              ? Colors.orange
                              : Colors.red,
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
                                ? Colors.green
                                : log.status == DoseStatus.skipped
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            log.status == DoseStatus.taken
                                ? 'Taken'
                                : log.status == DoseStatus.skipped
                                    ? 'Skipped'
                                    : 'Missed',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (log.actualTakenTime != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'At: ${_formatDateTime(log.actualTakenTime!)}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                      if (log.skipReason != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Reason: ${log.skipReason}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                      if (log.notes != null && log.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Notes: ${log.notes}',
                          style: TextStyle(color: Colors.grey[700]),
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
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Delete Log',
                      style: TextStyle(color: Colors.red),
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
                // Notes field
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Add any notes about this dose',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Custom time picker
                OutlinedButton.icon(
                  onPressed: _selectCustomTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    _customTime != null
                        ? 'Time: ${_formatTime(_customTime!)}'
                        : 'Set Custom Time (optional)',
                  ),
                ),
                const SizedBox(height: 16),

                // Mark as Taken button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _markAsTaken,
                    icon: const Icon(Icons.check),
                    label: const Text('Mark as Taken'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Skip reason dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSkipReason,
                  decoration: const InputDecoration(
                    labelText: 'Skip Reason',
                    border: OutlineInputBorder(),
                  ),
                  items: _skipReasons.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(reason),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSkipReason = value);
                  },
                ),
                const SizedBox(height: 12),

                // Mark as Skipped button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _selectedSkipReason != null ? _markAsSkipped : null,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Mark as Skipped'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
