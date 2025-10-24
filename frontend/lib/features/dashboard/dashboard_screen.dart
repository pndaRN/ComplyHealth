import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/conditions_provider.dart';
import '../../core/state/medication_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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
            Text(
              'Conditions: ${conditions.length}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              'Medications: ${meds.length}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            const Text(
              'Summary',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: conditions.length,
                itemBuilder: (context, i) {
                  final c = conditions[i];
                  final related = meds
                      .where((m) => m.conditionCode == c.code)
                      .toList();
                  return Card(
                    child: ListTile(
                      title: Text(c.name),
                      subtitle: related.isEmpty
                          ? const Text('No medications yet')
                          : Text(related.map((m) => m.name).join(', ')),
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
