import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/core/state/medication_provider.dart';
import 'package:complyhealth/core/theme/status_colors.dart';
import 'package:complyhealth/features/dashboard/utils/todays_medications_utils.dart';

/// Widget displaying the "As Needed" (PRN) medications section.
class PRNSectionWidget extends ConsumerStatefulWidget {
  final List<MedicationInstance> instances;
  final bool initiallyExpanded;
  final VoidCallback onRefresh;
  final void Function(MedicationInstance instance) onItemTap;

  const PRNSectionWidget({
    super.key,
    required this.instances,
    required this.initiallyExpanded,
    required this.onRefresh,
    required this.onItemTap,
  });

  @override
  ConsumerState<PRNSectionWidget> createState() => _PRNSectionWidgetState();
}

class _PRNSectionWidgetState extends ConsumerState<PRNSectionWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  Future<void> _quickMarkAsTaken(MedicationInstance instance) async {
    HapticFeedback.lightImpact();

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
      await ref.read(adherenceProvider.notifier).logDoseTaken(
            medicationId: latestMed.id,
            medicationName: latestMed.name,
            dosage: latestMed.dosage,
            scheduledTime: instance.scheduledTime,
          );

      widget.onRefresh();
    } catch (e) {
      // Rollback dose count on error
      await ref
          .read(medicationProvider.notifier)
          .decrementDoseCount(latestMed);
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log dose: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExpansionTile(
      title: Text(
        'As Needed (${widget.instances.length})',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      initiallyExpanded: _isExpanded,
      onExpansionChanged: (expanded) {
        setState(() => _isExpanded = expanded);
      },
      children: widget.instances.map((instance) {
        final medication = instance.medication;
        final currentDoses = medication.currentDoseCount;
        final maxDoses = medication.maxDailyDoses ?? 0;
        final canTake = currentDoses < maxDoses;
        final doseColor = getDoseCountColor(currentDoses, maxDoses, theme);

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
            onTap: () => widget.onItemTap(instance),
          ),
        );
      }).toList(),
    );
  }
}
