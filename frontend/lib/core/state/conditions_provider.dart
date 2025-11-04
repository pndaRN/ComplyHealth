import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import "../models/disease.dart";

final conditionsProvider = NotifierProvider<ConditionsNotifier, List<Disease>>(
  ConditionsNotifier.new,
);

class ConditionsNotifier extends Notifier<List<Disease>> {
  Box? _box;

  @override
  List<Disease> build() {
    _loadConditions();
    return [];
  }

  /// Get or open the Hive box (cached)
  Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox('conditions');
    return _box!;
  }

  Future<void> _loadConditions() async {
    final box = await _getBox();
    final saved = box.values.map((e) => e as Disease).toList();
    state = saved;
  }

  Future<void> addCondition(Disease disease) async {
    final box = await _getBox();
    await box.put(disease.code, disease);
    state = [...state, disease];
  }

  Future<void> removeCondition(Disease disease) async {
    final box = await _getBox();
    await box.delete(disease.code);
    state = state.where((d) => d.code != disease.code).toList();
  }
}
