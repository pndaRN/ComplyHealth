import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class EncryptionMigrationService {
  static const _secureStorage = FlutterSecureStorage();
  static const _keyName = 'hive_encryption_key';
  static const _migrationFlagKey = 'encryption_migration_completed';

  // Check if migration has already been done
  static Future<bool> isMigrationCompleted() async {
    final flag = await _secureStorage.read(key: _migrationFlagKey);
    return flag == 'true';
  }

  // Mark migration complete
  static Future<void> markMigrationCompleted() async {
    await _secureStorage.write(key: _migrationFlagKey, value: 'true');
  }

  // Get or generate encryption key
  static Future<List<int>> getEncryptionKey() async {
    final existingKey = await _secureStorage.read(key: _keyName);

    if (existingKey != null) {
      return base64Url.decode(existingKey);
    }

    final key = Hive.generateSecureKey();

    await _secureStorage.write(key: _keyName, value: base64Url.encode(key));

    return key;
  }

  // Migrate a single box from unencrypted to encrypted
  static Future<void> migrateBox(
    String boxName, {
    bool isTypeBox = false,
  }) async {
    try {
      // If the box is already open, it's either already migrated or in use.
      // We should close it first to ensure we can delete/migrate it.
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }

      final Box oldBox = await Hive.openBox(boxName);

      if (oldBox.isEmpty) {
        await oldBox.close();
        await Hive.deleteBoxFromDisk(boxName);
        return;
      }

      final data = Map<dynamic, dynamic>.from(oldBox.toMap());

      await oldBox.close();
      await Hive.deleteBoxFromDisk(boxName);

      final encryptionKey = await getEncryptionKey();

      final newBox = await Hive.openBox(
        boxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );

      await newBox.putAll(data);

      await newBox.close();

      debugPrint('Migrated box: $boxName (${data.length} items)');
    } catch (e) {
      debugPrint('Error migrating box $boxName: $e');
      rethrow;
    }
  }

  static const List<String> _allBoxNames = [
    'conditions',
    'medications',
    'profile',
    'medication_logs',
    'feedback',
    'settings',
    'medication_settings',
    'theme',
    'notebook',
  ];

  static Future<void> migrateAllBoxes() async {
    if (await isMigrationCompleted()) {
      return;
    }

    for (final boxName in _allBoxNames) {
      try {
        await migrateBox(boxName);
      } catch (e) {
        debugPrint("Failed to migrate $boxName: $e");
      }
    }

    await markMigrationCompleted();
    debugPrint('Migration completed successfully');
  }

  /// Clears all Hive boxes when data is unrecoverable.
  /// This allows the app to start fresh after corruption.
  static Future<void> clearAllBoxes() async {
    for (final name in _allBoxNames) {
      try {
        if (Hive.isBoxOpen(name)) {
          await Hive.box(name).close();
        }
        await Hive.deleteBoxFromDisk(name);
      } catch (e) {
        debugPrint('Error clearing box $name: $e');
      }
    }
    // Reset migration flag so it runs fresh next time
    try {
      await _secureStorage.delete(key: _migrationFlagKey);
    } catch (e) {
      debugPrint('Error resetting migration flag: $e');
    }
    debugPrint('All boxes cleared for fresh start');
  }
}
