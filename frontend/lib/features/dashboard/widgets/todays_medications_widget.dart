import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smartpatient/core/state/adherence_provider.dart';
import 'package:smartpatient/features/dashboard/dialogs/dose_logging_dialog.dart';

class TodaysMedicationsWidget extends ConsumerStatefulWidget {
  const TodaysMedicationsWidget({super.key});

  @override
  ConsumerState<TodaysMedicationsWidget> createState() =>
      _TodaysMedicationsWidgetState();
}

class _TodaysMedicationsWidgetState
    extends ConsumerState<TodaysMedicationsWidget> {
  List<MedicationInstance> _instances = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstances();
  }

  Future<void> _loadInstances() async {
    setState(() => _isLoading = true);
    final instances = await ref.read(adherenceProvider.notifier).getTodayInstances();
    setState(() {
      _instances = instances;
      _isLoading = false;
    });
  }

  Future<void> _quickMarkAsTaken(MedicationInstance instance) async {
    await ref.read(adherenceProvider.notifier).logDoseTaken(
          medicationId: instance.medication.id,
          medicationName: instance.medication.name,
          dosage: instance.medication.dosage,
          scheduledTime: instance.scheduledTime,
        );
    await _loadInstances();
  }

  Future<void> _openDetailedDialog(MedicationInstance instance) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DoseLoggingDialog(instance: instance),
    );

    if (result == true) {
      await _loadInstances();
    }
  }

  Color _getStatusColor(MedicationInstance instance) {
    if (instance.isTaken) return Colors.green;
    if (instance.isSkipped) return Colors.orange;
    if (instance.isMissed) return Colors.red;
    if (instance.isOverdue) return Colors.red.shade300;
    return Colors.grey;
  }

  IconData _getStatusIcon(MedicationInstance instance) {
    if (instance.isTaken) return Icons.check_circle;
    if (instance.isSkipped) return Icons.cancel;
    if (instance.isMissed) return Icons.error;
    if (instance.isOverdue) return Icons.warning;
    return Icons.radio_button_unchecked;
  }

  String _getStatusText(MedicationInstance instance) {
    if (instance.isTaken) return 'Taken';
    if (instance.isSkipped) return 'Skipped';
    if (instance.isMissed) return 'Missed';
    if (instance.isOverdue) return 'Overdue';
    return 'Pending';
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_instances.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Today\'s Medications',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'No medications scheduled for today',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final pendingCount =
        _instances.where((i) => i.isPending || i.isOverdue).length;
    final takenCount = _instances.where((i) => i.isTaken).length;
    final totalCount = _instances.length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Medications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: pendingCount == 0 ? Colors.green : Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$takenCount/$totalCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _instances.length,
            itemBuilder: (context, index) {
              final instance = _instances[index];
              return InkWell(
                onTap: () => _openDetailedDialog(instance),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Status icon/checkbox
                      if (instance.isPending && !instance.isOverdue)
                        Checkbox(
                          value: false,
                          onChanged: (_) => _quickMarkAsTaken(instance),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            _getStatusIcon(instance),
                            color: _getStatusColor(instance),
                            size: 24,
                          ),
                        ),
                      const SizedBox(width: 12),
                      // Medication info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              instance.medication.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              instance.medication.dosage,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Time and status
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!instance.isPRN)
                            Text(
                              _formatTime(instance.scheduledTime),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          if (instance.isPRN)
                            const Text(
                              'PRN',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            _getStatusText(instance),
                            style: TextStyle(
                              color: _getStatusColor(instance),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
