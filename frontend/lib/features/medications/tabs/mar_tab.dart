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
          _buildNextDueSection(),
          const SizedBox(height: 24),
          _buildTimeline(),
          const SizedBox(height: 24),
          if (_prnInstances.isNotEmpty) _buildPrnSection(),
          const SizedBox(height: 80), // Bottom padding for FAB
        ],
      ),
    );
  }

  Widget _buildNextDueSection() {
    // Find next pending or overdue dose
    final nextDue = _scheduledInstances.where((i) {
      final isDismissed = i.log?.isDismissed ?? false;
      return !i.isTaken && !i.isSkipped && !isDismissed;
    }).firstOrNull;

    if (nextDue == null) {
      return Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 48),
              SizedBox(height: 12),
              Text(
                'All caught up!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text('No scheduled medications due right now.'),
            ],
          ),
        ),
      );
    }

    return NextDueCard(
      instance: nextDue,
      onTake: () async {
        // Check for overdue status first
        if (isInstanceOverdue(nextDue)) {
          // Late dose - prompt for time
          final takenTime = await showBackdateDoseDialog(
            context: context,
            instance: nextDue,
          );

          if (takenTime != null) {
            try {
              await ref
                  .read(adherenceProvider.notifier)
                  .logDoseTaken(
                    medicationId: nextDue.medication.id,
                    medicationName: nextDue.medication.name,
                    dosage: nextDue.medication.dosage,
                    scheduledTime: nextDue.scheduledTime,
                    actualTakenTime: takenTime,
                  );
              _loadInstances();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Late dose logged')),
                );
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
          // Not late - quick take logic specifically for the card
          try {
            await ref
                .read(adherenceProvider.notifier)
                .logDoseTaken(
                  medicationId: nextDue.medication.id,
                  medicationName: nextDue.medication.name,
                  dosage: nextDue.medication.dosage,
                  scheduledTime: nextDue.scheduledTime,
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
      },
    );
  }

  Widget _buildTimeline() {
    final theme = Theme.of(context);
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
        ...List.generate(_scheduledInstances.length, (index) {
          final instance = _scheduledInstances[index];
          final isLast = index == _scheduledInstances.length - 1;
          return _buildTimelineItem(instance, isLast);
        }),
      ],
    );
  }

  Widget _buildTimelineItem(MedicationInstance instance, bool isLast) {
    final theme = Theme.of(context);
    final isDone = instance.isTaken || instance.isSkipped;
    final isMissed = instance.isMissed && !(instance.log?.isDismissed ?? false);

    Color statusColor;
    IconData statusIcon;

    if (instance.isTaken) {
      statusColor = theme.statusColors.success;
      statusIcon = Icons.check_circle;
    } else if (instance.isSkipped) {
      statusColor = theme.statusColors.info;
      statusIcon = Icons.remove_circle_outline;
    } else if (isMissed) {
      statusColor = theme.statusColors.error;
      statusIcon = Icons.warning;
    } else {
      statusColor = theme.colorScheme.outline;
      statusIcon = Icons.radio_button_unchecked;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time Column
          SizedBox(
            width: 70,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                DateFormat('h:mm a').format(instance.scheduledTime),
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Timeline Line
          Column(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: InkWell(
                onTap: () => _handleDoseAction(instance),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDone
                        ? theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          )
                        : theme.colorScheme.surface,
                    border: Border.all(
                      color: isMissed
                          ? theme.colorScheme.error
                          : theme.colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              instance.medication.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isDone
                                    ? theme.colorScheme.onSurfaceVariant
                                    : null,
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
                      if (isDone)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              instance.isTaken ? 'Taken' : 'Skipped',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (instance.isTaken &&
                                instance.log?.actualTakenTime != null)
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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

class NextDueCard extends ConsumerStatefulWidget {
  final MedicationInstance instance;
  final VoidCallback onTake;

  const NextDueCard({super.key, required this.instance, required this.onTake});

  @override
  ConsumerState<NextDueCard> createState() => _NextDueCardState();
}

class _NextDueCardState extends ConsumerState<NextDueCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(NextDueCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instance.medication.id != widget.instance.medication.id ||
        oldWidget.instance.scheduledTime != widget.instance.scheduledTime) {
      _controller.reset();
      _isAnimating = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTake() async {
    if (_isAnimating) return;
    setState(() => _isAnimating = true);
    HapticFeedback.lightImpact();

    try {
      await _controller.forward();
      widget.onTake();
    } catch (e) {
      if (mounted) {
        setState(() => _isAnimating = false);
        _controller.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = isInstanceOverdue(widget.instance);
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      color: isOverdue
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOverdue ? Icons.warning_amber : Icons.access_time,
                  color: isOverdue
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isOverdue ? 'Overdue' : 'Up Next',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isOverdue
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('h:mm a').format(widget.instance.scheduledTime),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.instance.medication.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.instance.medication.dosage,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final animValue = _animation.value;
                      final baseColor = isOverdue
                          ? theme.colorScheme.onError
                          : theme.colorScheme.onPrimary;
                      final backgroundColor = isOverdue
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary;

                      return IconButton.filled(
                        onPressed: _isAnimating ? null : _handleTake,
                        icon: Icon(
                          animValue > 0.5 ? Icons.check_circle : Icons.check,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: backgroundColor,
                          foregroundColor: baseColor,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
