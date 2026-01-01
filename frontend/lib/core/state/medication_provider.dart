import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/medication.dart';
import '../services/notification_service.dart';
import '../services/encryption_migration_service.dart';
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
    _initializeAndLoad();
    return [];
  }

  /// Initialize and load medications from Hive
  Future<void> _initializeAndLoad() async {
    await _loadMeds();
    await checkAndResetDailyCounts();
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

    final key = await EncryptionMigrationService.getEncryptionKey();

    _box = await Hive.openBox(
      'medications',
      encryptionCipher: HiveAesCipher(key),
      );
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

  /// Apply sorting to medications, handling grouped view specially
  List<Medication> _applySorting(List<Medication> meds) {
    if (_sortOption == MedicationSortOption.groupedByCondition) {
      // Just sort alphabetically for grouped view - UI will create condition groups
      final sorted = List<Medication>.from(meds);
      sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return sorted;
    } else {
      return MedicationSorter.sort(meds, _sortOption);
    }
  }

  Future<void> _loadMeds() async {
    await _loadSortPreference();
    final box = await _getBox();
    final meds = box.values.cast<Medication>().toList();

    // Only update state if we have data or state is empty
    if (meds.isNotEmpty || state.isEmpty) {
      state = _applySorting(meds);
    }

    // Schedule notifications for all medications
    if (meds.isNotEmpty) {
      await NotificationService().scheduleAllMedications(meds);
    }
  }

  Future<void> addMeds(Medication med) async {
    final box = await _getBox();
    await box.put(med.id, med);

    // Get all unique medications from Hive to avoid duplicates
    final uniqueMeds = box.values.cast<Medication>().toList();
    state = _applySorting(uniqueMeds);

    // Schedule notifications for the new medication
    await NotificationService().scheduleMedicationNotifications(med);
  }

  Future<void> deleteMeds(Medication med) async {
    final box = await _getBox();
    await box.delete(med.id);

    // Get all unique medications from Hive to avoid duplicates
    final uniqueMeds = box.values.cast<Medication>().toList();
    state = _applySorting(uniqueMeds);

    // Cancel notifications for the deleted medication
    await NotificationService().cancelMedicationNotifications(med.id);
  }

  Future<void> updateMeds(Medication med) async {
    final box = await _getBox();
    await box.put(med.id, med);

    // Get all unique medications from Hive to avoid duplicates
    final uniqueMeds = box.values.cast<Medication>().toList();
    state = _applySorting(uniqueMeds);

    // Re-schedule notifications for the updated medication
    await NotificationService().scheduleMedicationNotifications(med);
  }

  /// Change the sort option and re-sort medications
  Future<void> setSortOption(MedicationSortOption option) async {
    _sortOption = option;
    final settingsBox = await _getSettingsBox();
    await settingsBox.put('sortOption', option.index);

    // Always sort from the unique medications in Hive, not from state
    // This prevents duplication when switching between sort options
    final box = await _getBox();
    final uniqueMeds = box.values.cast<Medication>().toList();
    state = _applySorting(uniqueMeds);
  }

  /// Get current sort option
  MedicationSortOption get sortOption => _sortOption;

  List<Medication> forCondition(String name) =>
      state.where((m) => m.conditionNames.contains(name)).toList();

  /// Increment dose count for a PRN medication
  Future<void> incrementDoseCount(Medication med) async {
    if (!med.isPRN) return;

    // Verify medication still exists in state
    if (!state.any((m) => m.id == med.id)) {
      throw StateError('Medication not found in provider state');
    }

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

    // Validate against max doses
    if (med.maxDailyDoses != null && newCount > med.maxDailyDoses!) {
      throw StateError('Dose count would exceed maximum daily doses');
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
    final box = await _getBox();
    bool hasUpdates = false;

    // Get unique medications from Hive to avoid duplicates
    final uniqueMeds = box.values.cast<Medication>().toList();

    final updatedMeds = uniqueMeds.map((med) {
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
      for (final med in updatedMeds) {
        if (med.isPRN) {
          await box.put(med.id, med);
        }
      }
      state = _applySorting(updatedMeds);
    }
  }
}
