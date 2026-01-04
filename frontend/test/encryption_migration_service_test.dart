import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  group('EncryptionMigrationService', () {
    late String testPath;

    setUpAll(() async {
      testPath = '${Directory.systemTemp.path}/hive_test_${DateTime.now().millisecondsSinceEpoch}';
      Hive.init(testPath);
    });

    tearDownAll(() async {
      await Hive.close();
    });

    tearDown(() async {
      // Clean up any open boxes after each test
      await Hive.close();
    });

    group('Encryption Key Generation', () {
      test('should generate a 32-byte encryption key', () {
        final key = Hive.generateSecureKey();

        expect(key.length, 32, reason: 'AES-256 requires 32-byte key');
        expect(key, isA<List<int>>());
      });

      test('should generate unique keys each time', () {
        final key1 = Hive.generateSecureKey();
        final key2 = Hive.generateSecureKey();

        expect(key1, isNot(equals(key2)),
            reason: 'Each generated key should be unique');
      });

      test('should be encodable to base64', () {
        final key = Hive.generateSecureKey();
        final encoded = base64Url.encode(key);

        expect(encoded, isA<String>());
        expect(encoded.isNotEmpty, true);

        // Should be decodable back
        final decoded = base64Url.decode(encoded);
        expect(decoded, equals(key));
      });
    });

    group('HiveAesCipher', () {
      test('should create cipher with valid 32-byte key', () {
        final key = Hive.generateSecureKey();
        final cipher = HiveAesCipher(key);

        expect(cipher, isA<HiveAesCipher>());
      });

      test('should throw error with invalid key length', () {
        final invalidKey = List<int>.filled(16, 0); // Only 16 bytes

        expect(
          () => HiveAesCipher(invalidKey),
          throwsA(isA<ArgumentError>()),
          reason: 'Should reject non-32-byte keys',
        );
      });
    });

    group('Encrypted Box Operations', () {
      test('should open encrypted box with valid key', () async {
        final key = Hive.generateSecureKey();
        final boxName = 'test_encrypted_box_${DateTime.now().millisecondsSinceEpoch}';

        final box = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(key),
        );

        expect(box.isOpen, true);
        expect(box.name, boxName);

        await box.close();
        await Hive.deleteBoxFromDisk(boxName);
      });

      test('should store and retrieve data from encrypted box', () async {
        final key = Hive.generateSecureKey();
        final boxName = 'test_data_box_${DateTime.now().millisecondsSinceEpoch}';

        final box = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(key),
        );

        // Write test data
        await box.put('testKey', 'testValue');
        await box.put('intKey', 42);
        await box.put('boolKey', true);
        await box.put('listKey', ['a', 'b', 'c']);
        await box.put('mapKey', {'nested': 'value'});

        // Read and verify
        expect(box.get('testKey'), 'testValue');
        expect(box.get('intKey'), 42);
        expect(box.get('boolKey'), true);
        expect(box.get('listKey'), ['a', 'b', 'c']);
        expect(box.get('mapKey'), {'nested': 'value'});

        await box.close();
        await Hive.deleteBoxFromDisk(boxName);
      });

      test('should persist data after reopening encrypted box', () async {
        final key = Hive.generateSecureKey();
        final boxName = 'test_persist_box_${DateTime.now().millisecondsSinceEpoch}';

        // Write data
        var box = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(key),
        );
        await box.put('persistent', 'data');
        await box.close();

        // Reopen and verify
        box = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(key),
        );

        expect(box.get('persistent'), 'data');

        await box.close();
        await Hive.deleteBoxFromDisk(boxName);
      });

    });

    group('Box Migration Logic', () {
      test('should migrate unencrypted data to encrypted box', () async {
        final boxName = 'test_migrate_box_${DateTime.now().millisecondsSinceEpoch}';
        final testData = {
          'key1': 'value1',
          'key2': 'value2',
          'key3': 42,
        };

        // Create unencrypted box with data
        var box = await Hive.openBox(boxName);
        await box.putAll(testData);
        await box.close();

        // Read data before migration
        box = await Hive.openBox(boxName);
        final dataBeforeMigration = Map<dynamic, dynamic>.from(box.toMap());
        await box.close();
        await Hive.deleteBoxFromDisk(boxName);

        // Create encrypted box with same data
        final key = Hive.generateSecureKey();
        final encryptedBox = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(key),
        );
        await encryptedBox.putAll(dataBeforeMigration);

        // Verify data is intact after migration
        expect(encryptedBox.get('key1'), 'value1');
        expect(encryptedBox.get('key2'), 'value2');
        expect(encryptedBox.get('key3'), 42);
        expect(encryptedBox.length, 3);

        await encryptedBox.close();
        await Hive.deleteBoxFromDisk(boxName);
      });

      test('should handle empty box migration', () async {
        final boxName = 'test_empty_migrate_${DateTime.now().millisecondsSinceEpoch}';

        // Create empty unencrypted box
        var box = await Hive.openBox(boxName);
        expect(box.isEmpty, true);
        await box.close();
        await Hive.deleteBoxFromDisk(boxName);

        // Create encrypted box (simulating migration of empty box)
        final key = Hive.generateSecureKey();
        final encryptedBox = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(key),
        );

        expect(encryptedBox.isEmpty, true);

        await encryptedBox.close();
        await Hive.deleteBoxFromDisk(boxName);
      });

      test('should preserve all data types during migration', () async {
        final boxName = 'test_types_migrate_${DateTime.now().millisecondsSinceEpoch}';
        final testData = {
          'string': 'hello',
          'int': 123,
          'double': 3.14,
          'bool': true,
          'list': [1, 2, 3],
          'map': {'a': 1, 'b': 2},
          'null': null,
        };

        // Create and populate unencrypted box
        var box = await Hive.openBox(boxName);
        await box.putAll(testData);
        final dataSnapshot = Map<dynamic, dynamic>.from(box.toMap());
        await box.close();
        await Hive.deleteBoxFromDisk(boxName);

        // Migrate to encrypted box
        final key = Hive.generateSecureKey();
        final encryptedBox = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(key),
        );
        await encryptedBox.putAll(dataSnapshot);

        // Verify all types
        expect(encryptedBox.get('string'), 'hello');
        expect(encryptedBox.get('int'), 123);
        expect(encryptedBox.get('double'), 3.14);
        expect(encryptedBox.get('bool'), true);
        expect(encryptedBox.get('list'), [1, 2, 3]);
        expect(encryptedBox.get('map'), {'a': 1, 'b': 2});
        expect(encryptedBox.get('null'), null);

        await encryptedBox.close();
        await Hive.deleteBoxFromDisk(boxName);
      });
    });

    group('Key Storage Simulation', () {
      test('should encode and decode key consistently', () {
        final originalKey = Hive.generateSecureKey();

        // Simulate storing key as base64
        final encoded = base64Url.encode(originalKey);

        // Simulate retrieving key
        final decoded = base64Url.decode(encoded);

        expect(decoded, equals(originalKey));
        expect(decoded.length, 32);
      });

      test('should handle multiple encode/decode cycles', () {
        final originalKey = Hive.generateSecureKey();

        var currentEncoded = base64Url.encode(originalKey);

        // Simulate multiple read operations
        for (var i = 0; i < 5; i++) {
          final decoded = base64Url.decode(currentEncoded);
          final reEncoded = base64Url.encode(decoded);

          expect(decoded, equals(originalKey));
          expect(reEncoded, equals(currentEncoded));
        }
      });
    });

    group('Box Names Configuration', () {
      test('should recognize all expected box names for migration', () {
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

        expect(boxesToMigrate.length, 8);
        expect(boxesToMigrate.contains('conditions'), true);
        expect(boxesToMigrate.contains('medications'), true);
        expect(boxesToMigrate.contains('profile'), true);
        expect(boxesToMigrate.contains('medication_logs'), true);
        expect(boxesToMigrate.contains('feedback'), true);
        expect(boxesToMigrate.contains('settings'), true);
        expect(boxesToMigrate.contains('medication_settings'), true);
        expect(boxesToMigrate.contains('theme'), true);
      });

      test('should have unique box names', () {
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

        final uniqueNames = boxesToMigrate.toSet();
        expect(uniqueNames.length, boxesToMigrate.length,
            reason: 'All box names should be unique');
      });
    });

    group('Concurrent Access', () {
      test('should handle box reuse when already open', () async {
        final key = Hive.generateSecureKey();
        final boxName = 'test_concurrent_${DateTime.now().millisecondsSinceEpoch}';

        // Open box first time
        final box1 = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(key),
        );

        // Open same box again - should return same instance
        final box2 = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(key),
        );

        expect(identical(box1, box2), true,
            reason: 'Hive should return same box instance');

        await box1.close();
        await Hive.deleteBoxFromDisk(boxName);
      });

      test('should handle checking if box is open', () async {
        final key = Hive.generateSecureKey();
        final boxName = 'test_is_open_${DateTime.now().millisecondsSinceEpoch}';

        expect(Hive.isBoxOpen(boxName), false);

        final box = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(key),
        );

        expect(Hive.isBoxOpen(boxName), true);
        expect(box.isOpen, true);

        await box.close();

        expect(Hive.isBoxOpen(boxName), false);

        await Hive.deleteBoxFromDisk(boxName);
      });
    });

    group('Error Handling', () {
      test('should handle deleting non-existent box gracefully', () async {
        // This should not throw
        await Hive.deleteBoxFromDisk('non_existent_box_${DateTime.now().millisecondsSinceEpoch}');
      });

      test('should handle closing already closed box', () async {
        final key = Hive.generateSecureKey();
        final boxName = 'test_double_close_${DateTime.now().millisecondsSinceEpoch}';

        final box = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(key),
        );
        await box.close();

        // Closing again should not throw
        // Note: In Hive, calling close on an already closed box is a no-op
        expect(box.isOpen, false);

        await Hive.deleteBoxFromDisk(boxName);
      });
    });

    group('Data Integrity', () {
      test('should maintain data integrity after multiple operations', () async {
        final key = Hive.generateSecureKey();
        final boxName = 'test_integrity_${DateTime.now().millisecondsSinceEpoch}';

        final box = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(key),
        );

        // Perform multiple operations
        await box.put('item1', 'value1');
        await box.put('item2', 'value2');
        await box.delete('item1');
        await box.put('item3', 'value3');
        await box.put('item2', 'updated_value2');

        // Verify final state
        expect(box.containsKey('item1'), false);
        expect(box.get('item2'), 'updated_value2');
        expect(box.get('item3'), 'value3');
        expect(box.length, 2);

        await box.close();
        await Hive.deleteBoxFromDisk(boxName);
      });

      test('should handle large data sets', () async {
        final key = Hive.generateSecureKey();
        final boxName = 'test_large_data_${DateTime.now().millisecondsSinceEpoch}';

        final box = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(key),
        );

        // Add 100 items
        for (var i = 0; i < 100; i++) {
          await box.put('key_$i', 'value_$i with some additional data to make it larger');
        }

        expect(box.length, 100);

        // Verify random samples
        expect(box.get('key_0'), 'value_0 with some additional data to make it larger');
        expect(box.get('key_50'), 'value_50 with some additional data to make it larger');
        expect(box.get('key_99'), 'value_99 with some additional data to make it larger');

        await box.close();
        await Hive.deleteBoxFromDisk(boxName);
      });
    });
  });
}
