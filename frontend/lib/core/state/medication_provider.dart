import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/medication.dart';
import '../../features/medications/utils/medication_sorter.dart';

final medicationProvider =
    NotifierProvider<MedicationNotifier, List<Medication>>(
      MedicationNotifier.new,
    );

class MedicationNotifier extends Notifier<List<Medication>> {
  Box? _box;
  Box? _settingsBox;
  MedicationSortOption _sortOption = MedicationSortOption.alphabetical;

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

  /// Get or open the settings box (cached)
  Future<Box> _getSettingsBox() async {
    if (_settingsBox != null && _settingsBox!.isOpen) {
      return _settingsBox!;
    }
    _settingsBox = await Hive.openBox('medication_settings');
    return _settingsBox!;
  }

  /// Load sort preference from settings
  Future<void> _loadSortPreference() async {
    final settingsBox = await _getSettingsBox();
    final savedSort = settingsBox.get('sortOption');
    if (savedSort != null && savedSort is int) {
      _sortOption = MedicationSortOption.values[savedSort];
    }
  }

  Future<void> _loadMeds() async {
    await _loadSortPreference();
    final box = await _getBox();
    final meds = box.values.cast<Medication>().toList();
    state = MedicationSorter.sort(meds, _sortOption);
  }

  Future<void> addMeds(Medication med) async {
    final box = await _getBox();
    await box.put(med.id, med);
    final updatedMeds = [...state, med];
    state = MedicationSorter.sort(updatedMeds, _sortOption);
  }

  Future<void> deleteMeds(Medication med) async {
    final box = await _getBox();
    await box.delete(med.id);
    final updatedMeds = state.where((m) => m.id != med.id).toList();
    state = MedicationSorter.sort(updatedMeds, _sortOption);
  }

  Future<void> updateMeds(Medication med) async {
    final box = await _getBox();
    await box.put(med.id, med);
    final updatedMeds = state.map((m) => m.id == med.id ? med : m).toList();
    state = MedicationSorter.sort(updatedMeds, _sortOption);
  }

  /// Change the sort option and re-sort medications
  Future<void> setSortOption(MedicationSortOption option) async {
    _sortOption = option;
    final settingsBox = await _getSettingsBox();
    await settingsBox.put('sortOption', option.index);
    state = MedicationSorter.sort(state, _sortOption);
  }

  /// Get current sort option
  MedicationSortOption get sortOption => _sortOption;

  List<Medication> forCondition(String name) =>
      state.where((m) => m.conditionNames.contains(name)).toList();
}
