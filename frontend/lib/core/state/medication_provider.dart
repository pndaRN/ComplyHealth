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
    checkAndResetDailyCounts();
    return [];
  }

  /// Check if two DateTime objects are on the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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

  /// Increment dose count for a PRN medication
  Future<void> incrementDoseCount(Medication med) async {
    if (!med.isPRN) return;

    final today = DateTime.now();
    int newCount = med.currentDoseCount;
    DateTime? resetDate = med.lastDoseCountReset;

    // Reset if it's a new day
    if (resetDate == null || !_isSameDay(resetDate, today)) {
      newCount = 1;
      resetDate = today;
    } else {
      newCount = med.currentDoseCount + 1;
    }

    final updatedMed = Medication(
      id: med.id,
      name: med.name,
      dosage: med.dosage,
      conditionNames: med.conditionNames,
      isPRN: med.isPRN,
      scheduledTimes: med.scheduledTimes,
      maxDailyDoses: med.maxDailyDoses,
      currentDoseCount: newCount,
      lastDoseCountReset: resetDate,
    );

    await updateMeds(updatedMed);
  }

  /// Decrement dose count for a PRN medication (minimum 0)
  Future<void> decrementDoseCount(Medication med) async {
    if (!med.isPRN || med.currentDoseCount <= 0) return;

    final updatedMed = Medication(
      id: med.id,
      name: med.name,
      dosage: med.dosage,
      conditionNames: med.conditionNames,
      isPRN: med.isPRN,
      scheduledTimes: med.scheduledTimes,
      maxDailyDoses: med.maxDailyDoses,
      currentDoseCount: med.currentDoseCount - 1,
      lastDoseCountReset: med.lastDoseCountReset,
    );

    await updateMeds(updatedMed);
  }

  /// Reset dose count for a PRN medication
  Future<void> resetDoseCount(Medication med) async {
    if (!med.isPRN) return;

    final updatedMed = Medication(
      id: med.id,
      name: med.name,
      dosage: med.dosage,
      conditionNames: med.conditionNames,
      isPRN: med.isPRN,
      scheduledTimes: med.scheduledTimes,
      maxDailyDoses: med.maxDailyDoses,
      currentDoseCount: 0,
      lastDoseCountReset: DateTime.now(),
    );

    await updateMeds(updatedMed);
  }

  /// Check and reset dose counts for PRN medications if it's a new day
  Future<void> checkAndResetDailyCounts() async {
    final today = DateTime.now();
    bool hasUpdates = false;

    final updatedMeds = state.map((med) {
      if (!med.isPRN) return med;

      if (med.lastDoseCountReset == null ||
          !_isSameDay(med.lastDoseCountReset!, today)) {
        hasUpdates = true;
        return Medication(
          id: med.id,
          name: med.name,
          dosage: med.dosage,
          conditionNames: med.conditionNames,
          isPRN: med.isPRN,
          scheduledTimes: med.scheduledTimes,
          maxDailyDoses: med.maxDailyDoses,
          currentDoseCount: 0,
          lastDoseCountReset: today,
        );
      }
      return med;
    }).toList();

    if (hasUpdates) {
      final box = await _getBox();
      for (final med in updatedMeds) {
        if (med.isPRN) {
          await box.put(med.id, med);
        }
      }
      state = MedicationSorter.sort(updatedMeds, _sortOption);
    }
  }
}
