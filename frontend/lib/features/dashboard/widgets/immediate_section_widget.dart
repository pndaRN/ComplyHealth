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
  final Future<void> Function(MedicationInstance instance) onMarkAsTaken;
  final VoidCallback onRefresh;

  const ImmediateSectionWidget({
    super.key,
    required this.instances,
    required this.laterInstances,
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
class _ImmediateItem extends ConsumerStatefulWidget {
  final MedicationInstance instance;
  final Future<void> Function(MedicationInstance instance) onMarkAsTaken;
  final VoidCallback onRefresh;

  const _ImmediateItem({
    super.key,
    required this.instance,
    required this.onMarkAsTaken,
    required this.onRefresh,
  });

  @override
  ConsumerState<_ImmediateItem> createState() => _ImmediateItemState();
}

class _ImmediateItemState extends ConsumerState<_ImmediateItem>
    with TickerProviderStateMixin {
  late AnimationController _checkAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _checkAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    // Checkbox fill animation (1 second)
    _checkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkAnimationController,
      curve: Curves.easeInOut,
    );

    // Slide-off animation (1 second)
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _checkAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  MedicationInstance get instance => widget.instance;
  Future<void> Function(MedicationInstance) get onMarkAsTaken =>
      widget.onMarkAsTaken;
  VoidCallback get onRefresh => widget.onRefresh;

  Future<void> _onCheckTapped() async {
    if (_isAnimating) return;

    setState(() => _isAnimating = true);
    HapticFeedback.lightImpact();

    try {
      // 1. Start and wait for checkbox fill animation (1 second)
      await _checkAnimationController.forward().orCancel;

      // 2. Mark as taken (data update)
      await onMarkAsTaken(instance);

      // 3. Start slide-off animation
      await _slideAnimationController.forward().orCancel;

      // 4. Refresh the list after animation completes
      onRefresh();
    } catch (e) {
      // Reset animation state on error so button can be tapped again
      if (mounted) {
        setState(() => _isAnimating = false);
        _checkAnimationController.reset();
        _slideAnimationController.reset();
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = isInstanceOverdue(instance);

    return SlideTransition(
      position: _slideAnimation,
      child: Dismissible(
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
                AnimatedBuilder(
                  animation: _checkAnimation,
                  builder: (context, child) {
                    final animValue = _checkAnimation.value;
                    // Transition from grey (outline) to green (primary)
                    final greyColor = theme.colorScheme.outline;
                    final greenColor = theme.colorScheme.primary;
                    final currentColor = Color.lerp(greyColor, greenColor, animValue)!;
                    return IconButton(
                      onPressed: _isAnimating ? null : _onCheckTapped,
                      icon: Icon(
                        animValue > 0.5
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        color: currentColor,
                        size: 28 + (animValue * 4), // Slight size increase during animation
                      ),
                      tooltip: 'Mark as taken',
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _animateCompletion() async {
    if (_isAnimating) return;
    setState(() => _isAnimating = true);
    HapticFeedback.lightImpact();

    try {
      // 1. Start and wait for checkbox fill animation
      await _checkAnimationController.forward().orCancel;

      // 2. Start slide-off animation
      await _slideAnimationController.forward().orCancel;

      // 3. Refresh the list after animation completes
      onRefresh();
    } catch (e) {
      // Reset animation state on error so button can be tapped again
      if (mounted) {
        setState(() => _isAnimating = false);
        _checkAnimationController.reset();
        _slideAnimationController.reset();
      }
    }
  }

  Future<void> _markAsTakenNoRefresh(MedicationInstance inst) async {
    await onMarkAsTaken(inst);
  }

  Future<bool> _markAsTakenAtTimeNoRefresh(
    BuildContext context,
    WidgetRef ref,
    DateTime takenTime,
  ) async {
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
        return false;
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
        return false;
      }
    }

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
    return true;
  }

  Future<void> _markAsSkippedNoRefresh(WidgetRef ref) async {
    await ref.read(adherenceProvider.notifier).logDoseSkipped(
          medicationId: instance.medication.id,
          medicationName: instance.medication.name,
          dosage: instance.medication.dosage,
          scheduledTime: instance.scheduledTime,
          skipReason: 'Skipped from quick action',
        );
  }

  Widget _buildOverdueActionsMenu(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _checkAnimation,
      builder: (context, child) {
        final animValue = _checkAnimation.value;
        // Transition from orange (outline) to green (primary)
        final errorColor = theme.colorScheme.error;
        final primaryColor = theme.colorScheme.primary;
        final currentColor = Color.lerp(errorColor, primaryColor, animValue)!;

        return PopupMenuButton<String>(
          enabled: !_isAnimating,
          icon: Icon(
            animValue > 0.5 ? Icons.check_circle : Icons.error_outline,
            color: currentColor,
            size: 28 + (animValue * 4),
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
            bool shouldAnimate = false;
            switch (value) {
              case 'taken_late':
                final selectedTime = await showBackdateDoseDialog(
                  context: context,
                  instance: instance,
                );
                if (selectedTime != null) {
                  await _markAsTakenAtTimeNoRefresh(context, ref, selectedTime);
                  shouldAnimate = true;
                }
                break;
              case 'taken_now':
                await _markAsTakenNoRefresh(instance);
                shouldAnimate = true;
                break;
              case 'skip':
                await _markAsSkippedNoRefresh(ref);
                shouldAnimate = true;
                break;
              case 'details':
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => DoseLoggingDialog(instance: instance),
                );
                if (result == true) {
                  shouldAnimate = true;
                }
                break;
            }
            if (shouldAnimate) {
              await _animateCompletion();
            }
          },
        );
      },
    );
  }
}
