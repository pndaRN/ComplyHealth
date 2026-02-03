import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/core/state/medication_provider.dart';
import 'package:complyhealth/features/dashboard/dialogs/dose_logging_dialog.dart';
import 'package:complyhealth/features/dashboard/utils/todays_medications_utils.dart';
import 'package:complyhealth/features/dashboard/widgets/immediate_section_widget.dart';
import 'package:complyhealth/features/dashboard/widgets/later_section_widget.dart';
import 'package:complyhealth/features/dashboard/widgets/missed_section_widget.dart';
import 'package:complyhealth/features/dashboard/widgets/prn_section_widget.dart';

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
  final bool _laterExpanded = false;
  final bool _prnExpanded = false;
  final bool _missedExpanded = true;
  bool _isLoading = true;
  bool _isExpanded = false;

  // Adherence tracking
  int _todayTotal = 0;
  int _todayTaken = 0;
  double _todayAdherence = 0.0;

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
      const Duration(hours: TodaysMedicationsConstants.immediateWindowHours),
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
          scheduledTime.add(
            const Duration(
              minutes: TodaysMedicationsConstants.graceWindowMinutes,
            ),
          ),
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
        a.scheduledTime.add(
          const Duration(
            minutes: TodaysMedicationsConstants.graceWindowMinutes,
          ),
        ),
      );
      final bOverdue = now.isAfter(
        b.scheduledTime.add(
          const Duration(
            minutes: TodaysMedicationsConstants.graceWindowMinutes,
          ),
        ),
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
  }

  Future<void> _markAsTakenWithDelay(MedicationInstance instance) async {
    // Just mark as taken - the child widget handles animation and refresh
    await _quickMarkAsTaken(instance);
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
          AnimatedCrossFade(
            firstChild: Container(height: 0.0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1),
                _buildAdherenceSummary(),
                if (_missedInstances.isNotEmpty)
                  MissedSectionWidget(
                    instances: _missedInstances,
                    initiallyExpanded: _missedExpanded,
                    onRefresh: _loadAndCategorizeInstances,
                  ),
                ImmediateSectionWidget(
                  instances: _immediateInstances,
                  laterInstances: _laterInstances,
                  onMarkAsTaken: _markAsTakenWithDelay,
                  onRefresh: _loadAndCategorizeInstances,
                ),
                if (_laterInstances.isNotEmpty)
                  LaterSectionWidget(
                    instances: _laterInstances,
                    initiallyExpanded: _laterExpanded,
                    onItemTap: _openDetailedDialog,
                  ),
                if (_prnInstances.isNotEmpty)
                  PRNSectionWidget(
                    instances: _prnInstances,
                    initiallyExpanded: _prnExpanded,
                    onRefresh: _loadAndCategorizeInstances,
                    onItemTap: _openDetailedDialog,
                  ),
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
                color: getAdherenceColor(_todayAdherence, theme),
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
                getAdherenceColor(_todayAdherence, Theme.of(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
