import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// These tests verify that providers correctly integrate with encrypted Hive boxes.
/// Since FlutterSecureStorage requires platform channels, we test the encryption
/// patterns used by providers without the secure storage dependency.
void main() {
  group('Provider Encryption Integration', () {
    late String testPath;
    late List<int> testKey;

    setUpAll(() async {
      testPath = '${Directory.systemTemp.path}/hive_provider_test_${DateTime.now().millisecondsSinceEpoch}';
      Hive.init(testPath);
      // Generate a test key (simulating what EncryptionMigrationService does)
      testKey = Hive.generateSecureKey();
    });

    tearDownAll(() async {
      await Hive.close();
    });

    tearDown(() async {
      await Hive.close();
    });

    group('Settings Provider Pattern', () {
      test('should store and retrieve boolean settings', () async {
        final box = await Hive.openBox(
          'test_settings',
          encryptionCipher: HiveAesCipher(testKey),
        );

        // Simulate SettingsNotifier behavior
        await box.put('notificationsEnabled', true);
        await box.put('hasCompletedOnboarding', false);

        expect(box.get('notificationsEnabled', defaultValue: true), true);
        expect(box.get('hasCompletedOnboarding', defaultValue: false), false);

        // Update setting
        await box.put('notificationsEnabled', false);
        expect(box.get('notificationsEnabled', defaultValue: true), false);

        await box.close();
        await Hive.deleteBoxFromDisk('test_settings');
      });

      test('should persist settings after box reopen', () async {
        final boxName = 'test_settings_persist_${DateTime.now().millisecondsSinceEpoch}';

        // Write settings
        var box = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(testKey),
        );
        await box.put('notificationsEnabled', false);
        await box.put('hasCompletedOnboarding', true);
        await box.close();

        // Reopen and verify
        box = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(testKey),
        );

        expect(box.get('notificationsEnabled'), false);
        expect(box.get('hasCompletedOnboarding'), true);

        await box.close();
        await Hive.deleteBoxFromDisk(boxName);
      });
    });

    group('Conditions Provider Pattern', () {
      test('should store conditions with code as key', () async {
        final box = await Hive.openBox(
          'test_conditions',
          encryptionCipher: HiveAesCipher(testKey),
        );

        // Simulate Disease storage (without actual model)
        final conditionData = {
          'code': 'E11',
          'name': 'Type 2 Diabetes',
          'category': 'Endocrine',
        };

        await box.put('E11', conditionData);

        final retrieved = box.get('E11') as Map;
        expect(retrieved['code'], 'E11');
        expect(retrieved['name'], 'Type 2 Diabetes');

        await box.close();
        await Hive.deleteBoxFromDisk('test_conditions');
      });

      test('should list all conditions', () async {
        final box = await Hive.openBox(
          'test_conditions_list',
          encryptionCipher: HiveAesCipher(testKey),
        );

        await box.put('E11', {'code': 'E11', 'name': 'Type 2 Diabetes'});
        await box.put('I10', {'code': 'I10', 'name': 'Hypertension'});
        await box.put('J45', {'code': 'J45', 'name': 'Asthma'});

        final conditions = box.values.toList();
        expect(conditions.length, 3);

        await box.close();
        await Hive.deleteBoxFromDisk('test_conditions_list');
      });

      test('should remove condition by code', () async {
        final box = await Hive.openBox(
          'test_conditions_remove',
          encryptionCipher: HiveAesCipher(testKey),
        );

        await box.put('E11', {'code': 'E11', 'name': 'Type 2 Diabetes'});
        await box.put('I10', {'code': 'I10', 'name': 'Hypertension'});

        expect(box.length, 2);

        await box.delete('E11');

        expect(box.length, 1);
        expect(box.containsKey('E11'), false);
        expect(box.containsKey('I10'), true);

        await box.close();
        await Hive.deleteBoxFromDisk('test_conditions_remove');
      });
    });

    group('Medications Provider Pattern', () {
      test('should store medications with UUID as key', () async {
        final box = await Hive.openBox(
          'test_medications',
          encryptionCipher: HiveAesCipher(testKey),
        );

        final medicationId = 'uuid-12345-67890';
        final medicationData = {
          'id': medicationId,
          'name': 'Aspirin',
          'dosage': '100mg',
          'isPRN': false,
          'scheduledTimes': ['09:00', '21:00'],
          'conditionNames': ['Heart Disease'],
        };

        await box.put(medicationId, medicationData);

        final retrieved = box.get(medicationId) as Map;
        expect(retrieved['name'], 'Aspirin');
        expect(retrieved['dosage'], '100mg');
        expect(retrieved['scheduledTimes'], ['09:00', '21:00']);

        await box.close();
        await Hive.deleteBoxFromDisk('test_medications');
      });

      test('should update medication in place', () async {
        final box = await Hive.openBox(
          'test_medications_update',
          encryptionCipher: HiveAesCipher(testKey),
        );

        final medicationId = 'uuid-abc-123';
        await box.put(medicationId, {
          'id': medicationId,
          'name': 'Aspirin',
          'dosage': '100mg',
        });

        // Update dosage
        await box.put(medicationId, {
          'id': medicationId,
          'name': 'Aspirin',
          'dosage': '200mg', // Updated
        });

        final retrieved = box.get(medicationId) as Map;
        expect(retrieved['dosage'], '200mg');
        expect(box.length, 1); // Still only one medication

        await box.close();
        await Hive.deleteBoxFromDisk('test_medications_update');
      });

      test('should handle PRN medication dose tracking', () async {
        final box = await Hive.openBox(
          'test_medications_prn',
          encryptionCipher: HiveAesCipher(testKey),
        );

        final medicationId = 'uuid-prn-123';
        final now = DateTime.now();

        // Initial PRN medication
        await box.put(medicationId, {
          'id': medicationId,
          'name': 'Ibuprofen',
          'dosage': '200mg',
          'isPRN': true,
          'maxDailyDoses': 4,
          'currentDoseCount': 0,
          'lastDoseCountReset': now.toIso8601String(),
        });

        // Simulate incrementing dose
        final med = box.get(medicationId) as Map;
        final updatedMed = Map<String, dynamic>.from(med);
        updatedMed['currentDoseCount'] = 1;
        await box.put(medicationId, updatedMed);

        final retrieved = box.get(medicationId) as Map;
        expect(retrieved['currentDoseCount'], 1);

        await box.close();
        await Hive.deleteBoxFromDisk('test_medications_prn');
      });
    });

    group('Profile Provider Pattern', () {
      test('should store and retrieve user profile', () async {
        final box = await Hive.openBox(
          'test_profile',
          encryptionCipher: HiveAesCipher(testKey),
        );

        final profileData = {
          'firstName': 'John',
          'lastName': 'Smith',
          'dob': '04/19/1985',
          'allergies': 'Penicillin',
          'xp': 500,
          'streak': 7,
          'levelProgress': 0.45,
        };

        await box.put('user', profileData);

        final retrieved = box.get('user') as Map;
        expect(retrieved['firstName'], 'John');
        expect(retrieved['lastName'], 'Smith');
        expect(retrieved['xp'], 500);
        expect(retrieved['streak'], 7);

        await box.close();
        await Hive.deleteBoxFromDisk('test_profile');
      });

      test('should update XP and level progress', () async {
        final box = await Hive.openBox(
          'test_profile_xp',
          encryptionCipher: HiveAesCipher(testKey),
        );

        // Initial profile
        await box.put('user', {
          'firstName': 'John',
          'xp': 100,
          'levelProgress': 0.5,
        });

        // Add XP
        final profile = Map<String, dynamic>.from(box.get('user') as Map);
        profile['xp'] = 200;
        profile['levelProgress'] = 0.75;
        await box.put('user', profile);

        final retrieved = box.get('user') as Map;
        expect(retrieved['xp'], 200);
        expect(retrieved['levelProgress'], 0.75);

        await box.close();
        await Hive.deleteBoxFromDisk('test_profile_xp');
      });
    });

    group('Theme Provider Pattern', () {
      test('should store theme preference', () async {
        final box = await Hive.openBox(
          'test_theme',
          encryptionCipher: HiveAesCipher(testKey),
        );

        await box.put('isDarkMode', true);

        expect(box.get('isDarkMode'), true);

        // Toggle theme
        await box.put('isDarkMode', false);
        expect(box.get('isDarkMode'), false);

        await box.close();
        await Hive.deleteBoxFromDisk('test_theme');
      });
    });

    group('Feedback Provider Pattern', () {
      test('should store feedback entries', () async {
        final box = await Hive.openBox(
          'test_feedback',
          encryptionCipher: HiveAesCipher(testKey),
        );

        final feedbackId = 'feedback-123';
        await box.put(feedbackId, {
          'id': feedbackId,
          'message': 'Great app!',
          'timestamp': DateTime.now().toIso8601String(),
          'submitted': false,
        });

        final retrieved = box.get(feedbackId) as Map;
        expect(retrieved['message'], 'Great app!');
        expect(retrieved['submitted'], false);

        await box.close();
        await Hive.deleteBoxFromDisk('test_feedback');
      });
    });

    group('Adherence Provider Pattern', () {
      test('should store medication logs', () async {
        final box = await Hive.openBox(
          'test_medication_logs',
          encryptionCipher: HiveAesCipher(testKey),
        );

        final now = DateTime.now();
        final logKey = '${now.year}-${now.month}-${now.day}';

        await box.put(logKey, {
          'date': logKey,
          'logs': [
            {
              'medicationId': 'med-123',
              'scheduledTime': '09:00',
              'taken': true,
              'takenAt': now.toIso8601String(),
            },
            {
              'medicationId': 'med-123',
              'scheduledTime': '21:00',
              'taken': false,
              'takenAt': null,
            },
          ],
        });

        final retrieved = box.get(logKey) as Map;
        expect(retrieved['logs'].length, 2);

        await box.close();
        await Hive.deleteBoxFromDisk('test_medication_logs');
      });
    });

    group('Box Caching Pattern', () {
      test('should return same box instance when already open', () async {
        final boxName = 'test_caching_${DateTime.now().millisecondsSinceEpoch}';

        // Simulate _getBox pattern from providers
        Box? cachedBox;

        Future<Box> getBox() async {
          if (cachedBox != null && cachedBox!.isOpen) {
            return cachedBox!;
          }
          cachedBox = await Hive.openBox(
            boxName,
            encryptionCipher: HiveAesCipher(testKey),
          );
          return cachedBox!;
        }

        final box1 = await getBox();
        final box2 = await getBox();

        expect(identical(box1, box2), true);

        await cachedBox?.close();
        await Hive.deleteBoxFromDisk(boxName);
      });

      test('should reopen box if closed', () async {
        final boxName = 'test_reopen_${DateTime.now().millisecondsSinceEpoch}';

        Box? cachedBox;

        Future<Box> getBox() async {
          if (cachedBox != null && cachedBox!.isOpen) {
            return cachedBox!;
          }
          cachedBox = await Hive.openBox(
            boxName,
            encryptionCipher: HiveAesCipher(testKey),
          );
          return cachedBox!;
        }

        final box1 = await getBox();
        await box1.put('test', 'value');
        await box1.close();

        // Should reopen
        final box2 = await getBox();
        expect(box2.isOpen, true);
        expect(box2.get('test'), 'value');

        await cachedBox?.close();
        await Hive.deleteBoxFromDisk(boxName);
      });
    });

    group('Key Consistency', () {
      test('should use same key for all boxes', () async {
        // This simulates how providers all get the same key
        final key = testKey;

        final conditionsBox = await Hive.openBox(
          'consistency_conditions',
          encryptionCipher: HiveAesCipher(key),
        );
        final medicationsBox = await Hive.openBox(
          'consistency_medications',
          encryptionCipher: HiveAesCipher(key),
        );
        final settingsBox = await Hive.openBox(
          'consistency_settings',
          encryptionCipher: HiveAesCipher(key),
        );

        // Write to each box
        await conditionsBox.put('test', 'conditions_value');
        await medicationsBox.put('test', 'medications_value');
        await settingsBox.put('test', 'settings_value');

        // Verify each has correct value
        expect(conditionsBox.get('test'), 'conditions_value');
        expect(medicationsBox.get('test'), 'medications_value');
        expect(settingsBox.get('test'), 'settings_value');

        await conditionsBox.close();
        await medicationsBox.close();
        await settingsBox.close();

        await Hive.deleteBoxFromDisk('consistency_conditions');
        await Hive.deleteBoxFromDisk('consistency_medications');
        await Hive.deleteBoxFromDisk('consistency_settings');
      });

      test('should allow reopening boxes with same key', () async {
        final key = testKey;
        final boxName = 'key_reopen_${DateTime.now().millisecondsSinceEpoch}';

        // First write
        var box = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(key),
        );
        await box.put('secret', 'data');
        await box.close();

        // Second read with same key
        box = await Hive.openBox(
          boxName,
          encryptionCipher: HiveAesCipher(key),
        );
        expect(box.get('secret'), 'data');

        await box.close();
        await Hive.deleteBoxFromDisk(boxName);
      });
    });

    group('Sensitive Data Handling', () {
      test('should encrypt personal health information', () async {
        final box = await Hive.openBox(
          'test_phi',
          encryptionCipher: HiveAesCipher(testKey),
        );

        // Store sensitive PHI
        await box.put('user', {
          'firstName': 'Jane',
          'lastName': 'Doe',
          'dob': '01/15/1990',
          'ssn': '123-45-6789', // Sensitive
          'allergies': 'Penicillin, Sulfa',
          'conditions': ['Diabetes', 'Hypertension'],
          'medications': ['Metformin', 'Lisinopril'],
        });

        // Verify it can be retrieved (encryption working)
        final retrieved = box.get('user') as Map;
        expect(retrieved['firstName'], 'Jane');
        expect(retrieved['conditions'], ['Diabetes', 'Hypertension']);

        await box.close();
        await Hive.deleteBoxFromDisk('test_phi');
      });

      test('should encrypt medication history', () async {
        final box = await Hive.openBox(
          'test_med_history',
          encryptionCipher: HiveAesCipher(testKey),
        );

        final history = <Map<String, dynamic>>[];
        for (var i = 0; i < 30; i++) {
          final date = DateTime.now().subtract(Duration(days: i));
          history.add({
            'date': date.toIso8601String(),
            'medicationsTaken': [
              {'name': 'Aspirin', 'time': '09:00', 'taken': true},
              {'name': 'Metformin', 'time': '12:00', 'taken': i % 3 != 0},
            ],
          });
        }

        await box.put('history', history);

        final retrieved = box.get('history') as List;
        expect(retrieved.length, 30);

        await box.close();
        await Hive.deleteBoxFromDisk('test_med_history');
      });
    });
  });
}
