import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/medication.dart';

final medicationProvider =
    NotifierProvider<MedicationNotifier, List<Medication>>(
      MedicationNotifier.new,
    );

class MedicationNotifier extends Notifier<List<Medication>> {
  @override
  List<Medication> build() {
    _loadMeds();
    return [];
  }

  Future<void> _loadMeds() async {
    final box = await Hive.openBox('medications');
    state = box.values.cast<Medication>().toList();
  }

  Future<void> addMeds(Medication med) async {
    final box = await Hive.openBox('medications');
    await box.put(med.id, med);
    state = [...state, med];
  }

  Future<void> deleteMeds(Medication med) async {
    final box = await Hive.openBox('medications');
    await box.delete(med.id);
    state = state.where((m) => m.id != med.id).toList();
  }

  List<Medication> forCondition(String code) =>
      state.where((m) => m.conditionCode == code).toList();
}
