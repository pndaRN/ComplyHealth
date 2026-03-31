import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';
import '../models/disease.dart';
import '../../core/services/encryption_migration_service.dart';
import '../../core/state/auth_provider.dart';

final conditionsProvider =
    AsyncNotifierProvider<ConditionsNotifier, List<Disease>>(
      ConditionsNotifier.new,
    );

class ConditionsNotifier extends AsyncNotifier<List<Disease>> {
  static const String _boxName = 'conditions';

  Future<Box<Disease>> _getBox() async {
    final key = await EncryptionMigrationService.getEncryptionKey();

    if (Hive.isBoxOpen(_boxName)) {
      try {
        // Try to get the box with the expected type first
        try {
          final box = Hive.box<Disease>(_boxName);
          return box;
        } catch (_) {
          // Type mismatch or other error, try to get as dynamic to close it
          final box = Hive.box(_boxName);
          await box.close();
        }
      } catch (_) {
        // If even getting as dynamic failed, try opening as dynamic to get handle and close
        try {
          // This handles the "already open" case by getting the existing instance
          final box = await Hive.openBox(_boxName);
          await box.close();
        } catch (_) {
          // If all else fails, ignore and try to open fresh below
        }
      }
    }

    try {
      return await Hive.openBox<Disease>(
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
      return await Hive.openBox<Disease>(
        _boxName,
        encryptionCipher: HiveAesCipher(key),
      );
    }
  }

  @override
  Future<List<Disease>> build() async {
    final box = await _getBox();
    return box.values.toList();
  }

  Future<void> addCondition(Disease disease) async {
    // Set state to loading to indicate an operation is in progress.
    state = const AsyncValue.loading();
    try {
      final box = await _getBox();
      await box.put(disease.code, disease);
      // After successfully adding, update the state with the new list.
      state = AsyncValue.data(box.values.toList());
      _syncCondition(disease);
    } catch (e, s) {
      // If an error occurs, update the state to reflect the error.
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> removeCondition(Disease disease) async {
    state = const AsyncValue.loading();
    try {
      final box = await _getBox();
      await box.delete(disease.code);
      state = AsyncValue.data(box.values.toList());
      _syncDeleteCondition(disease.code);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateConditionNotes(String code, String notes) async {
    final box = await _getBox();
    final existing = box.get(code);
    if (existing != null) {
      final updated = existing.copyWith(personalNotes: notes);
      await box.put(code, updated);
      state = AsyncValue.data(box.values.toList());
      _syncCondition(updated);
    }
  }

  void _syncCondition(Disease disease) {
    final uid = ref.read(userIdProvider);
    if (uid == null) return;
    ref.read(syncServiceProvider).syncCondition(uid, disease);
  }

  void _syncDeleteCondition(String code) {
    final uid = ref.read(userIdProvider);
    if (uid == null) return;
    ref.read(syncServiceProvider).deleteConditionRemote(uid, code);
  }
}
