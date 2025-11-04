import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/disease.dart';
import '../../core/services/icd_service.dart';
import '../../core/state/conditions_provider.dart';

class AddConditionDialog extends ConsumerStatefulWidget {
  const AddConditionDialog({super.key});

  @override
  ConsumerState<AddConditionDialog> createState() => _AddConditionDialogState();
}

class _AddConditionDialogState extends ConsumerState<AddConditionDialog> {
  List<Disease> allConditions = [];
  List<Disease> searchResults = [];
  final TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadConditions();
  }

  Future<void> loadConditions() async {
    allConditions = await ICDService.loadAll();
    setState(() {
      isLoading = false;
    });
  }

  void search(String term) {
    setState(() {
      searchResults = ICDService.search(allConditions, term);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Condition'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: search,
                    decoration: const InputDecoration(
                      labelText: 'Search conditions...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: searchResults.isEmpty
                        ? Center(
                            child: Text(
                              searchController.text.isEmpty
                                  ? 'Start typing to search conditions'
                                  : 'No results found',
                            ),
                          )
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, i) {
                              final disease = searchResults[i];
                              return _ConditionListItem(disease: disease);
                            },
                          ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

/// Separate widget for list items that only rebuilds when conditions change
class _ConditionListItem extends ConsumerWidget {
  final Disease disease;

  const _ConditionListItem({required this.disease});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myConditions = ref.watch(conditionsProvider);
    final isAdded = myConditions.any((d) => d.code == disease.code);

    return ListTile(
      title: Text(disease.name),
      subtitle: Text(
        '${disease.code} • ${disease.category}',
      ),
      trailing: IconButton(
        icon: Icon(
          isAdded ? Icons.check_circle : Icons.add_circle_outline,
          color: isAdded ? Colors.green : null,
        ),
        onPressed: () {
          final notifier = ref.read(conditionsProvider.notifier);
          if (isAdded) {
            notifier.removeCondition(disease);
          } else {
            notifier.addCondition(disease);
          }
        },
      ),
    );
  }
}
