import 'package:flutter_test/flutter_test.dart';
import 'package:smartpatient/core/models/medication.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  // Initialize timezone for tests
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('NotificationService - Medication Model Tests', () {
    group('Medication Model Validation', () {
      test('should create scheduled medication correctly', () {
        final medication = Medication(
          id: 'test-123',
          name: 'Aspirin',
          dosage: '100mg',
          isPRN: false,
          scheduledTimes: ['09:00', '21:00'],
        );

        expect(medication.isPRN, false);
        expect(medication.scheduledTimes.length, 2);
        expect(medication.scheduledTimes[0], '09:00');
        expect(medication.scheduledTimes[1], '21:00');
      });

      test('should create PRN medication correctly', () {
        final medication = Medication(
          id: 'test-456',
          name: 'Ibuprofen',
          dosage: '200mg',
          isPRN: true,
          maxDailyDoses: 4,
        );

        expect(medication.isPRN, true);
        expect(medication.maxDailyDoses, 4);
        expect(medication.scheduledTimes.isEmpty, true);
      });

      test('should handle multiple scheduled times', () {
        final medication = Medication(
          id: 'test-789',
          name: 'Multivitamin',
          dosage: '1 tablet',
          scheduledTimes: ['08:00', '12:00', '18:00', '22:00'],
        );

        expect(medication.scheduledTimes.length, 4);
      });

      test('should handle medication with no scheduled times', () {
        final medication = Medication(
          id: 'test-000',
          name: 'Test Med',
          dosage: '10mg',
          isPRN: false,
          scheduledTimes: [],
        );

        expect(medication.scheduledTimes.isEmpty, true);
        expect(medication.isPRN, false);
      });
    });

    group('PRN Medication Logic', () {
      test('PRN medications should not have scheduled times', () {
        final prnMedication = Medication(
          id: 'prn-123',
          name: 'Ibuprofen',
          dosage: '200mg',
          isPRN: true,
          maxDailyDoses: 4,
        );

        expect(prnMedication.isPRN, true);
        expect(prnMedication.scheduledTimes.isEmpty, true);
        expect(prnMedication.maxDailyDoses, isNotNull);
      });

      test('should handle PRN medication with dose tracking', () {
        final medication = Medication(
          id: 'prn-456',
          name: 'Pain Relief',
          dosage: '500mg',
          isPRN: true,
          maxDailyDoses: 3,
          currentDoseCount: 1,
          lastDoseCountReset: DateTime.now(),
        );

        expect(medication.isPRN, true);
        expect(medication.maxDailyDoses, 3);
        expect(medication.currentDoseCount, 1);
        expect(medication.lastDoseCountReset, isNotNull);
      });

      test('should handle PRN medication without max doses', () {
        final medication = Medication(
          id: 'prn-789',
          name: 'As Needed Med',
          dosage: '10mg',
          isPRN: true,
        );

        expect(medication.isPRN, true);
        expect(medication.maxDailyDoses, isNull);
      });
    });

    group('Scheduled Medication Logic', () {
      test('should handle single daily dose', () {
        final medication = Medication(
          id: 'scheduled-123',
          name: 'Aspirin',
          dosage: '100mg',
          isPRN: false,
          scheduledTimes: ['09:00'],
        );

        expect(medication.scheduledTimes.length, 1);
        expect(medication.isPRN, false);
      });

      test('should handle multiple daily doses', () {
        final medication = Medication(
          id: 'scheduled-456',
          name: 'Antibiotic',
          dosage: '500mg',
          isPRN: false,
          scheduledTimes: ['08:00', '14:00', '20:00'],
        );

        expect(medication.scheduledTimes.length, 3);
        expect(medication.isPRN, false);
      });

      test('should handle many scheduled times', () {
        final times = List.generate(
          10,
          (i) => '${i.toString().padLeft(2, '0')}:00',
        );

        final medication = Medication(
          id: 'scheduled-789',
          name: 'Medication',
          dosage: '10mg',
          scheduledTimes: times,
        );

        expect(medication.scheduledTimes.length, 10);
      });
    });

    group('Time Parsing and Validation', () {
      test('should parse valid time strings', () {
        final times = ['09:00', '13:30', '18:45', '00:00', '23:59'];

        for (final timeStr in times) {
          final parts = timeStr.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);

          expect(hour >= 0 && hour <= 23, true,
              reason: 'Hour $hour should be between 0-23');
          expect(minute >= 0 && minute <= 59, true,
              reason: 'Minute $minute should be between 0-59');
        }
      });

      test('should handle edge case times', () {
        final edgeCases = {
          '00:00': 'Midnight',
          '12:00': 'Noon',
          '23:59': 'Just before midnight',
        };

        for (final entry in edgeCases.entries) {
          final timeStr = entry.key;
          final parts = timeStr.split(':');

          expect(parts.length, 2, reason: 'Time should have hour:minute format');

          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);

          expect(hour, greaterThanOrEqualTo(0));
          expect(hour, lessThanOrEqualTo(23));
          expect(minute, greaterThanOrEqualTo(0));
          expect(minute, lessThanOrEqualTo(59));
        }
      });

      test('should validate time format consistency', () {
        final medication = Medication(
          id: 'time-test',
          name: 'Test Med',
          dosage: '10mg',
          scheduledTimes: ['08:00', '12:30', '18:45'],
        );

        for (final time in medication.scheduledTimes) {
          expect(time.contains(':'), true);
          expect(time.split(':').length, 2);
        }
      });
    });

    group('Time Formatting Logic', () {
      test('should format AM times correctly', () {
        expect(formatTime(0, 0), '12:00 AM');
        expect(formatTime(1, 0), '1:00 AM');
        expect(formatTime(9, 0), '9:00 AM');
        expect(formatTime(11, 59), '11:59 AM');
      });

      test('should format PM times correctly', () {
        expect(formatTime(12, 0), '12:00 PM');
        expect(formatTime(13, 0), '1:00 PM');
        expect(formatTime(18, 30), '6:30 PM');
        expect(formatTime(23, 59), '11:59 PM');
      });

      test('should pad minutes with zero', () {
        expect(formatTime(9, 5), '9:05 AM');
        expect(formatTime(14, 5), '2:05 PM');
        expect(formatTime(0, 0), '12:00 AM');
      });

      test('should handle all hours correctly', () {
        for (int hour = 0; hour < 24; hour++) {
          final formatted = formatTime(hour, 0);
          expect(formatted.contains('AM') || formatted.contains('PM'), true);
          expect(formatted.contains(':'), true);
        }
      });
    });

    group('Notification ID Generation Logic', () {
      test('should generate consistent IDs for same medication and time index',
          () {
        final medicationId = 'test-med-123';
        final timeIndex = 0;

        final id1 = generateNotificationId(medicationId, timeIndex);
        final id2 = generateNotificationId(medicationId, timeIndex);

        expect(id1, equals(id2),
            reason: 'Same medication and time should produce same ID');
      });

      test('should generate different IDs for different time indices', () {
        final medicationId = 'med-123';
        final ids = <int>{};

        for (int i = 0; i < 10; i++) {
          final id = generateNotificationId(medicationId, i);
          ids.add(id);
        }

        expect(ids.length, 10, reason: 'All IDs should be unique');
      });

      test('should generate different IDs for different medications', () {
        final ids = <int>{};

        for (int i = 0; i < 50; i++) {
          final medId = 'medication-$i';
          final id = generateNotificationId(medId, 0);
          ids.add(id);
        }

        expect(ids.length, greaterThan(45),
            reason: 'Most IDs should be unique (some hash collisions acceptable)');
      });

      test('should handle various medication ID formats', () {
        final testIds = [
          'uuid-123-456-789',
          'med_abc_xyz',
          'MED-001',
          '12345',
          'a' * 50,
        ];

        final generatedIds = <int>[];
        for (final medId in testIds) {
          final id = generateNotificationId(medId, 0);
          generatedIds.add(id);
        }

        expect(generatedIds.length, testIds.length);
        expect(generatedIds.toSet().length, testIds.length,
            reason: 'Different med IDs should produce different notification IDs');
      });
    });

    group('Notification Payload Format', () {
      test('should create valid payload format', () {
        final medicationId = 'med-123';
        final timeStr = '09:00';
        final payload = '$medicationId|$timeStr';

        expect(payload.contains('|'), true);

        final parts = payload.split('|');
        expect(parts.length, 2);
        expect(parts[0], medicationId);
        expect(parts[1], timeStr);
      });

      test('should handle multiple payloads for same medication', () {
        final medicationId = 'med-456';
        final times = ['08:00', '12:00', '18:00'];

        final payloads = times.map((time) => '$medicationId|$time').toList();

        expect(payloads.length, 3);
        expect(payloads[0], 'med-456|08:00');
        expect(payloads[1], 'med-456|12:00');
        expect(payloads[2], 'med-456|18:00');
      });

      test('should parse payload back to components', () {
        final medicationId = 'test-med-789';
        final timeStr = '15:30';
        final payload = '$medicationId|$timeStr';

        final parts = payload.split('|');
        final parsedMedId = parts[0];
        final parsedTime = parts[1];

        expect(parsedMedId, medicationId);
        expect(parsedTime, timeStr);
      });
    });

    group('Medication List Operations', () {
      test('should handle empty medication list', () {
        final medications = <Medication>[];

        expect(medications.isEmpty, true);
        expect(medications.length, 0);
      });

      test('should filter PRN vs scheduled medications', () {
        final medications = [
          Medication(
            id: 'med-1',
            name: 'Aspirin',
            dosage: '100mg',
            isPRN: false,
            scheduledTimes: ['09:00'],
          ),
          Medication(
            id: 'med-2',
            name: 'Ibuprofen',
            dosage: '200mg',
            isPRN: true,
            maxDailyDoses: 4,
          ),
          Medication(
            id: 'med-3',
            name: 'Vitamin D',
            dosage: '1000 IU',
            isPRN: false,
            scheduledTimes: ['08:00'],
          ),
        ];

        final scheduledMeds = medications.where((m) => !m.isPRN).toList();
        final prnMeds = medications.where((m) => m.isPRN).toList();

        expect(scheduledMeds.length, 2);
        expect(prnMeds.length, 1);
      });

      test('should count total scheduled notifications', () {
        final medications = [
          Medication(
            id: 'med-1',
            name: 'Med 1',
            dosage: '10mg',
            scheduledTimes: ['09:00', '21:00'],
          ),
          Medication(
            id: 'med-2',
            name: 'Med 2',
            dosage: '20mg',
            scheduledTimes: ['08:00', '12:00', '18:00'],
          ),
          Medication(
            id: 'med-3',
            name: 'Med 3',
            dosage: '30mg',
            isPRN: true,
          ),
        ];

        final totalNotifications = medications
            .where((m) => !m.isPRN)
            .fold<int>(0, (sum, m) => sum + m.scheduledTimes.length);

        expect(totalNotifications, 5);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle medication with very long name', () {
        final longName = 'A' * 200;
        final medication = Medication(
          id: 'edge-1',
          name: longName,
          dosage: '10mg',
          scheduledTimes: ['09:00'],
        );

        expect(medication.name.length, 200);
      });

      test('should handle special characters in medication name', () {
        final medication = Medication(
          id: 'edge-2',
          name: 'Med-Name (Test) [100mg] & More',
          dosage: '10mg',
          scheduledTimes: ['09:00'],
        );

        expect(medication.name.contains('('), true);
        expect(medication.name.contains(')'), true);
        expect(medication.name.contains('['), true);
        expect(medication.name.contains(']'), true);
        expect(medication.name.contains('&'), true);
      });

      test('should handle various medication ID formats', () {
        final ids = [
          'uuid-123-456-789',
          'med_123',
          'MED-ABC-XYZ',
          '00000000-0000-0000-0000-000000000000',
        ];

        for (final id in ids) {
          final medication = Medication(
            id: id,
            name: 'Test Med',
            dosage: '10mg',
          );

          expect(medication.id, id);
        }
      });

      test('should handle medications with no conditions', () {
        final medication = Medication(
          id: 'test-no-condition',
          name: 'Test Med',
          dosage: '10mg',
          conditionNames: [],
        );

        expect(medication.conditionNames.isEmpty, true);
      });

      test('should handle medications with multiple conditions', () {
        final medication = Medication(
          id: 'test-multi-condition',
          name: 'Test Med',
          dosage: '10mg',
          conditionNames: ['Condition A', 'Condition B', 'Condition C'],
        );

        expect(medication.conditionNames.length, 3);
      });
    });

    group('Time Zone Handling', () {
      test('should have timezone database initialized', () {
        expect(tz.timeZoneDatabase.locations.isNotEmpty, true);
      });

      test('should get local timezone', () {
        final local = tz.local;
        expect(local, isNotNull);
      });

      test('should create timezone-aware datetime', () {
        final now = tz.TZDateTime.now(tz.local);
        expect(now, isNotNull);
        expect(now.location, equals(tz.local));
      });

      test('should handle scheduling times in the future', () {
        final now = tz.TZDateTime.now(tz.local);
        final scheduledTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          14,
          30,
        );

        expect(scheduledTime.location, equals(tz.local));
        expect(scheduledTime.hour, 14);
        expect(scheduledTime.minute, 30);
      });

      test('should handle past times by scheduling for next day', () {
        final now = tz.TZDateTime.now(tz.local);
        var scheduledTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          now.hour,
          now.minute,
        );

        // If time has passed, schedule for tomorrow
        if (scheduledTime.isBefore(now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }

        expect(
            scheduledTime.isAfter(now) || scheduledTime.isAtSameMomentAs(now),
            true);
      });
    });

    group('Medication JSON Serialization', () {
      test('should serialize medication to JSON', () {
        final medication = Medication(
          id: 'json-test-1',
          name: 'Test Med',
          dosage: '10mg',
          isPRN: false,
          scheduledTimes: ['09:00', '21:00'],
          conditionNames: ['Test Condition'],
        );

        final json = medication.toJson();

        expect(json['id'], 'json-test-1');
        expect(json['name'], 'Test Med');
        expect(json['dosage'], '10mg');
        expect(json['isPRN'], false);
        expect(json['scheduledTimes'], ['09:00', '21:00']);
        expect(json['conditionNames'], ['Test Condition']);
      });

      test('should deserialize medication from JSON', () {
        final json = {
          'id': 'json-test-2',
          'name': 'Test Med',
          'doseage': '20mg', // Note: typo in original implementation
          'isPRN': true,
          'maxDailyDoses': 4,
          'currentDoseCount': 2,
        };

        final medication = Medication.fromJson(json);

        expect(medication.id, 'json-test-2');
        expect(medication.name, 'Test Med');
        expect(medication.dosage, '20mg');
        expect(medication.isPRN, true);
        expect(medication.maxDailyDoses, 4);
        expect(medication.currentDoseCount, 2);
      });
    });
  });
}

// Helper functions that mimic private methods in NotificationService

/// Format time for display (mimics _formatTime in NotificationService)
String formatTime(int hour, int minute) {
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
  final displayMinute = minute.toString().padLeft(2, '0');
  return '$displayHour:$displayMinute $period';
}

/// Generate notification ID (mimics _generateNotificationId in NotificationService)
int generateNotificationId(String medicationId, int timeIndex) {
  final hash = medicationId.hashCode;
  return (hash.abs() % 100000) * 10 + timeIndex;
}
