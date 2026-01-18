import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:complyhealth/core/models/medication.dart';
import 'package:complyhealth/core/services/notification_service.dart';

@GenerateMocks([FlutterLocalNotificationsPlugin])
import 'notification_service_unit_test.mocks.dart';

void main() {
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late NotificationService service;

  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    service = NotificationService.withPlugin(mockPlugin);
    service.initialized = true; // Bypass initialization

    // Stub cancel to return void future
    when(mockPlugin.cancel(any)).thenAnswer((_) async {});
    when(mockPlugin.cancelAll()).thenAnswer((_) async {});
    when(mockPlugin.zonedSchedule(
      any,
      any,
      any,
      any,
      any,
      androidScheduleMode: anyNamed('androidScheduleMode'),
      payload: anyNamed('payload'),
      matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
    )).thenAnswer((_) async {});
  });

  group('NotificationService - Scheduling Behavior', () {
    test('schedules one notification per scheduled time', () async {
      final medication = Medication(
        id: 'med-1',
        name: 'Test Med',
        dosage: '10mg',
        scheduledTimes: ['09:00', '21:00'],
      );

      await service.scheduleMedicationNotifications(medication);

      // Should call zonedSchedule twice (once per scheduled time)
      verify(mockPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).called(2);
    });

    test('schedules notification with correct title and body', () async {
      final medication = Medication(
        id: 'med-1',
        name: 'Aspirin',
        dosage: '100mg',
        scheduledTimes: ['14:30'],
      );

      await service.scheduleMedicationNotifications(medication);

      verify(mockPlugin.zonedSchedule(
        any,
        'Time to take Aspirin',
        '100mg - Scheduled for 2:30 PM',
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).called(1);
    });

    test('schedules notification with correct payload', () async {
      final medication = Medication(
        id: 'med-abc-123',
        name: 'Test Med',
        dosage: '10mg',
        scheduledTimes: ['09:00'],
      );

      await service.scheduleMedicationNotifications(medication);

      verify(mockPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: 'med-abc-123|09:00',
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).called(1);
    });

    test('uses deterministic notification IDs based on medication ID and time index', () async {
      final medication = Medication(
        id: 'med-1',
        name: 'Test Med',
        dosage: '10mg',
        scheduledTimes: ['09:00'],
      );

      final expectedId = NotificationService.generateNotificationId('med-1', 0);

      await service.scheduleMedicationNotifications(medication);

      verify(mockPlugin.zonedSchedule(
        expectedId,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).called(1);
    });

    test('skips invalid time formats', () async {
      final medication = Medication(
        id: 'med-1',
        name: 'Test Med',
        dosage: '10mg',
        scheduledTimes: ['invalid', '09:00', 'abc:def'],
      );

      await service.scheduleMedicationNotifications(medication);

      // Should only schedule one notification (09:00)
      verify(mockPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).called(1);
    });
  });

  group('NotificationService - Cancel Before Schedule (Double Notification Prevention)', () {
    test('cancels existing notifications before scheduling new ones', () async {
      final medication = Medication(
        id: 'med-1',
        name: 'Test Med',
        dosage: '10mg',
        scheduledTimes: ['09:00'],
      );

      await service.scheduleMedicationNotifications(medication);

      // Should cancel 10 potential notification IDs before scheduling
      verify(mockPlugin.cancel(any)).called(10);
    });

    test('cancel is called before zonedSchedule', () async {
      final medication = Medication(
        id: 'med-1',
        name: 'Test Med',
        dosage: '10mg',
        scheduledTimes: ['09:00'],
      );

      final List<String> callOrder = [];

      when(mockPlugin.cancel(any)).thenAnswer((_) async {
        callOrder.add('cancel');
      });
      when(mockPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).thenAnswer((_) async {
        callOrder.add('schedule');
      });

      await service.scheduleMedicationNotifications(medication);

      // All cancel calls should come before any schedule calls
      final firstScheduleIndex = callOrder.indexOf('schedule');
      final lastCancelIndex = callOrder.lastIndexOf('cancel');

      expect(lastCancelIndex, lessThan(firstScheduleIndex));
    });

    test('calling scheduleMedicationNotifications twice cancels before second schedule', () async {
      final medication = Medication(
        id: 'med-1',
        name: 'Test Med',
        dosage: '10mg',
        scheduledTimes: ['09:00'],
      );

      await service.scheduleMedicationNotifications(medication);
      clearInteractions(mockPlugin);

      // Reset stubs
      when(mockPlugin.cancel(any)).thenAnswer((_) async {});
      when(mockPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).thenAnswer((_) async {});

      // Call again
      await service.scheduleMedicationNotifications(medication);

      // Should cancel before scheduling again
      verify(mockPlugin.cancel(any)).called(10);
      verify(mockPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).called(1);
    });
  });

  group('NotificationService - PRN Medications', () {
    test('does not schedule notifications for PRN medications', () async {
      final prnMedication = Medication(
        id: 'prn-1',
        name: 'PRN Med',
        dosage: '20mg',
        isPRN: true,
        scheduledTimes: ['09:00', '21:00'],
      );

      await service.scheduleMedicationNotifications(prnMedication);

      // Should cancel existing notifications but not schedule new ones
      verify(mockPlugin.cancel(any)).called(10);
      verifyNever(mockPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      ));
    });

    test('cancels notifications when medication becomes PRN', () async {
      // Simulate a medication changing to PRN
      final prnMedication = Medication(
        id: 'med-1',
        name: 'Now PRN',
        dosage: '10mg',
        isPRN: true,
      );

      await service.scheduleMedicationNotifications(prnMedication);

      // Should still cancel all potential notification IDs
      verify(mockPlugin.cancel(any)).called(10);
    });
  });

  group('NotificationService - Cancel Operations', () {
    test('cancelMedicationNotifications cancels up to 10 notification IDs', () async {
      await service.cancelMedicationNotifications('med-1');

      verify(mockPlugin.cancel(any)).called(10);
    });

    test('cancelMedicationNotifications uses correct IDs', () async {
      final medId = 'test-med-id';
      await service.cancelMedicationNotifications(medId);

      for (int i = 0; i < 10; i++) {
        final expectedId = NotificationService.generateNotificationId(medId, i);
        verify(mockPlugin.cancel(expectedId)).called(1);
      }
    });

    test('cancelAllNotifications calls cancelAll on plugin', () async {
      await service.cancelAllNotifications();

      verify(mockPlugin.cancelAll()).called(1);
    });
  });

  group('NotificationService - Bulk Operations', () {
    test('scheduleAllMedications processes each medication', () async {
      final medications = [
        Medication(
          id: 'med-1',
          name: 'Med 1',
          dosage: '10mg',
          scheduledTimes: ['09:00'],
        ),
        Medication(
          id: 'med-2',
          name: 'Med 2',
          dosage: '20mg',
          scheduledTimes: ['12:00'],
        ),
        Medication(
          id: 'med-3',
          name: 'Med 3',
          dosage: '30mg',
          scheduledTimes: ['18:00'],
        ),
      ];

      await service.scheduleAllMedications(medications);

      // Should schedule 3 notifications total (one per medication)
      verify(mockPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).called(3);

      // Should cancel for each medication (10 x 3)
      verify(mockPlugin.cancel(any)).called(30);
    });

    test('scheduleAllMedications skips PRN medications', () async {
      final medications = [
        Medication(
          id: 'med-1',
          name: 'Regular Med',
          dosage: '10mg',
          scheduledTimes: ['09:00'],
        ),
        Medication(
          id: 'prn-1',
          name: 'PRN Med',
          dosage: '20mg',
          isPRN: true,
        ),
        Medication(
          id: 'med-2',
          name: 'Another Regular',
          dosage: '30mg',
          scheduledTimes: ['18:00'],
        ),
      ];

      await service.scheduleAllMedications(medications);

      // Should only schedule 2 notifications (PRN skipped)
      verify(mockPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).called(2);
    });

    test('handles empty medication list', () async {
      await service.scheduleAllMedications([]);

      verifyNever(mockPlugin.cancel(any));
      verifyNever(mockPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      ));
    });
  });

  group('NotificationService - Notification ID Generation', () {
    test('generates consistent IDs for same input', () {
      final id1 = NotificationService.generateNotificationId('med-1', 0);
      final id2 = NotificationService.generateNotificationId('med-1', 0);

      expect(id1, equals(id2));
    });

    test('generates different IDs for different time indices', () {
      final ids = <int>{};

      for (int i = 0; i < 5; i++) {
        final id = NotificationService.generateNotificationId('med-1', i);
        ids.add(id);
      }

      expect(ids.length, 5);
    });

    test('generates different IDs for different medications', () {
      final ids = <int>{};

      for (int i = 0; i < 10; i++) {
        final id = NotificationService.generateNotificationId('med-$i', 0);
        ids.add(id);
      }

      // Should have high uniqueness (allowing for rare hash collisions)
      expect(ids.length, greaterThan(8));
    });
  });

  group('NotificationService - Time Formatting', () {
    test('schedules with correct AM time formatting', () async {
      final medication = Medication(
        id: 'med-1',
        name: 'Morning Med',
        dosage: '10mg',
        scheduledTimes: ['09:05'],
      );

      await service.scheduleMedicationNotifications(medication);

      verify(mockPlugin.zonedSchedule(
        any,
        any,
        '10mg - Scheduled for 9:05 AM',
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).called(1);
    });

    test('schedules with correct PM time formatting', () async {
      final medication = Medication(
        id: 'med-1',
        name: 'Evening Med',
        dosage: '10mg',
        scheduledTimes: ['18:30'],
      );

      await service.scheduleMedicationNotifications(medication);

      verify(mockPlugin.zonedSchedule(
        any,
        any,
        '10mg - Scheduled for 6:30 PM',
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).called(1);
    });

    test('schedules with correct midnight formatting', () async {
      final medication = Medication(
        id: 'med-1',
        name: 'Midnight Med',
        dosage: '10mg',
        scheduledTimes: ['00:00'],
      );

      await service.scheduleMedicationNotifications(medication);

      verify(mockPlugin.zonedSchedule(
        any,
        any,
        '10mg - Scheduled for 12:00 AM',
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).called(1);
    });

    test('schedules with correct noon formatting', () async {
      final medication = Medication(
        id: 'med-1',
        name: 'Noon Med',
        dosage: '10mg',
        scheduledTimes: ['12:00'],
      );

      await service.scheduleMedicationNotifications(medication);

      verify(mockPlugin.zonedSchedule(
        any,
        any,
        '10mg - Scheduled for 12:00 PM',
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      )).called(1);
    });
  });
}
