import 'package:flutter/material.dart';
import 'package:complyhealth/core/state/adherence_provider.dart';
import 'package:complyhealth/features/dashboard/utils/todays_medications_utils.dart';

/// Widget displaying the "Later Today" section with upcoming medications.
class LaterSectionWidget extends StatefulWidget {
  final List<MedicationInstance> instances;
  final bool initiallyExpanded;
  final void Function(MedicationInstance instance) onItemTap;

  const LaterSectionWidget({
    super.key,
    required this.instances,
    required this.initiallyExpanded,
    required this.onItemTap,
  });

  @override
  State<LaterSectionWidget> createState() => _LaterSectionWidgetState();
}

class _LaterSectionWidgetState extends State<LaterSectionWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Later Today (${widget.instances.length})',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      initiallyExpanded: _isExpanded,
      onExpansionChanged: (expanded) {
        setState(() => _isExpanded = expanded);
      },
      children: widget.instances.map((instance) {
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
              formatMedicationTime(instance.scheduledTime),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            onTap: () => widget.onItemTap(instance),
          ),
        );
      }).toList(),
    );
  }
}
