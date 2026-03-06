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
    when(
      mockPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
        matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
      ),
    ).thenAnswer((_) async {});
  });

  group('NotificationService - Grouped Scheduling', () {
    test(
      'schedules 7 weekly notifications (one per day) for a single time slot',
      () async {
        final medications = [
          Medication(
            id: 'med-1',
            name: 'Test Med',
            dosage: '10mg',
            scheduledTimes: ['09:00'],
          ),
        ];

        await service.rescheduleAllNotifications(medications);

        // Should call zonedSchedule 7 times (once for each day of the week)
        verify(
          mockPlugin.zonedSchedule(
            any,
            any,
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            payload: anyNamed('payload'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
          ),
        ).called(7);
      },
    );

    test('groups multiple medications for the same time', () async {
      final medications = [
        Medication(
          id: 'med-1',
          name: 'Med A',
          dosage: '10mg',
          scheduledTimes: ['09:00'],
        ),
        Medication(
          id: 'med-2',
          name: 'Med B',
          dosage: '20mg',
          scheduledTimes: ['09:00'],
        ),
      ];

      await service.rescheduleAllNotifications(medications);

      // Should still only call 7 times (grouped), not 14
      verify(
        mockPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          payload: anyNamed('payload'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        ),
      ).called(7);
    });

    test('notification body lists all medications', () async {
      final medications = [
        Medication(
          id: 'med-1',
          name: 'Aspirin',
          dosage: '10mg',
          scheduledTimes: ['09:00'],
        ),
        Medication(
          id: 'med-2',
          name: 'Vitamin C',
          dosage: '500mg',
          scheduledTimes: ['09:00'],
        ),
      ];

      await service.rescheduleAllNotifications(medications);

      // Verify the body contains both medication names
      verify(
        mockPlugin.zonedSchedule(
          any,
          any,
          'Time to take: Aspirin, Vitamin C',
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          payload: anyNamed('payload'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        ),
      ).called(7);
    });

    test('uses correct payload for navigation', () async {
      final medications = [
        Medication(
          id: 'med-1',
          name: 'Test Med',
          dosage: '10mg',
          scheduledTimes: ['09:00'],
        ),
      ];

      await service.rescheduleAllNotifications(medications);

      verify(
        mockPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          payload: 'MEDICATIONS_TAB|09:00',
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        ),
      ).called(7);
    });
  });

  group('NotificationService - Custom Messages', () {
    test('uses morning messages for 9:00', () async {
      final medications = [
        Medication(
          id: 'med-1',
          name: 'Med',
          dosage: '10mg',
          scheduledTimes: ['09:00'],
        ),
      ];

      await service.rescheduleAllNotifications(medications);

      // Verify title is one of the morning messages
      verify(
        mockPlugin.zonedSchedule(
          any,
          argThat(
            anyOf(
              contains('Before coffee'),
              contains('Good morning'),
              contains('Start the day'),
              contains('Morning check-in'),
            ),
          ),
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          payload: anyNamed('payload'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        ),
      ).called(7);
    });

    test('uses evening messages for 20:00', () async {
      final medications = [
        Medication(
          id: 'med-1',
          name: 'Med',
          dosage: '10mg',
          scheduledTimes: ['20:00'],
        ),
      ];

      await service.rescheduleAllNotifications(medications);

      verify(
        mockPlugin.zonedSchedule(
          any,
          argThat(
            anyOf(
              contains('Evening medications'),
              contains('Time to wind down'),
              contains('Evening check-in'),
            ),
          ),
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          payload: anyNamed('payload'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        ),
      ).called(7);
    });
  });

  group('NotificationService - PRN & Logic', () {
    test('skips PRN medications', () async {
      final medications = [
        Medication(
          id: 'prn-1',
          name: 'PRN Med',
          dosage: '20mg',
          isPRN: true,
          scheduledTimes: [],
        ),
      ];

      await service.rescheduleAllNotifications(medications);

      verifyNever(
        mockPlugin.zonedSchedule(
          any,
          any,
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          payload: anyNamed('payload'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        ),
      );
    });

    test('cancels all existing notifications before rescheduling', () async {
      final medications = <Medication>[];
      await service.rescheduleAllNotifications(medications);

      verify(mockPlugin.cancelAll()).called(1);
    });
  });
}
