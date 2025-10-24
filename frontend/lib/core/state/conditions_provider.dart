import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import "../models/disease.dart";

final conditionsProvider = NotifierProvider<ConditionsNotifier, List<Disease>>(
  ConditionsNotifier.new,
);

class ConditionsNotifier extends Notifier<List<Disease>> {
  @override
  List<Disease> build() {
    _loadConditions();
    return [];
  }

  Future<void> _loadConditions() async {
    final box = await Hive.openBox('conditions');
    final saved = box.values.map((e) => e as Disease).toList();
    state = saved;
  }

  Future<void> addCondition(Disease disease) async {
    final box = await Hive.openBox('conditions');
    await box.put(disease.code, disease);
    state = [...state, disease];
  }

  Future<void> removeCondition(Disease disease) async {
    final box = await Hive.openBox('conditions');
    await box.delete(disease.code);
    state = state.where((d) => d.code != disease.code).toList();
  }
}
