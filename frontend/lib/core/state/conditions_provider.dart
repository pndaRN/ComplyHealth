import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/disease.dart';
import '../../core/services/encryption_migration_service.dart';

final conditionsProvider =
    AsyncNotifierProvider<ConditionsNotifier, List<Disease>>(
  ConditionsNotifier.new,
);

class ConditionsNotifier extends AsyncNotifier<List<Disease>> {
  Future<Box<Disease>> _getBox() async {
    final key = await EncryptionMigrationService.getEncryptionKey();
    // The box might already be open from a previous operation.
    if (Hive.isBoxOpen('conditions')) {
      return Hive.box('conditions');
    }
    return await Hive.openBox<Disease>(
      'conditions',
      encryptionCipher: HiveAesCipher(key),
    );
  }

  @override
  Future<List<Disease>> build() async {
    state = const AsyncValue.loading();
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
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
