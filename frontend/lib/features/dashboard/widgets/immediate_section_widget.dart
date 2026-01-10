import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/core/state/medication_provider.dart';
import 'package:complyhealth/features/dashboard/dialogs/dose_logging_dialog.dart';
import 'package:complyhealth/features/dashboard/dialogs/backdate_dose_dialog.dart';
import 'package:complyhealth/features/dashboard/dialogs/skip_dose_dialog.dart';
import 'package:complyhealth/features/dashboard/utils/todays_medications_utils.dart';

/// Widget displaying the "Due Now" / "Overdue & Due Now" section.
class ImmediateSectionWidget extends ConsumerWidget {
  final List<MedicationInstance> instances;
  final List<MedicationInstance> laterInstances;
  final Set<String> processingMedications;
  final Future<void> Function(MedicationInstance instance) onMarkAsTaken;
  final VoidCallback onRefresh;

  const ImmediateSectionWidget({
    super.key,
    required this.instances,
    required this.laterInstances,
    required this.processingMedications,
    required this.onMarkAsTaken,
    required this.onRefresh,
  });

  String _getMedicationKey(MedicationInstance instance) {
    return '${instance.medication.id}_${instance.scheduledTime.millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (instances.isEmpty) {
      return _buildEmptyState(context);
    }

    final hasOverdue = instances.any((i) => isInstanceOverdue(i));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            hasOverdue ? 'Overdue & Due Now' : 'Due Now',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
          ),
        ),
        ...instances.map(
          (instance) => _ImmediateItem(
            key: Key(_getMedicationKey(instance)),
            instance: instance,
            isProcessing: processingMedications.contains(_getMedicationKey(instance)),
            onMarkAsTaken: onMarkAsTaken,
            onRefresh: onRefresh,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Colors.green[400],
          ),
          const SizedBox(height: 8),
          const Text(
            'All caught up!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (laterInstances.isNotEmpty)
            Text(
              'Next dose at ${formatMedicationTime(laterInstances.first.scheduledTime)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
        ],
      ),
    );
  }
}

/// Individual item in the immediate section.
class _ImmediateItem extends ConsumerWidget {
  final MedicationInstance instance;
  final bool isProcessing;
  final Future<void> Function(MedicationInstance instance) onMarkAsTaken;
  final VoidCallback onRefresh;

  const _ImmediateItem({
    super.key,
    required this.instance,
    required this.isProcessing,
    required this.onMarkAsTaken,
    required this.onRefresh,
  });

  Future<bool> _handleSkipSwipe(BuildContext context, WidgetRef ref) async {
    final reason = await showSkipDoseDialog(
      context: context,
      instance: instance,
    );

    if (reason != null) {
      HapticFeedback.lightImpact();
      try {
        await ref.read(adherenceProvider.notifier).logDoseSkipped(
              medicationId: instance.medication.id,
              medicationName: instance.medication.name,
              dosage: instance.medication.dosage,
              scheduledTime: instance.scheduledTime,
              skipReason: reason,
            );
        onRefresh();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to skip dose: $e')),
          );
        }
      }
    }

    return false; // Don't dismiss the widget, we handle removal via reload
  }

  Future<void> _handleBackdate(BuildContext context, WidgetRef ref) async {
    final selectedTime = await showBackdateDoseDialog(
      context: context,
      instance: instance,
    );

    if (selectedTime != null) {
      await _markAsTakenAtTime(context, ref, selectedTime);
    }
  }

  Future<void> _markAsTakenAtTime(
    BuildContext context,
    WidgetRef ref,
    DateTime takenTime,
  ) async {
    HapticFeedback.lightImpact();

    if (instance.isPRN) {
      final medications = ref.read(medicationProvider).value ?? [];
      final latestMed = medications.firstWhere(
        (m) => m.id == instance.medication.id,
        orElse: () => instance.medication,
      );

      try {
        await ref.read(medicationProvider.notifier).incrementDoseCount(latestMed);
        await ref.read(adherenceProvider.notifier).logDoseTaken(
              medicationId: latestMed.id,
              medicationName: latestMed.name,
              dosage: latestMed.dosage,
              scheduledTime: instance.scheduledTime,
              actualTakenTime: takenTime,
            );
      } catch (e) {
        await ref.read(medicationProvider.notifier).decrementDoseCount(latestMed);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to log dose: $e')),
          );
        }
        return;
      }
    } else {
      try {
        await ref.read(adherenceProvider.notifier).logDoseTaken(
              medicationId: instance.medication.id,
              medicationName: instance.medication.name,
              dosage: instance.medication.dosage,
              scheduledTime: instance.scheduledTime,
              actualTakenTime: takenTime,
            );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to log dose: $e')),
          );
        }
        return;
      }
    }

    onRefresh();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Marked as taken at ${formatMedicationTime(takenTime)}'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _quickMarkAsSkipped(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();

    await ref.read(adherenceProvider.notifier).logDoseSkipped(
          medicationId: instance.medication.id,
          medicationName: instance.medication.name,
          dosage: instance.medication.dosage,
          scheduledTime: instance.scheduledTime,
          skipReason: 'Skipped from quick action',
        );

    onRefresh();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.cancel, color: Colors.white),
              SizedBox(width: 8),
              Text('Marked as skipped'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openDetailedDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DoseLoggingDialog(instance: instance),
    );

    if (result == true) {
      onRefresh();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOverdue = isInstanceOverdue(instance);

    return Dismissible(
      key: Key(
        'dismiss_${instance.medication.id}_${instance.scheduledTime.millisecondsSinceEpoch}',
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _handleSkipSwipe(context, ref),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Skip',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.skip_next, color: Colors.white),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border(left: getUrgencyBorder(instance, theme)),
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Medication icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medication,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              // Medication info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            instance.medication.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (isOverdue) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.warning, size: 16, color: Colors.red[700]),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      instance.medication.dosage,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMedicationTime(instance.scheduledTime),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Action button
              if (isOverdue)
                _buildOverdueActionsMenu(context, ref)
              else
                IconButton(
                  onPressed: () => onMarkAsTaken(instance),
                  icon: Icon(
                    Icons.check_circle_outline,
                    color: isProcessing
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  tooltip: 'Mark as taken',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverdueActionsMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
          ],
        ),
      ),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'taken_late',
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mark as Taken (Late)',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'I took it but forgot to log',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'taken_now',
          child: Row(
            children: [
              Icon(Icons.check, color: Colors.green[700], size: 20),
              const SizedBox(width: 12),
              const Text('Mark as Taken Now'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'skip',
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.orange[700], size: 20),
              const SizedBox(width: 12),
              const Text('Mark as Skipped'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              Icon(Icons.more_horiz, color: Colors.grey[700], size: 20),
              const SizedBox(width: 12),
              const Text('More Options'),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'taken_late':
            await _handleBackdate(context, ref);
            break;
          case 'taken_now':
            await onMarkAsTaken(instance);
            break;
          case 'skip':
            await _quickMarkAsSkipped(context, ref);
            break;
          case 'details':
            await _openDetailedDialog(context);
            break;
        }
      },
    );
  }
}
