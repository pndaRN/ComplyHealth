import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Categorized medication lists
  List<MedicationInstance> _immediateInstances = [];
  List<MedicationInstance> _laterInstances = [];
  List<MedicationInstance> _prnInstances = [];

  // UI state
  bool _laterExpanded = false;
  bool _prnExpanded = false;
  bool _isLoading = true;

  // Adherence tracking
  int _todayTotal = 0;
  int _todayTaken = 0;
  double _todayAdherence = 0.0;

  // Time window constants (in hours)
  static const int _immediateWindowHours = 2;
  static const int _graceWindowMinutes = 30;

  @override
  void initState() {
    super.initState();
    _loadAndCategorizeInstances();
  }

  Future<void> _loadAndCategorizeInstances() async {
    setState(() => _isLoading = true);

    final instances = await ref.read(adherenceProvider.notifier).getTodayInstances();
    final now = DateTime.now();
    final immediateThreshold = now.add(const Duration(hours: _immediateWindowHours));

    // Reset categorized lists
    final immediate = <MedicationInstance>[];
    final later = <MedicationInstance>[];
    final prn = <MedicationInstance>[];

    // Categorize each instance
    for (final instance in instances) {
      // Skip completed medications (taken, skipped, or missed)
      if (instance.isTaken || instance.isSkipped || instance.isMissed) {
        continue;
      }

      if (instance.isPRN) {
        prn.add(instance);
      } else {
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
      _todayTotal = total;
      _todayTaken = taken;
      _todayAdherence = adherence;
      _isLoading = false;
    });
  }

  Future<void> _quickMarkAsTaken(MedicationInstance instance) async {
    HapticFeedback.lightImpact();
    await ref.read(adherenceProvider.notifier).logDoseTaken(
          medicationId: instance.medication.id,
          medicationName: instance.medication.name,
          dosage: instance.medication.dosage,
          scheduledTime: instance.scheduledTime,
        );
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

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  Color _getAdherenceColor(double adherence) {
    if (adherence >= 90) return Colors.green;
    if (adherence >= 75) return Colors.blue;
    if (adherence >= 50) return Colors.orange;
    return Colors.red;
  }

  BorderSide _getUrgencyBorder(MedicationInstance instance) {
    final now = DateTime.now();
    final scheduledTime = instance.scheduledTime;

    // Overdue (past grace period)
    if (now.isAfter(scheduledTime.add(const Duration(minutes: _graceWindowMinutes)))) {
      return const BorderSide(color: Colors.red, width: 6);
    }

    // Within 30 minutes of scheduled time
    if (now.isAfter(scheduledTime.subtract(const Duration(minutes: 30))) &&
        now.isBefore(scheduledTime.add(const Duration(minutes: 30)))) {
      return const BorderSide(color: Colors.orange, width: 4);
    }

    // Within 2-hour window
    return const BorderSide(color: Colors.blue, width: 4);
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
          const Divider(height: 1),
          _buildAdherenceSummary(),
          const Divider(height: 1),
          _buildImmediateSection(),
          if (_laterInstances.isNotEmpty) _buildLaterSection(),
          if (_prnInstances.isNotEmpty) _buildPRNSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getAdherenceColor(_todayAdherence),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getAdherenceColor(_todayAdherence),
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            if (_laterInstances.isNotEmpty)
              Text(
                'Next dose at ${_formatTime(_laterInstances.first.scheduledTime)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
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
            _immediateInstances.any((i) => now.isAfter(
              i.scheduledTime.add(const Duration(minutes: _graceWindowMinutes)),
            ))
                ? 'Overdue & Due Now'
                : 'Due Now',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
          ),
        ),
        ..._immediateInstances.map((instance) => _buildImmediateItem(instance)),
      ],
    );
  }

  Widget _buildImmediateItem(MedicationInstance instance) {
    final now = DateTime.now();
    final isOverdue = now.isAfter(
      instance.scheduledTime.add(const Duration(minutes: _graceWindowMinutes)),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          left: _getUrgencyBorder(instance),
        ),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            // Large checkbox
            SizedBox(
              width: 28,
              height: 28,
              child: Checkbox(
                value: false,
                onChanged: (_) => _quickMarkAsTaken(instance),
              ),
            ),
            const SizedBox(width: 12),
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
                      Text(
                        instance.medication.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.warning,
                          size: 16,
                          color: Colors.red[700],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    instance.medication.dosage,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
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
            // Action buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => _quickMarkAsTaken(instance),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Mark Taken',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => _openDetailedDialog(instance),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Details',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
          opacity: 0.6,
          child: ListTile(
            leading: Icon(
              Icons.medication,
              color: Colors.grey[600],
            ),
            title: Text(instance.medication.name),
            subtitle: Text(instance.medication.dosage),
            trailing: Text(
              _formatTime(instance.scheduledTime),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
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

        return Container(
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.05),
          ),
          child: ListTile(
            leading: Icon(
              Icons.medication,
              color: Colors.purple[400],
            ),
            title: Text(medication.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medication.dosage),
                const SizedBox(height: 4),
                Text(
                  'Taken: $currentDoses/$maxDoses doses today',
                  style: TextStyle(
                    fontSize: 12,
                    color: canTake ? Colors.green[700] : Colors.red[700],
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
                : Icon(
                    Icons.block,
                    color: Colors.red[400],
                  ),
            onTap: () => _openDetailedDialog(instance),
          ),
        );
      }).toList(),
    );
  }
}
