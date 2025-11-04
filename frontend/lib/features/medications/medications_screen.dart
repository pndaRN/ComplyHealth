import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/medication.dart';
import '../../core/state/medication_provider.dart';
import '../../core/state/conditions_provider.dart';
import '../conditions/add_condition_dialog.dart';
import 'dialogs/medication_add_dialog.dart';
import 'dialogs/medication_edit_dialog.dart';

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
                  onTap: () => _showEditDialog(context, m),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) async {
    final conditions = ref.read(conditionsProvider);

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

        // After condition dialog closes, check if conditions were added and reopen
        if (context.mounted) {
          final updatedConditions = ref.read(conditionsProvider);
          if (updatedConditions.isNotEmpty) {
            // Use addPostFrameCallback to ensure clean dialog transition
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                _showAddDialog(context, ref);
              }
            });
          }
        }
      }
      return;
    }

    // Normal flow when conditions exist
    showDialog(
      context: context,
      builder: (context) => const MedicationAddDialog(),
    );
  }

  void _showEditDialog(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (context) => MedicationEditDialog(medication: medication),
    );
  }
}
