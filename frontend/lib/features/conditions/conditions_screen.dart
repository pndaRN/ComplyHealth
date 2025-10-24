import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/disease.dart';
import '../../core/services/icd_service.dart';
import '../../core/state/conditions_provider.dart';

class ConditionsScreen extends ConsumerStatefulWidget {
  const ConditionsScreen({super.key});

  @override
  ConsumerState<ConditionsScreen> createState() => _ConditionsScreenState();
}

class _ConditionsScreenState extends ConsumerState<ConditionsScreen> {
  List<Disease> allConditions = [];
  List<Disease> searchResults = [];
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadConditions();
  }

  Future<void> loadConditions() async {
    allConditions = await ICDService.loadAll();
    setState(() {});
  }

  void search(String term) {
    setState(() {
      searchResults = ICDService.search(allConditions, term);
    });
  }

  @override
  Widget build(BuildContext context) {
    final myConditions = ref.watch(conditionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Conditions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              onChanged: search,
              decoration: const InputDecoration(
                labelText: 'Search conditions...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, i) {
                    final disease = searchResults[i];
                    final added = myConditions.any(
                      (d) => d.code == disease.code,
                    );
                    return ListTile(
                      title: Text(disease.name),
                      subtitle: Text('${disease.code} • ${disease.category}'),
                      trailing: IconButton(
                        icon: Icon(
                          added ? Icons.check_circle : Icons.add_circle_outline,
                          color: added ? Colors.green : null,
                        ),
                        onPressed: added
                            ? null
                            : () => ref
                                  .read(conditionsProvider.notifier)
                                  .addCondition(disease),
                      ),
                    );
                  },
                ),
              )
            else if (controller.text.isNotEmpty)
              const Text('No results found.'),
            if (myConditions.isNotEmpty && controller.text.isEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: myConditions.length,
                  itemBuilder: (context, i) {
                    final d = myConditions[i];
                    return ListTile(
                      title: Text(d.name),
                      subtitle: Text(d.code),
                      trailing: IconButton(
                        onPressed: () => ref
                            .read(conditionsProvider.notifier)
                            .removeCondition(d),
                        icon: const Icon(Icons.delete_outlined),
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
