import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/medication.dart';

final medicationProvider =
    NotifierProvider<MedicationNotifier, List<Medication>>(
      MedicationNotifier.new,
    );

class MedicationNotifier extends Notifier<List<Medication>> {
  Box? _box;

  @override
  List<Medication> build() {
    _loadMeds();
    return [];
  }

  /// Get or open the Hive box (cached)
  Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox('medications');
    return _box!;
  }

  Future<void> _loadMeds() async {
    final box = await _getBox();
    state = box.values.cast<Medication>().toList();
  }

  Future<void> addMeds(Medication med) async {
    final box = await _getBox();
    await box.put(med.id, med);
    state = [...state, med];
  }

  Future<void> deleteMeds(Medication med) async {
    final box = await _getBox();
    await box.delete(med.id);
    state = state.where((m) => m.id != med.id).toList();
  }

  Future<void> updateMeds(Medication med) async {
    final box = await _getBox();
    await box.put(med.id, med);
    state = state.map((m) => m.id == med.id ? med : m).toList();
  }

  List<Medication> forCondition(String name) =>
      state.where((m) => m.conditionNames.contains(name)).toList();
}
