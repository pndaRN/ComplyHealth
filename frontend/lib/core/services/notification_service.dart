import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:complyhealth/core/models/medication.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

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
    // Handle notification tap - could navigate to specific screen
    // This can be expanded to open the medication details or adherence screen
    // Payload contains: medicationId|scheduledTime
  }

  /// Schedule notifications for a medication
  Future<void> scheduleMedicationNotifications(Medication medication) async {
    if (!_initialized) await initialize();

    // Cancel existing notifications for this medication first
    await cancelMedicationNotifications(medication.id);

    if (medication.isPRN) {
      // Don't schedule notifications for PRN medications
      return;
    }

    // Schedule notification for each scheduled time
    for (int i = 0; i < medication.scheduledTimes.length; i++) {
      final timeStr = medication.scheduledTimes[i];
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Create a unique notification ID for each medication time
      final notificationId = _generateNotificationId(medication.id, i);

      // Schedule daily notification at this time
      await _scheduleDailyNotification(
        id: notificationId,
        title: 'Time to take ${medication.name}',
        body:
            '${medication.dosage} - Scheduled for ${_formatTime(hour, minute)}',
        hour: hour,
        minute: minute,
        payload: '${medication.id}|$timeStr',
      );
    }
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
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

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

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Cancel all notifications for a medication
  Future<void> cancelMedicationNotifications(String medicationId) async {
    if (!_initialized) await initialize();

    // Cancel all possible notification IDs for this medication
    // We'll cancel up to 10 possible times (should be more than enough)
    for (int i = 0; i < 10; i++) {
      final notificationId = _generateNotificationId(medicationId, i);
      await _notifications.cancel(notificationId);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
  }

  /// Schedule notifications for all medications
  Future<void> scheduleAllMedications(List<Medication> medications) async {
    for (final medication in medications) {
      await scheduleMedicationNotifications(medication);
    }
  }

  /// Generate a unique notification ID from medication ID and time index
  int _generateNotificationId(String medicationId, int timeIndex) {
    // Create a hash from the medication ID and add the time index
    final hash = medicationId.hashCode;
    return (hash.abs() % 100000) * 10 + timeIndex;
  }

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
