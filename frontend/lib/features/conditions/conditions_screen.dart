import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/conditions_provider.dart';
import 'add_condition_dialog.dart';

class ConditionsScreen extends ConsumerWidget {
  const ConditionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myConditions = ref.watch(conditionsProvider);
    final notifier = ref.read(conditionsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Conditions')),
      body: myConditions.isEmpty
          ? const Center(child: Text('No conditions yet.'))
          : ListView.builder(
              itemCount: myConditions.length,
              itemBuilder: (context, i) {
                final condition = myConditions[i];
                return ListTile(
                  title: Text(condition.name),
                  subtitle: Text('${condition.code} • ${condition.category}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => notifier.removeCondition(condition),
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
