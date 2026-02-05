import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/state/adherence_provider.dart';
import '../../../../core/state/medication_provider.dart';
import '../../../../core/theme/status_colors.dart';
import '../../dashboard/dialogs/backdate_dose_dialog.dart';
import '../../dashboard/dialogs/dose_logging_dialog.dart';
import '../../dashboard/utils/todays_medications_utils.dart';

class MarTab extends ConsumerStatefulWidget {
  const MarTab({super.key});

  @override
  ConsumerState<MarTab> createState() => _MarTabState();
}

class _MarTabState extends ConsumerState<MarTab> {
  List<MedicationInstance> _scheduledInstances = [];
  List<MedicationInstance> _prnInstances = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstances();
  }

  Future<void> _loadInstances() async {
    setState(() => _isLoading = true);
    final instances = await ref
        .read(adherenceProvider.notifier)
        .getTodayInstances();

    final scheduled = <MedicationInstance>[];
    final prn = <MedicationInstance>[];

    for (final instance in instances) {
      if (instance.isPRN) {
        prn.add(instance);
      } else {
        scheduled.add(instance);
      }
    }

    // Sort scheduled by time
    scheduled.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    // Sort PRN by name
    prn.sort((a, b) => a.medication.name.compareTo(b.medication.name));

    if (mounted) {
      setState(() {
        _scheduledInstances = scheduled;
        _prnInstances = prn;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDoseAction(MedicationInstance instance) async {
    HapticFeedback.selectionClick();

    // For PRN, increment count first
    if (instance.isPRN) {
      final meds = ref.read(medicationProvider).value ?? [];
      final med = meds.firstWhere(
        (m) => m.id == instance.medication.id,
        orElse: () => instance.medication,
      );

      try {
        await ref.read(medicationProvider.notifier).incrementDoseCount(med);
        await ref
            .read(adherenceProvider.notifier)
            .logDoseTaken(
              medicationId: med.id,
              medicationName: med.name,
              dosage: med.dosage,
              scheduledTime: instance.scheduledTime,
              isPRN: true,
            );
        _loadInstances();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
      return;
    }

    // For scheduled, open dialog if taken/skipped to edit, or simple tap to log
    if (instance.log != null) {
      // Already logged - show details/edit
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => DoseLoggingDialog(instance: instance),
      );
      if (result == true) _loadInstances();
    } else {
      // Not logged
      if (isInstanceOverdue(instance)) {
        // Late dose - prompt for time
        final takenTime = await showBackdateDoseDialog(
          context: context,
          instance: instance,
        );

        if (takenTime != null) {
          try {
            await ref
                .read(adherenceProvider.notifier)
                .logDoseTaken(
                  medicationId: instance.medication.id,
                  medicationName: instance.medication.name,
                  dosage: instance.medication.dosage,
                  scheduledTime: instance.scheduledTime,
                  actualTakenTime: takenTime,
                );
            _loadInstances();
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Late dose logged')));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        }
      } else {
        // Not late - quick take
        try {
          await ref
              .read(adherenceProvider.notifier)
              .logDoseTaken(
                medicationId: instance.medication.id,
                medicationName: instance.medication.name,
                dosage: instance.medication.dosage,
                scheduledTime: instance.scheduledTime,
              );
          _loadInstances();
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Dose logged')));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadInstances,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTimeline(),
          const SizedBox(height: 24),
          if (_prnInstances.isNotEmpty) _buildPrnSection(),
          const SizedBox(height: 80), // Bottom padding for FAB
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // Group instances by scheduled time
    final Map<DateTime, List<MedicationInstance>> grouped = {};
    for (final instance in _scheduledInstances) {
      final time = instance.scheduledTime;
      if (!grouped.containsKey(time)) {
        grouped[time] = [];
      }
      grouped[time]!.add(instance);
    }

    final sortedTimes = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Schedule',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...sortedTimes.map((time) {
          final instances = grouped[time]!;

          // Determine if this slot is "late" or has unlogged doses
          final bool hasLateOrUnlogged = instances.any((i) {
            // Only consider missed if time sensitive
            final isMissed = i.isMissed && !(i.log?.isDismissed ?? false);
            final isPending = i.log == null;
            // Use isInstanceOverdue to respect isTimeSensitive logic
            final isPast = isInstanceOverdue(i);

            // If not time sensitive, we don't flag as action needed (red) unless explicitly missed (which shouldn't happen automatically)
            if (!i.medication.isTimeSensitive && isPending) return false;

            return isMissed || (isPending && isPast);
          });

          // Determine if slot should be auto-expanded
          final bool isWithinHour = now.difference(time).inMinutes.abs() <= 60;
          final bool shouldExpand = isWithinHour || hasLateOrUnlogged;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            color: hasLateOrUnlogged
                ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
                : null,
            child: ExpansionTile(
              initiallyExpanded: shouldExpand,
              shape: const Border(),
              collapsedShape: const Border(),
              backgroundColor: hasLateOrUnlogged
                  ? theme.colorScheme.errorContainer.withValues(alpha: 0.1)
                  : null,
              title: Row(
                children: [
                  Icon(
                    hasLateOrUnlogged ? Icons.warning_amber : Icons.access_time,
                    size: 20,
                    color: hasLateOrUnlogged
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('h:mm a').format(time),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: hasLateOrUnlogged ? theme.colorScheme.error : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasLateOrUnlogged)
                    Text(
                      '(Action Needed)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              children: [
                const Divider(height: 1),
                ...instances.map(
                  (instance) => _buildMedicationInstanceTile(instance),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMedicationInstanceTile(MedicationInstance instance) {
    return _MedicationTile(
      instance: instance,
      onAction: () async {
        await _handleDoseAction(instance);
        return true;
      },
      onEdit: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => DoseLoggingDialog(instance: instance),
        );
        if (result == true) _loadInstances();
      },
    );
  }

  Widget _buildPrnSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'As Needed (PRN)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._prnInstances.map((instance) {
          final count = instance.medication.currentDoseCount;
          final max = instance.medication.maxDailyDoses;
          final isMaxed = max != null && count >= max;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(instance.medication.name),
              subtitle: Text(instance.medication.dosage),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count${max != null ? '/$max' : ''}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    onPressed: isMaxed
                        ? null
                        : () => _handleDoseAction(instance),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _MedicationTile extends ConsumerStatefulWidget {
  final MedicationInstance instance;
  final Future<bool> Function() onAction;
  final VoidCallback onEdit;

  const _MedicationTile({
    required this.instance,
    required this.onAction,
    required this.onEdit,
  });

  @override
  ConsumerState<_MedicationTile> createState() => _MedicationTileState();
}

class _MedicationTileState extends ConsumerState<_MedicationTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isAnimating || widget.instance.isTaken || widget.instance.isSkipped) {
      return;
    }
    setState(() => _isAnimating = true);
    HapticFeedback.lightImpact();

    try {
      await _controller.forward();
      await widget.onAction();
      if (mounted) {
        setState(() => _isAnimating = false);
        _controller.reset();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnimating = false);
        _controller.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instance = widget.instance;
    final isDone = instance.isTaken || instance.isSkipped;
    final isMissed = instance.isMissed && !(instance.log?.isDismissed ?? false);

    Color statusColor;
    IconData statusIcon;

    if (instance.isTaken) {
      statusColor = theme.statusColors.success;
      statusIcon = Icons.check;
    } else if (instance.isSkipped) {
      statusColor = theme.statusColors.info;
      statusIcon = Icons.remove_circle_outline;
    } else if (isMissed) {
      statusColor = theme.statusColors.error;
      statusIcon = Icons.warning;
    } else {
      statusColor = theme.colorScheme.outline;
      statusIcon = Icons.check;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: widget.onEdit,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instance.medication.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? theme.colorScheme.onSurfaceVariant : null,
                    ),
                  ),
                  Text(
                    instance.medication.dosage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (!isDone) ...[
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: widget.onEdit,
              tooltip: 'More options',
            ),
            const SizedBox(width: 8),
          ],
          if (isDone)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    instance.isTaken ? 'Taken' : 'Skipped',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (instance.isTaken && instance.log?.actualTakenTime != null)
                    Text(
                      DateFormat(
                        'h:mm a',
                      ).format(instance.log!.actualTakenTime!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          GestureDetector(
            onTap: isDone ? widget.onEdit : _handlePress,
            child: RepaintBoundary(
              child: SizedBox(
                height: 40,
                width: 40,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final animValue = _animation.value;

                    final baseColor = statusColor;
                    final currentBg =
                        Color.lerp(
                          isDone || isMissed ? baseColor : Colors.transparent,
                          isDone || isMissed ? Colors.white : baseColor,
                          animValue,
                        ) ??
                        baseColor;

                    final currentFg =
                        Color.lerp(
                          isDone || isMissed ? Colors.white : baseColor,
                          isDone || isMissed ? baseColor : Colors.white,
                          animValue,
                        ) ??
                        baseColor;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isAnimating)
                          SizedBox(
                            height: 38,
                            width: 38,
                            child: CircularProgressIndicator(
                              value: animValue,
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                baseColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentBg,
                            border: Border.all(
                              color: isDone || isMissed
                                  ? Colors.transparent
                                  : baseColor,
                              width: 2,
                            ),
                          ),
                          child: Transform.scale(
                            scale: 1.0 + (0.1 * animValue),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Opacity(
                                  opacity: (1 - (animValue * 2)).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  child: Icon(
                                    statusIcon,
                                    color: currentFg,
                                    size: 18,
                                  ),
                                ),
                                Opacity(
                                  opacity: ((animValue - 0.5) * 2).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: currentFg,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
