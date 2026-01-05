import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
      final Box oldBox;
      if (isTypeBox) {
        oldBox = await Hive.openBox(boxName);
      } else {
        oldBox = await Hive.openBox(boxName);
      }

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

      print('Migrated box: $boxName (${data.length} items)');
    } catch (e) {
      print('Error migrating box $boxName: $e');
      rethrow;
    }
  }

  static Future<void> migrateAllBoxes() async {
    if (await isMigrationCompleted()) {
      return;
    }
    final boxesToMigrate = [
      'conditions',
      'medications',
      'profile',
      'medication_logs',
      'feedback',
      'settings',
      'medication_settings',
      'theme',
    ];

    for (final boxName in boxesToMigrate) {
      try {
        await migrateBox(boxName);
      } catch (e) {
        print("Failed to migrate $boxName: $e");
      }
    }

    await markMigrationCompleted();
    print('Migration completed successfully');
  }
}
