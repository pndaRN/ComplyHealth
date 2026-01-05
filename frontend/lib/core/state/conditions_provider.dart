import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import "../models/disease.dart";
import '../../core/services/encryption_migration_service.dart';

final conditionsProvider = NotifierProvider<ConditionsNotifier, List<Disease>>(
  ConditionsNotifier.new,
);

class ConditionsNotifier extends Notifier<List<Disease>> {
  Box? _box;

  @override
  List<Disease> build() {
    _initializeAndLoad();
    return [];
  }

  /// Get or open the Hive box (cached)
  Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }

    final key = await EncryptionMigrationService.getEncryptionKey();
    _box = await Hive.openBox(
      'conditions',
      encryptionCipher: HiveAesCipher(key),
    );
    return _box!;
  }

  /// Initialize and load conditions from Hive
  Future<void> _initializeAndLoad() async {
    await _loadConditions();
  }

  Future<void> _loadConditions() async {
    final box = await _getBox();
    final saved = box.values.map((e) => e as Disease).toList();
    if (saved.isNotEmpty || state.isEmpty) {
      state = saved;
    }
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
