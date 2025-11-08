import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/conditions_provider.dart';
import '../../core/state/medication_provider.dart';
import '../../core/models/medication.dart';
import 'add_condition_dialog.dart';

class ConditionsScreen extends ConsumerWidget {
  const ConditionsScreen({super.key});

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
    final myConditions = ref.watch(conditionsProvider);
    final notifier = ref.read(conditionsProvider.notifier);
    final medicationNotifier = ref.read(medicationProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Conditions')),
      body: myConditions.isEmpty
          ? const Center(child: Text('No conditions yet.'))
          : ListView.builder(
              itemCount: myConditions.length,
              itemBuilder: (context, i) {
                final condition = myConditions[i];
                final medications = medicationNotifier.forCondition(condition.name);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ExpansionTile(
                    title: Text(
                      condition.commonName.isNotEmpty ? condition.commonName : condition.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${condition.code} • ${condition.category}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (condition.description.isNotEmpty) ...[
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                condition.description,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Medications (${medications.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (medications.isEmpty)
                              Text(
                                'No medications assigned to this condition.',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            else
                              ...medications.map((med) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.medication, size: 16, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${med.name} - ${med.dosage}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    Text(
                                      _getTimingSummary(med),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Delete'),
                                  onPressed: () => notifier.removeCondition(condition),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddConditionDialog(),
    );
  }
}
