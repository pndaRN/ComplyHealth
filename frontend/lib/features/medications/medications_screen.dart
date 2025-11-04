import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/medication.dart';
import '../../core/state/medication_provider.dart';
import '../../core/state/conditions_provider.dart';
import '../conditions/add_condition_dialog.dart';

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
                  subtitle: Text('For condition: ${m.conditionName}'),
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
  ) async {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    final freqCtrl = TextEditingController();
    final conditions = ref.read(conditionsProvider);
    String? selectCondition;

    if (conditions.isEmpty) {
      // Show simplified dialog to add condition first
      final shouldOpenConditionDialog = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Add Medication'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please add at least one condition first.'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Condition'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      // If user clicked "Add Condition", open the condition dialog
      if (shouldOpenConditionDialog == true && context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => const AddConditionDialog(),
        );

        // After condition dialog closes, check if conditions were added
        if (context.mounted) {
          final updatedConditions = ref.read(conditionsProvider);
          if (updatedConditions.isNotEmpty) {
            // Small delay to ensure dialog is fully closed
            await Future.delayed(const Duration(milliseconds: 100));
            if (context.mounted) {
              _showAddDialog(context, ref, notifier);
            }
          }
        }
      }
      return;
    }

    // Normal flow when conditions exist
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Medication'),
          content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Medication Name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: doseCtrl,
                        decoration: const InputDecoration(labelText: 'Dosage'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: freqCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Frequency',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectCondition,
                        hint: const Text('Select Condition'),
                        items: conditions.map((condition) {
                          return DropdownMenuItem<String>(
                            value: condition.name,
                            child: Text(condition.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectCondition = value;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Condition',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectCondition == null) return;
                final newMedication = Medication(
                  id: const Uuid().v4(),
                  name: nameCtrl.text,
                  dosage: doseCtrl.text,
                  frequency: freqCtrl.text,
                  conditionName: selectCondition!,
                );
                notifier.addMeds(newMedication);
                Navigator.pop(context);
              },
              child: const Text('Add Medication'),
            ),
          ],
        );
      },
    );
  }
}
