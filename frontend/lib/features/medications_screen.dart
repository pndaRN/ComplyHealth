import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medsync/core/state/medication_provider.dart';
import '../../core/models/medication.dart';
import '../../core/state/medications_provider.dart';

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
                  title: Text('${m.name} - ${m.dosage}'),
                  subtitle: Text('For condition: ${m.conditionCode}'),
                  trailing: IconButton(
                    onPressed: () => notifier.deleteMeds(m),
                    icon: const Icon(Icons.delete_outline),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, notifier),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ADD SHOWaddDialog
