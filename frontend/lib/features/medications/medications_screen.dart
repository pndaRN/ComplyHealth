import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/medication.dart';
import '../../core/state/medication_provider.dart';
import '../../core/state/conditions_provider.dart';

class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meds = ref.watch(medicationProvider);
    final notifier = ref.read(medicationProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Medications')),
      body: meds.isEmpty
          ? const Center(child: Text('No medications yet.'))
          : ListView.builder(
              itemCount: meds.length,
              itemBuilder: (context, i) {
                final m = meds[i];
                return ListTile(
                  title: Text('${m.name} — ${m.dosage}'),
                  subtitle: Text('For condition: ${m.conditionCode}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => notifier.deleteMeds(m),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref, notifier),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(
    BuildContext context,
    WidgetRef ref,
    MedicationNotifier notifier,
  ) {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    final freqCtrl = TextEditingController();

    final selectedConditions = ref.read(conditionsProvider);
    final icdCodes = selectedConditions.map((c) => c.code).join(', ');
    final condCtrl = TextEditingController(text: icdCodes);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: doseCtrl,
              decoration: const InputDecoration(labelText: 'Dosage'),
            ),
            TextField(
              controller: freqCtrl,
              decoration: const InputDecoration(labelText: 'Frequency'),
            ),
            TextField(
              controller: condCtrl,
              decoration: const InputDecoration(labelText: 'Condition Code'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.addMeds(
                Medication(
                  id: const Uuid().v4(),
                  name: nameCtrl.text,
                  dosage: doseCtrl.text,
                  frequency: freqCtrl.text,
                  conditionCode: condCtrl.text,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
