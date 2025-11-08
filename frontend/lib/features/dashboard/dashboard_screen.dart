import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/conditions_provider.dart';
import '../../core/state/medication_provider.dart';
import '../../core/models/medication.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getTimingSummary(Medication medication) {
    if (medication.isPRN) {
      return 'PRN';
    }
    final count = medication.scheduledTimes.length;
    if (count == 0) return 'No schedule';
    if (count == 1) return 'Once daily';
    return '${count}x daily';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditions = ref.watch(conditionsProvider);
    final meds = ref.watch(medicationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: conditions.length,
                itemBuilder: (context, i) {
                  final c = conditions[i];
                  final related = meds
                      .where((m) => m.conditionNames.contains(c.name))
                      .toList();
                  return Card(
                    child: ListTile(
                      title: Text(c.name),
                      subtitle: related.isEmpty
                          ? const Text('No medications yet')
                          : Text(
                              related
                                  .map(
                                    (m) =>
                                        '${m.name} - ${m.dosage} - ${_getTimingSummary(m)}',
                                  )
                                  .join('\n'),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
