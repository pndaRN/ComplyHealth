import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/core/state/medication_provider.dart';
import 'package:complyhealth/core/theme/status_colors.dart';
import 'package:complyhealth/features/dashboard/dialogs/dose_logging_dialog.dart';

class TodaysMedicationsWidget extends ConsumerStatefulWidget {
  const TodaysMedicationsWidget({super.key});

  @override
  ConsumerState<TodaysMedicationsWidget> createState() =>
      _TodaysMedicationsWidgetState();
}

class _TodaysMedicationsWidgetState
    extends ConsumerState<TodaysMedicationsWidget> {
  // Categorized medication lists
  List<MedicationInstance> _immediateInstances = [];
  List<MedicationInstance> _laterInstances = [];
  List<MedicationInstance> _prnInstances = [];
  List<MedicationInstance> _missedInstances = [];

  // UI state
  bool _laterExpanded = false;
  bool _prnExpanded = false;
  bool _missedExpanded = true;
  bool _isLoading = true;
  bool _isExpanded = false;

  // Adherence tracking
  int _todayTotal = 0;
  int _todayTaken = 0;
  double _todayAdherence = 0.0;

  // Time window constants (in hours)
  static const int _immediateWindowHours = 2;
  static const int _graceWindowMinutes = 60;

  // Dose count color thresholds
  static const double _maxDoseRatio = 1.0;
  static const double _warningDoseRatio = 0.75;

  @override
  void initState() {
    super.initState();
    _loadAndCategorizeInstances();
  }

  Future<void> _loadAndCategorizeInstances() async {
    setState(() => _isLoading = true);

    final instances = await ref
        .read(adherenceProvider.notifier)
        .getTodayInstances();
    final now = DateTime.now();
    final immediateThreshold = now.add(
      const Duration(hours: _immediateWindowHours),
    );

    // Reset categorized lists
    final immediate = <MedicationInstance>[];
    final later = <MedicationInstance>[];
    final prn = <MedicationInstance>[];
    final missed = <MedicationInstance>[];

    // Categorize each instance
    for (final instance in instances) {
      if (instance.isPRN) {
        // PRN medications always show regardless of status
        prn.add(instance);
      } else {
        // Collect missed doses (non-dismissed) into missed section
        if (instance.isMissed) {
          if (instance.log != null && !instance.log!.isDismissed) {
            missed.add(instance);
          }
          continue;
        }

        // Skip other completed scheduled medications (taken, skipped)
        if (instance.isTaken || instance.isSkipped) {
          continue;
        }

        final scheduledTime = instance.scheduledTime;
        final isOverdue = now.isAfter(
          scheduledTime.add(const Duration(minutes: _graceWindowMinutes)),
        );
        final isDueNow = now.isAfter(scheduledTime);
        final isWithinWindow = scheduledTime.isBefore(immediateThreshold);

        final isImmediate = isOverdue || isDueNow || isWithinWindow;

        if (isImmediate) {
          immediate.add(instance);
        } else {
          later.add(instance);
        }
      }
    }

    // Sort missed by scheduled time (most recent first)
    missed.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

    // Sort immediate: overdue first, then by scheduled time
    immediate.sort((a, b) {
      final aOverdue = now.isAfter(
        a.scheduledTime.add(const Duration(minutes: _graceWindowMinutes)),
      );
      final bOverdue = now.isAfter(
        b.scheduledTime.add(const Duration(minutes: _graceWindowMinutes)),
      );

      if (aOverdue && !bOverdue) return -1;
      if (!aOverdue && bOverdue) return 1;
      return a.scheduledTime.compareTo(b.scheduledTime);
    });

    // Sort later by scheduled time
    later.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    // Sort PRN alphabetically
    prn.sort((a, b) => a.medication.name.compareTo(b.medication.name));

    // Calculate adherence (excluding PRN)
    final scheduled = instances.where((i) => !i.isPRN).toList();
    final taken = scheduled.where((i) => i.isTaken).length;
    final total = scheduled.length;
    final adherence = total > 0 ? (taken / total) * 100 : 0.0;

    setState(() {
      _immediateInstances = immediate;
      _laterInstances = later;
      _prnInstances = prn;
      _missedInstances = missed;
      _todayTotal = total;
      _todayTaken = taken;
      _todayAdherence = adherence;
      _isLoading = false;
    });
  }

  Future<void> _quickMarkAsTaken(MedicationInstance instance) async {
    HapticFeedback.lightImpact();

    // For PRN medications, increment count first to ensure atomicity
    if (instance.isPRN) {
      // Get the latest medication state from provider
      final medicationsAsync = ref.read(medicationProvider);
      final latestMed = (medicationsAsync.value ?? []).firstWhere(
        (m) => m.id == instance.medication.id,
        orElse: () => instance.medication,
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
              scheduledTime: instance.scheduledTime,
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
        rethrow;
      }
    } else {
      // For scheduled medications, just log the dose
      try {
        await ref
            .read(adherenceProvider.notifier)
            .logDoseTaken(
              medicationId: instance.medication.id,
              medicationName: instance.medication.name,
              dosage: instance.medication.dosage,
              scheduledTime: instance.scheduledTime,
            );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to log dose: $e')));
        }
        rethrow;
      }
    }

    await _loadAndCategorizeInstances();
  }

  Future<void> _openDetailedDialog(MedicationInstance instance) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DoseLoggingDialog(instance: instance),
    );

    if (result == true) {
      await _loadAndCategorizeInstances();
    }
  }

  Future<bool> _showSkipConfirmation(MedicationInstance instance) async {
    final skipReasons = [
      'Forgot',
      'Side effects',
      'Unavailable',
      'Not needed',
      'Other',
    ];

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Skip ${instance.medication.name}?'),
            const SizedBox(height: 16),
            const Text(
              'Select a reason:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...skipReasons.map(
              (r) => ListTile(
                dense: true,
                title: Text(r),
                onTap: () => Navigator.pop(context, r),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (reason != null) {
      HapticFeedback.lightImpact();
      try {
        await ref
            .read(adherenceProvider.notifier)
            .logDoseSkipped(
              medicationId: instance.medication.id,
              medicationName: instance.medication.name,
              dosage: instance.medication.dosage,
              scheduledTime: instance.scheduledTime,
              skipReason: reason,
            );
        await _loadAndCategorizeInstances();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to skip dose: $e')));
        }
      }
    }

    return false; // Don't dismiss the widget, we handle removal via reload
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  Color _getAdherenceColor(double adherence, ThemeData theme) {
    if (adherence >= 90) return theme.statusColors.success;
    if (adherence >= 75) return theme.statusColors.info;
    if (adherence >= 50) return theme.statusColors.warning;
    return theme.statusColors.error;
  }

  Color _getDoseCountColor(int current, int max, ThemeData theme) {
    if (max == 0) return theme.colorScheme.onSurfaceVariant;
    final ratio = current / max;
    if (ratio >= _maxDoseRatio) return theme.statusColors.error;
    if (ratio >= _warningDoseRatio) return theme.statusColors.warning;
    return theme.statusColors.success;
  }

  BorderSide _getUrgencyBorder(MedicationInstance instance, ThemeData theme) {
    final now = DateTime.now();
    final scheduledTime = instance.scheduledTime;

    // Overdue (past grace period)
    if (now.isAfter(
      scheduledTime.add(const Duration(minutes: _graceWindowMinutes)),
    )) {
      return BorderSide(color: theme.statusColors.error, width: 6);
    }

    // Within 30 minutes of scheduled time
    if (now.isAfter(scheduledTime.subtract(const Duration(minutes: 30))) &&
        now.isBefore(scheduledTime.add(const Duration(minutes: 30)))) {
      return BorderSide(color: theme.statusColors.warning, width: 4);
    }

    // Within 2-hour window
    return BorderSide(color: theme.statusColors.info, width: 4);
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

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          // Use AnimatedCrossFade to switch between hidden (Container) and shown (Column)
          AnimatedCrossFade(
            firstChild: Container(height: 0.0), // Empty state
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1),
                _buildAdherenceSummary(),
                if (_missedInstances.isNotEmpty) _buildMissedSection(),
                _buildImmediateSection(),
                if (_laterInstances.isNotEmpty) _buildLaterSection(),
                if (_prnInstances.isNotEmpty) _buildPRNSection(),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.textTheme.titleLarge?.color,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Today\'s Medications',
                  maxLines: 1,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getAdherenceColor(_todayAdherence, theme),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$_todayTaken/$_todayTotal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today: ${_todayAdherence.toStringAsFixed(0)}%',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (_todayAdherence >= 100)
                const Text(
                  'Perfect adherence!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _todayTotal > 0 ? _todayTaken / _todayTotal : 0.0,
              minHeight: 8,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getAdherenceColor(_todayAdherence, Theme.of(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImmediateSection() {
    if (_immediateInstances.isEmpty) {
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
            if (_laterInstances.isNotEmpty)
              Text(
                'Next dose at ${_formatTime(_laterInstances.first.scheduledTime)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
          ],
        ),
      );
    }

    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            _immediateInstances.any(
                  (i) => now.isAfter(
                    i.scheduledTime.add(
                      const Duration(minutes: _graceWindowMinutes),
                    ),
                  ),
                )
                ? 'Overdue & Due Now'
                : 'Due Now',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
        ),
        ..._immediateInstances.map(
          (instance) => _buildImmediateItem(
            instance,
            key: Key(
              '${instance.medication.id}_${instance.scheduledTime.millisecondsSinceEpoch}',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImmediateItem(MedicationInstance instance, {Key? key}) {
    final now = DateTime.now();
    final isOverdue = now.isAfter(
      instance.scheduledTime.add(const Duration(minutes: _graceWindowMinutes)),
    );

    return Dismissible(
      key: Key(
        'dismiss_${instance.medication.id}_${instance.scheduledTime.millisecondsSinceEpoch}',
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showSkipConfirmation(instance),
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
          border: Border(left: _getUrgencyBorder(instance, Theme.of(context))),
          color: Theme.of(context).colorScheme.surface,
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
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medication,
                  color: Theme.of(context).colorScheme.primary,
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
                      _formatTime(instance.scheduledTime),
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
                _buildOverdueActionsMenu(instance)
              else 
                ElevatedButton(
                onPressed: () => _quickMarkAsTaken(instance),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Mark Taken', style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildOverdueActionsMenu(MedicationInstance instance) {
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
          await _showBackdateDialog(instance);
          break;
        case 'taken_now':
          await _quickMarkAsTaken(instance);
          break;
        case 'skip':
          await _quickMarkAsSkipped(instance);
          break;
        case 'details':
          await _openDetailedDialog(instance);
          break;
      }
    },
  );
}

Future<void> _showBackdateDialog(MedicationInstance instance) async {
  DateTime selectedTime = instance.scheduledTime;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Mark as Taken (Late)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instance.medication.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Scheduled: ${_formatTime(instance.scheduledTime)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'When did you actually take it?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(selectedTime),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedTime = DateTime(
                        selectedTime.year,
                        selectedTime.month,
                        selectedTime.day,
                        picked.hour,
                        picked.minute,
                      );
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _formatTime(selectedTime),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.edit, size: 18, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will mark the dose as taken at the time you specify',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    ),
  );

  if (confirmed == true) {
    await _markAsTakenAtTime(instance, selectedTime);
  }
}

Future<void> _markAsTakenAtTime(
  MedicationInstance instance,
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
      if (mounted) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log dose: $e')),
        );
      }
      return;
    }
  }

  await _loadAndCategorizeInstances();
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Marked as taken at ${_formatTime(takenTime)}'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

Future<void> _quickMarkAsSkipped(MedicationInstance instance) async {
  HapticFeedback.lightImpact();

  await ref.read(adherenceProvider.notifier).logDoseSkipped(
    medicationId: instance.medication.id,
    medicationName: instance.medication.name,
    dosage: instance.medication.dosage,
    scheduledTime: instance.scheduledTime,
    skipReason: 'Skipped from quick action',
  );

  await _loadAndCategorizeInstances();

  if (mounted) {
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

  Widget _buildMissedSection() {
    final theme = Theme.of(context);

    return ExpansionTile(
      title: Row(
        children: [
          Icon(Icons.error_outline, color: theme.statusColors.error, size: 20),
          const SizedBox(width: 8),
          Text(
            'Missed (${_missedInstances.length})',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.statusColors.error,
            ),
          ),
        ],
      ),
      initiallyExpanded: _missedExpanded,
      onExpansionChanged: (expanded) {
        setState(() => _missedExpanded = expanded);
      },
      children: _missedInstances.map((instance) {
        return _buildMissedItem(instance);
      }).toList(),
    );
  }

  Widget _buildMissedItem(MedicationInstance instance) {
    final theme = Theme.of(context);

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
                    'Scheduled: ${_formatTime(instance.scheduledTime)}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _buildMissedActionsMenu(instance),
          ],
        ),
      ),
    );
  }

  Widget _buildMissedActionsMenu(MedicationInstance instance) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).statusColors.error,
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
            await _showRecoveryTakenDialog(instance);
            break;
          case 'mark_skipped':
            await _showRecoverySkippedDialog(instance);
            break;
          case 'dismiss':
            await _dismissMissedDose(instance);
            break;
        }
      },
    );
  }

Future<void> _showRecoveryTakenDialog(MedicationInstance instance) async {
  DateTime selectedTime = DateTime.now();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Mark as Taken'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instance.medication.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Originally scheduled: ${_formatTime(instance.scheduledTime)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'When did you actually take it?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(selectedTime),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedTime = DateTime(
                        selectedTime.year,
                        selectedTime.month,
                        selectedTime.day,
                        picked.hour,
                        picked.minute,
                      );
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _formatTime(selectedTime),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.edit, size: 18, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    ),
  );

  if (confirmed == true && instance.log != null) {
    HapticFeedback.lightImpact();

    await ref.read(adherenceProvider.notifier).recoverMissedDoseAsTaken(
      logId: instance.log!.id,
      actualTakenTime: selectedTime,
    );

    await _loadAndCategorizeInstances();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Recovered as taken at ${_formatTime(selectedTime)}'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

Future<void> _showRecoverySkippedDialog(MedicationInstance instance) async {
  final skipReasons = [
    'Forgot',
    'Side effects',
    'Unavailable',
    'Not needed',
    'Other',
  ];

  final reason = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Mark as Skipped'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            instance.medication.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a reason:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...skipReasons.map(
            (r) => ListTile(
              dense: true,
              title: Text(r),
              onTap: () => Navigator.pop(context, r),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );

  if (reason != null && instance.log != null) {
    HapticFeedback.lightImpact();

    await ref.read(adherenceProvider.notifier).recoverMissedDoseAsSkipped(
      logId: instance.log!.id,
      skipReason: reason,
    );

    await _loadAndCategorizeInstances();

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

Future<void> _dismissMissedDose(MedicationInstance instance) async {
  if (instance.log == null) return;

  HapticFeedback.lightImpact();

  await ref.read(adherenceProvider.notifier).dismissMissedDose(
    logId: instance.log!.id,
  );

  await _loadAndCategorizeInstances();

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

  Widget _buildLaterSection() {
    return ExpansionTile(
      title: Text(
        'Later Today (${_laterInstances.length})',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      initiallyExpanded: _laterExpanded,
      onExpansionChanged: (expanded) {
        setState(() => _laterExpanded = expanded);
      },
      children: _laterInstances.map((instance) {
        return Opacity(
          key: Key(
            'later_${instance.medication.id}_${instance.scheduledTime.millisecondsSinceEpoch}',
          ),
          opacity: 0.6,
          child: ListTile(
            leading: Icon(Icons.medication, color: Colors.grey[600]),
            title: Text(
              instance.medication.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            subtitle: Text(instance.medication.dosage),
            trailing: Text(
              _formatTime(instance.scheduledTime),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            onTap: () => _openDetailedDialog(instance),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPRNSection() {
    return ExpansionTile(
      title: Text(
        'As Needed (${_prnInstances.length})',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      initiallyExpanded: _prnExpanded,
      onExpansionChanged: (expanded) {
        setState(() => _prnExpanded = expanded);
      },
      children: _prnInstances.map((instance) {
        final medication = instance.medication;
        final currentDoses = medication.currentDoseCount;
        final maxDoses = medication.maxDailyDoses ?? 0;
        final canTake = currentDoses < maxDoses;
        final theme = Theme.of(context);
        final doseColor = _getDoseCountColor(currentDoses, maxDoses, theme);

        return Container(
          key: Key('prn_${medication.id}'),
          decoration: BoxDecoration(
            color: theme.statusColors.prn.withValues(alpha: 0.05),
          ),
          child: ListTile(
            leading: Icon(Icons.medication, color: theme.statusColors.prn),
            title: Text(
              medication.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medication.dosage),
                const SizedBox(height: 4),
                Text(
                  'Taken: $currentDoses/$maxDoses doses today',
                  style: TextStyle(
                    fontSize: 12,
                    color: doseColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            trailing: canTake
                ? IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () => _quickMarkAsTaken(instance),
                    tooltip: 'Log dose',
                  )
                : Icon(Icons.block, color: Colors.red[400]),
            onTap: () => _openDetailedDialog(instance),
          ),
        );
      }).toList(),
    );
  }
}
