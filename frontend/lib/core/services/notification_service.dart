import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:complyhealth/core/models/medication.dart';

class NotificationService {
  static NotificationService? _singleton;

  factory NotificationService() {
    if (_singleton == null) {
      try {
        _singleton = NotificationService._internal();
      } catch (e) {
        debugPrint('Failed to initialize NotificationService: $e');
        rethrow;
      }
    }
    return _singleton!;
  }

  NotificationService._internal()
    : _notifications = FlutterLocalNotificationsPlugin();

  /// Testing constructor that accepts a mock plugin
  @visibleForTesting
  NotificationService.withPlugin(this._notifications);

  final FlutterLocalNotificationsPlugin _notifications;

  bool _initialized = false;
  bool _exactAlarmsPermitted = true;

  /// Setter for testing to bypass initialization
  @visibleForTesting
  set initialized(bool value) => _initialized = value;

  // Stream controller for notification tap events
  static final StreamController<String> _notificationTapController =
      StreamController<String>.broadcast();
  static Stream<String> get onNotificationTap =>
      _notificationTapController.stream;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    try {
      tz.initializeTimeZones();
      final String timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (e) {
      debugPrint('Failed to get local timezone: $e. Falling back to UTC.');
      // Fallback to UTC to prevent crash
      tz.setLocalLocation(tz.UTC);
    }

    // Skip platform-specific initialization on web
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    _initialized = true;
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();

      // Request exact alarm permission for Android 12+ (API 31+)
      if (!kIsWeb && Platform.isAndroid) {
        final exactAlarmGranted = await androidPlugin
            .requestExactAlarmsPermission();
        _exactAlarmsPermitted = exactAlarmGranted ?? false;
      }
    }

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Emit event for listeners (main.dart) to handle navigation
    // Payload contains: medicationId|scheduledTime
    _notificationTapController.add(response.payload ?? '');
  }

  /// Schedule notifications for all medications (grouped by time)
  Future<void> scheduleAllMedications(List<Medication> medications) async {
    await rescheduleAllNotifications(medications);
  }

  /// Reschedule all notifications, grouping medications by time
  Future<void> rescheduleAllNotifications(List<Medication> medications) async {
    if (!_initialized) await initialize();

    // Cancel all existing notifications
    await cancelAllNotifications();

    // Group medications by time
    final Map<String, List<Medication>> scheduledGroups = {};
    for (final med in medications) {
      if (med.isPRN) continue;

      for (final timeStr in med.scheduledTimes) {
        if (!scheduledGroups.containsKey(timeStr)) {
          scheduledGroups[timeStr] = [];
        }
        scheduledGroups[timeStr]!.add(med);
      }
    }

    // Schedule notification for each time group
    for (final entry in scheduledGroups.entries) {
      final timeStr = entry.key;
      final meds = entry.value;
      final parts = timeStr.split(':');
      if (parts.length < 2) continue;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      // Schedule for each day of the week to allow cycling messages
      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final now = tz.TZDateTime.now(tz.local);
        var scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        // Adjust to the correct day
        scheduledDate = scheduledDate.add(Duration(days: dayOffset));

        // If the calculated date is in the past (even with dayOffset), move it forward by weeks until it's future
        // Actually, since we loop 0..6 from *today*, only today's time might be past.
        if (scheduledDate.isBefore(now)) {
          // If it's today and past, this specific instance is for next week.
          // However, local_notifications matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime
          // means it triggers every week at this time on this weekday.
          // We just need to give it a valid date.
          // If we give it a past date, it might fire immediately or schedule for next week depending on implementation.
          // Safer to ensure it's in the future.
          scheduledDate = scheduledDate.add(const Duration(days: 7));
        }

        final weekday = scheduledDate.weekday; // 1 (Mon) to 7 (Sun)
        final message = _getMessageForTime(hour, dayOffset);
        final medNames = meds.map((m) => m.name).join(', ');

        // Generate a unique ID for this time AND day
        final notificationId = _generateNotificationIdForTimeAndDay(
          hour,
          minute,
          weekday,
        );

        await _scheduleWeeklyNotification(
          id: notificationId,
          title: message,
          body: 'Time to take: $medNames',
          scheduledDate: scheduledDate,
          payload: 'MEDICATIONS_TAB|$timeStr',
        );
      }
    }
  }

  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders to take your medications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use exact alarms if permitted, otherwise fall back to inexact
    final scheduleMode = _exactAlarmsPermitted
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: scheduleMode,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  String _getMessageForTime(int hour, int randomSeed) {
    // Pools of messages
    const morning = [
      'Before coffee gets cold ☕',
      'Good morning! Time for meds ☀️',
      'Start the day right 💊',
      'Morning check-in! 🌅',
    ];

    const midday = [
      'Time for your midday meds ☀️',
      'Lunchtime check-in 🥪',
      'Keep it up! Midday meds 💊',
    ];

    const afternoon = [
      'Afternoon check-in 🌿',
      'Time for afternoon meds 🌤️',
      'Don\'t forget your meds! 🍵',
    ];

    const evening = [
      'Evening medications 🌙',
      'Time to wind down 🌆',
      'Evening check-in ✨',
    ];

    const night = [
      'Sleep well! Night meds 😴',
      'Sweet dreams! 💤',
      'Nighttime routine 🌙',
    ];

    List<String> pool;
    if (hour >= 5 && hour < 11) {
      pool = morning;
    } else if (hour >= 11 && hour < 14) {
      pool = midday;
    } else if (hour >= 14 && hour < 18) {
      pool = afternoon;
    } else if (hour >= 18 && hour < 22) {
      pool = evening;
    } else {
      pool = night;
    }

    // Pick a message based on the seed (day offset) to cycle through them
    return pool[randomSeed % pool.length];
  }

  int _generateNotificationIdForTimeAndDay(int hour, int minute, int weekday) {
    // Format: DHHmm (D=1-7, HH=00-23, mm=00-59)
    // Example: Sunday 23:59 -> 72359
    // Max value: 72359, well within int range
    return (weekday * 10000) + (hour * 100) + minute;
  }

  /// Schedule notifications for a medication
  // Deprecated: Use rescheduleAllNotifications instead
  Future<void> scheduleMedicationNotifications(Medication medication) async {
    debugPrint(
      'WARNING: scheduleMedicationNotifications called directly. Use rescheduleAllNotifications instead.',
    );
  }

  /// Schedule a daily notification at a specific time
  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    // Deprecated
  }

  /// Cancel all notifications for a medication
  // Deprecated: Use rescheduleAllNotifications instead
  Future<void> cancelMedicationNotifications(String medicationId) async {
    debugPrint(
      'WARNING: cancelMedicationNotifications called directly. Use rescheduleAllNotifications instead.',
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
  }

  /// Generate a unique notification ID from medication ID and time index
  @visibleForTesting
  static int generateNotificationId(String medicationId, int timeIndex) {
    // Use hash directly to minimize collision risk, offset by time index
    final hash = medicationId.hashCode.abs();
    // Large multiplier to separate time indices
    return hash + (timeIndex * 10000000);
  }

  int _generateNotificationId(String medicationId, int timeIndex) =>
      generateNotificationId(medicationId, timeIndex);

  /// Format time for display
  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) await initialize();
    return await _notifications.pendingNotificationRequests();
  }
}
