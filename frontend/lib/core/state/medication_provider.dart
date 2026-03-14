import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';
import '../models/medication.dart';
import '../services/notification_service.dart';
import '../services/encryption_migration_service.dart';
import '../../features/medications/utils/medication_sorter.dart';

final medicationProvider =
    AsyncNotifierProvider<MedicationNotifier, List<Medication>>(
      MedicationNotifier.new,
    );

class MedicationNotifier extends AsyncNotifier<List<Medication>> {
  static const String _boxName = 'medications';
  MedicationSortOption _sortOption = MedicationSortOption.alphabetical;
  static bool _hasScheduledInitialNotifications = false;

  Future<Box<Medication>> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      try {
        try {
          final box = Hive.box<Medication>(_boxName);
          return box;
        } catch (_) {
          final box = Hive.box(_boxName);
          await box.close();
        }
      } catch (_) {
        try {
          final box = await Hive.openBox(_boxName);
          await box.close();
        } catch (_) {}
      }
    }
    final key = await EncryptionMigrationService.getEncryptionKey();
    try {
      return await Hive.openBox<Medication>(
        _boxName,
        encryptionCipher: HiveAesCipher(key),
      );
    } catch (e) {
      debugPrint('Failed to open $_boxName: $e - clearing and retrying');
      // Clear corrupted box
      try {
        await Hive.deleteBoxFromDisk(_boxName);
      } catch (_) {}
      // Open fresh empty box
      return await Hive.openBox<Medication>(
        _boxName,
        encryptionCipher: HiveAesCipher(key),
      );
    }
  }

  Future<Box> _getSettingsBox() async {
    if (Hive.isBoxOpen('medication_settings')) {
      return Hive.box('medication_settings');
    }
    return await Hive.openBox('medication_settings');
  }

  @override
  Future<List<Medication>> build() async {
    await _loadSortPreference();
    final box = await _getBox();
    List<Medication> meds = await _checkAndResetDailyCounts(
      box.values.toList(),
    );

    // Only schedule notifications on the first build to prevent duplicates
    // Individual add/update operations will handle their own scheduling
    if (!_hasScheduledInitialNotifications && meds.isNotEmpty) {
      try {
        await NotificationService().cancelAllNotifications();
        await NotificationService().scheduleAllMedications(meds);
        _hasScheduledInitialNotifications = true;
      } catch (e) {
        // Log error but don't fail the build
        print('Failed to schedule initial notifications: $e');
      }
    }

    return _applySorting(meds);
  }

  Future<void> _loadSortPreference() async {
    final settingsBox = await _getSettingsBox();
    final savedSort = settingsBox.get('sortOption');
    if (savedSort != null && savedSort is int) {
      _sortOption = MedicationSortOption.values[savedSort];
    }
  }

  List<Medication> _applySorting(List<Medication> meds) {
    if (_sortOption == MedicationSortOption.groupedByCondition) {
      final sorted = List<Medication>.from(meds);
      sorted.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return sorted;
    } else {
      return MedicationSorter.sort(meds, _sortOption);
    }
  }

  Future<void> addMeds(Medication med) async {
    state = await AsyncValue.guard(() async {
      final box = await _getBox();
      await box.put(med.id, med);
      // Reschedule all notifications to account for the new medication
      try {
        await NotificationService().rescheduleAllNotifications(
          box.values.toList(),
        );
      } catch (e) {
        print('Failed to reschedule notifications (add): $e');
      }
      return _applySorting(box.values.toList());
    });
  }

  Future<void> deleteMeds(Medication med) async {
    state = await AsyncValue.guard(() async {
      final box = await _getBox();
      await box.delete(med.id);
      // Reschedule all notifications to remove the deleted medication from groups
      try {
        await NotificationService().rescheduleAllNotifications(
          box.values.toList(),
        );
      } catch (e) {
        print('Failed to reschedule notifications (delete): $e');
      }
      return _applySorting(box.values.toList());
    });
  }

  Future<void> updateMeds(Medication med) async {
    state = await AsyncValue.guard(() async {
      final box = await _getBox();
      await box.put(med.id, med);
      // Reschedule all notifications to account for schedule changes
      try {
        await NotificationService().rescheduleAllNotifications(
          box.values.toList(),
        );
      } catch (e) {
        print('Failed to reschedule notifications (update): $e');
      }
      return _applySorting(box.values.toList());
    });
  }

  Future<void> updateMedicationNotes(String id, String notes) async {
    final box = await _getBox();
    final existing = box.get(id);
    if (existing != null) {
      final updated = existing.copyWith(personalNotes: notes);
      await box.put(id, updated);
      state = AsyncValue.data(_applySorting(box.values.toList()));
    }
  }

  Future<void> setSortOption(MedicationSortOption option) async {
    state = await AsyncValue.guard(() async {
      _sortOption = option;
      final settingsBox = await _getSettingsBox();
      await settingsBox.put('sortOption', option.index);

      final box = await _getBox();
      return _applySorting(box.values.toList());
    });
  }

  MedicationSortOption get sortOption => _sortOption;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> incrementDoseCount(Medication med) async {
    if (!med.isPRN) return;
    if (!(state.value ?? []).any((m) => m.id == med.id)) {
      throw StateError('Medication not found in provider state');
    }

    final today = DateTime.now();
    int newCount = med.currentDoseCount;
    DateTime? resetDate = med.lastDoseCountReset;

    if (resetDate == null || !_isSameDay(resetDate, today)) {
      newCount = 1;
      resetDate = today;
    } else {
      newCount = med.currentDoseCount + 1;
    }

    if (med.maxDailyDoses != null && newCount > med.maxDailyDoses!) {
      throw StateError('Dose count would exceed maximum daily doses');
    }

    final updatedMed = med.copyWith(
      currentDoseCount: newCount,
      lastDoseCountReset: resetDate,
    );
    await updateMeds(updatedMed);
  }

  Future<void> decrementDoseCount(Medication med) async {
    if (!med.isPRN || med.currentDoseCount <= 0) return;
    final updatedMed = med.copyWith(currentDoseCount: med.currentDoseCount - 1);
    await updateMeds(updatedMed);
  }

  Future<void> resetDoseCount(Medication med) async {
    if (!med.isPRN) return;
    final updatedMed = med.copyWith(
      currentDoseCount: 0,
      lastDoseCountReset: DateTime.now(),
    );
    await updateMeds(updatedMed);
  }

  Future<List<Medication>> _checkAndResetDailyCounts(
    List<Medication> initialMeds,
  ) async {
    final today = DateTime.now();
    bool hasUpdates = false;

    // Build a map for O(1) lookup of original dose counts
    final originalCounts = <String, int>{
      for (final med in initialMeds) med.id: med.currentDoseCount,
    };

    final updatedMeds = initialMeds.map((med) {
      if (med.isPRN &&
          (med.lastDoseCountReset == null ||
              !_isSameDay(med.lastDoseCountReset!, today))) {
        hasUpdates = true;
        return med.copyWith(currentDoseCount: 0, lastDoseCountReset: today);
      }
      return med;
    }).toList();

    if (hasUpdates) {
      final box = await _getBox();
      for (final med in updatedMeds) {
        // O(1) lookup instead of O(n) firstWhere
        if (originalCounts[med.id] != med.currentDoseCount) {
          await box.put(med.id, med);
        }
      }
      return updatedMeds;
    }
    return initialMeds;
  }
}
