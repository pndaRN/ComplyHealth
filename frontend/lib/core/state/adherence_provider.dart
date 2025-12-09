import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smartpatient/core/models/medication.dart';
import 'package:smartpatient/core/models/medication_log.dart';
import 'package:smartpatient/core/state/medication_provider.dart';

/// Provider for medication adherence tracking
final adherenceProvider =
    NotifierProvider<AdherenceNotifier, List<MedicationLog>>(
  AdherenceNotifier.new,
);

class AdherenceNotifier extends Notifier<List<MedicationLog>> {
  static const String boxName = 'medication_logs';
  Box<MedicationLog>? _box;

  @override
  List<MedicationLog> build() {
    _initBox();
    return [];
  }

  Future<void> _initBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<MedicationLog>(boxName);
      state = _box!.values.toList();
    }
  }

  /// Get or open the Hive box (cached)
  Future<Box<MedicationLog>> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox<MedicationLog>(boxName);
    state = _box!.values.toList();
    return _box!;
  }

  /// Get all medication instances scheduled for today
  Future<List<MedicationInstance>> getTodayInstances() async {
    final medications = ref.read(medicationProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final instances = <MedicationInstance>[];

    for (final med in medications) {
      if (med.isPRN) {
        // For PRN medications, create a single instance
        instances.add(MedicationInstance(
          medication: med,
          scheduledTime: today,
          isPRN: true,
        ));
      } else {
        // For scheduled medications, create an instance for each time
        for (final timeStr in med.scheduledTimes) {
          final parts = timeStr.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final scheduledTime = DateTime(
            today.year,
            today.month,
            today.day,
            hour,
            minute,
          );

          instances.add(MedicationInstance(
            medication: med,
            scheduledTime: scheduledTime,
            isPRN: false,
          ));
        }
      }
    }

    // Get existing logs for today
    final todayLogs = await getLogsForDate(today);

    // Match logs to instances
    for (final instance in instances) {
      final matchingLogs = todayLogs.where((log) {
        if (log.medicationId != instance.medication.id) return false;
        if (instance.isPRN) return true;

        // For scheduled meds, match by time (within 5 minutes)
        final diff = log.scheduledTime.difference(instance.scheduledTime);
        return diff.abs().inMinutes < 5;
      }).toList();

      instance.log = matchingLogs.isNotEmpty ? matchingLogs.first : null;
    }

    // Sort by scheduled time
    instances.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    return instances;
  }

  /// Log a dose as taken
  Future<void> logDoseTaken({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    DateTime? actualTakenTime,
    String? notes,
  }) async {
    try {
      final log = MedicationLog(
        medicationId: medicationId,
        medicationName: medicationName,
        dosage: dosage,
        scheduledTime: scheduledTime,
        actualTakenTime: actualTakenTime ?? DateTime.now(),
        status: DoseStatus.taken,
        notes: notes,
      );

      final box = await _getBox();
      await box.put(log.id, log);
      state = box.values.toList();
    } catch (_) {
      rethrow;
    }
  }

  /// Log a dose as skipped
  Future<void> logDoseSkipped({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    String? skipReason,
    String? notes,
  }) async {
    try {
      final log = MedicationLog(
        medicationId: medicationId,
        medicationName: medicationName,
        dosage: dosage,
        scheduledTime: scheduledTime,
        status: DoseStatus.skipped,
        skipReason: skipReason,
        notes: notes,
      );

      final box = await _getBox();
      await box.put(log.id, log);
      state = box.values.toList();
    } catch (_) {
      rethrow;
    }
  }

  /// Auto-mark doses as missed if past grace period
  Future<void> autoMarkMissedDoses({int graceMinutes = 30}) async {
    final instances = await getTodayInstances();
    final now = DateTime.now();

    for (final instance in instances) {
      if (instance.log == null && !instance.isPRN) {
        final deadline = instance.scheduledTime.add(
          Duration(minutes: graceMinutes),
        );

        if (now.isAfter(deadline)) {
          await logDoseMissed(
            medicationId: instance.medication.id,
            medicationName: instance.medication.name,
            dosage: instance.medication.dosage,
            scheduledTime: instance.scheduledTime,
          );
        }
      }
    }
  }

  /// Log a dose as missed
  Future<void> logDoseMissed({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
  }) async {
    try {
      final log = MedicationLog(
        medicationId: medicationId,
        medicationName: medicationName,
        dosage: dosage,
        scheduledTime: scheduledTime,
        status: DoseStatus.missed,
      );

      final box = await _getBox();
      await box.put(log.id, log);
      state = box.values.toList();
    } catch (_) {
      rethrow;
    }
  }

  /// Delete a log entry
  Future<void> deleteLog(String logId) async {
    try {
      final box = await _getBox();
      await box.delete(logId);
      state = box.values.toList();
    } catch (_) {
      rethrow;
    }
  }

  /// Update an existing log
  Future<void> updateLog(MedicationLog log) async {
    try {
      final box = await _getBox();
      await box.put(log.id, log);
      state = box.values.toList();
    } catch (_) {
      rethrow;
    }
  }

  /// Get logs for a specific date
  Future<List<MedicationLog>> getLogsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return state.where((log) {
      return log.scheduledTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          log.scheduledTime.isBefore(endOfDay);
    }).toList();
  }

  /// Get logs for a date range
  Future<List<MedicationLog>> getLogsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    return state.where((log) {
      return log.scheduledTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
          log.scheduledTime.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  /// Calculate adherence percentage for the last 7 days
  Future<double> getWeeklyAdherence() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final logs = await getLogsForDateRange(sevenDaysAgo, now);
    if (logs.isEmpty) return 0.0;

    final takenCount = logs.where((log) => log.status == DoseStatus.taken).length;
    return (takenCount / logs.length) * 100;
  }

  /// Calculate current streak (consecutive days with 100% adherence)
  Future<int> getCurrentStreak() async {
    final now = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final dailyAdherence = await getDailyAdherence(date);

      if (dailyAdherence >= 100.0) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Calculate adherence percentage for a specific day
  Future<double> getDailyAdherence(DateTime date) async {
    final logs = await getLogsForDate(date);
    if (logs.isEmpty) return 0.0;

    final takenCount = logs.where((log) => log.status == DoseStatus.taken).length;
    return (takenCount / logs.length) * 100;
  }

  /// Get adherence metrics summary
  Future<AdherenceMetrics> getMetrics() async {
    final weeklyAdherence = await getWeeklyAdherence();
    final currentStreak = await getCurrentStreak();

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final logs = await getLogsForDateRange(sevenDaysAgo, now);

    final takenCount = logs.where((log) => log.status == DoseStatus.taken).length;
    final missedCount = logs.where((log) => log.status == DoseStatus.missed).length;
    final skippedCount = logs.where((log) => log.status == DoseStatus.skipped).length;

    return AdherenceMetrics(
      weeklyAdherence: weeklyAdherence,
      currentStreak: currentStreak,
      totalDosesTaken: takenCount,
      totalDosesMissed: missedCount,
      totalDosesSkipped: skippedCount,
      totalDosesScheduled: logs.length,
    );
  }
}

/// Represents a medication instance scheduled for a specific time
class MedicationInstance {
  final Medication medication;
  final DateTime scheduledTime;
  final bool isPRN;
  MedicationLog? log;

  MedicationInstance({
    required this.medication,
    required this.scheduledTime,
    required this.isPRN,
    this.log,
  });

  DoseStatus? get status => log?.status;

  bool get isTaken => status == DoseStatus.taken;
  bool get isSkipped => status == DoseStatus.skipped;
  bool get isMissed => status == DoseStatus.missed;
  bool get isPending => status == null;

  bool get isOverdue {
    if (isPending && !isPRN) {
      final now = DateTime.now();
      final gracePeriod = Duration(minutes: 30);
      final deadline = scheduledTime.add(gracePeriod);
      return now.isAfter(deadline);
    }
    return false;
  }
}

/// Adherence metrics data class
class AdherenceMetrics {
  final double weeklyAdherence;
  final int currentStreak;
  final int totalDosesTaken;
  final int totalDosesMissed;
  final int totalDosesSkipped;
  final int totalDosesScheduled;

  AdherenceMetrics({
    required this.weeklyAdherence,
    required this.currentStreak,
    required this.totalDosesTaken,
    required this.totalDosesMissed,
    required this.totalDosesSkipped,
    required this.totalDosesScheduled,
  });

  double get overallAdherence {
    if (totalDosesScheduled == 0) return 0.0;
    return (totalDosesTaken / totalDosesScheduled) * 100;
  }
}
