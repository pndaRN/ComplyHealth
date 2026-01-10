import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/core/theme/status_colors.dart';
import 'package:complyhealth/features/dashboard/dialogs/recovery_taken_dialog.dart';
import 'package:complyhealth/features/dashboard/dialogs/recovery_skipped_dialog.dart';
import 'package:complyhealth/features/dashboard/utils/todays_medications_utils.dart';

/// Widget displaying the missed doses section with recovery options.
class MissedSectionWidget extends ConsumerStatefulWidget {
  final List<MedicationInstance> instances;
  final bool initiallyExpanded;
  final VoidCallback onRefresh;

  const MissedSectionWidget({
    super.key,
    required this.instances,
    required this.initiallyExpanded,
    required this.onRefresh,
  });

  @override
  ConsumerState<MissedSectionWidget> createState() =>
      _MissedSectionWidgetState();
}

class _MissedSectionWidgetState extends ConsumerState<MissedSectionWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  Future<void> _handleRecoverAsTaken(MedicationInstance instance) async {
    final selectedTime = await showRecoveryTakenDialog(
      context: context,
      instance: instance,
    );

    if (selectedTime != null && instance.log != null) {
      HapticFeedback.lightImpact();

      await ref.read(adherenceProvider.notifier).recoverMissedDoseAsTaken(
            logId: instance.log!.id,
            actualTakenTime: selectedTime,
          );

      widget.onRefresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Recovered as taken at ${formatMedicationTime(selectedTime)}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleRecoverAsSkipped(MedicationInstance instance) async {
    final reason = await showRecoverySkippedDialog(
      context: context,
      instance: instance,
    );

    if (reason != null && instance.log != null) {
      HapticFeedback.lightImpact();

      await ref.read(adherenceProvider.notifier).recoverMissedDoseAsSkipped(
            logId: instance.log!.id,
            skipReason: reason,
          );

      widget.onRefresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cancel, color: Colors.white),
                SizedBox(width: 8),
                Text('Changed to skipped'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleDismiss(MedicationInstance instance) async {
    if (instance.log == null) return;

    HapticFeedback.lightImpact();

    await ref.read(adherenceProvider.notifier).dismissMissedDose(
          logId: instance.log!.id,
        );

    widget.onRefresh();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.visibility_off, color: Colors.white),
              SizedBox(width: 8),
              Text('Dismissed from list'),
            ],
          ),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExpansionTile(
      title: Row(
        children: [
          Icon(Icons.error_outline, color: theme.statusColors.error, size: 20),
          const SizedBox(width: 8),
          Text(
            'Missed (${widget.instances.length})',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.statusColors.error,
            ),
          ),
        ],
      ),
      initiallyExpanded: _isExpanded,
      onExpansionChanged: (expanded) {
        setState(() => _isExpanded = expanded);
      },
      children: widget.instances.map((instance) {
        return _buildMissedItem(instance, theme);
      }).toList(),
    );
  }

  Widget _buildMissedItem(MedicationInstance instance, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.statusColors.error, width: 4),
        ),
        color: theme.statusColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.statusColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.medication,
                color: theme.statusColors.error,
              ),
            ),
            const SizedBox(width: 12),
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.statusColors.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Missed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    instance.medication.dosage,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Scheduled: ${formatMedicationTime(instance.scheduledTime)}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _buildRecoverMenu(instance, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoverMenu(MedicationInstance instance, ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.statusColors.error,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Recover',
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
          value: 'mark_taken',
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mark as Taken',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Select when you took it',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'mark_skipped',
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.orange[700], size: 20),
              const SizedBox(width: 12),
              const Text('Mark as Skipped'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'dismiss',
          child: Row(
            children: [
              Icon(Icons.visibility_off, color: Colors.grey[700], size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dismiss'),
                    Text(
                      'Hide from list, keep as missed',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'mark_taken':
            await _handleRecoverAsTaken(instance);
            break;
          case 'mark_skipped':
            await _handleRecoverAsSkipped(instance);
            break;
          case 'dismiss':
            await _handleDismiss(instance);
            break;
        }
      },
    );
  }
}
