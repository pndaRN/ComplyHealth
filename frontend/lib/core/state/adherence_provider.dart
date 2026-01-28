import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:complyhealth/core/models/medication.dart';
import 'package:complyhealth/core/models/medication_log.dart';
import 'package:complyhealth/core/state/medication_provider.dart';
import '../../core/services/encryption_migration_service.dart';

/// Provider for medication adherence tracking
final adherenceProvider =
    AsyncNotifierProvider<AdherenceNotifier, List<MedicationLog>>(
      AdherenceNotifier.new,
    );

class AdherenceNotifier extends AsyncNotifier<List<MedicationLog>> {
  static const String boxName = 'medication_logs';
  Box<MedicationLog>? _box;

  Future<Box<MedicationLog>> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }

    if (Hive.isBoxOpen(boxName)) {
      try {
        try {
          final box = Hive.box<MedicationLog>(boxName);
          _box = box;
          return box;
        } catch (_) {
          final box = Hive.box(boxName);
          await box.close();
        }
      } catch (_) {
        try {
          final box = await Hive.openBox(boxName);
          await box.close();
        } catch (_) {}
      }
    }

    final key = await EncryptionMigrationService.getEncryptionKey();
    _box = await Hive.openBox<MedicationLog>(
      boxName,
      encryptionCipher: HiveAesCipher(key),
    );
    return _box!;
  }

  @override
  Future<List<MedicationLog>> build() async {
    final box = await _getBox();
    return box.values.toList();
  }

  /// Get all medication instances scheduled for today
  Future<List<MedicationInstance>> getTodayInstances() async {
    final medications = await ref.read(
      medicationProvider.future,
    ); // Access data from AsyncValue
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final instances = <MedicationInstance>[];

    for (final med in medications) {
      if (med.isPRN) {
        instances.add(
          MedicationInstance(
            medication: med,
            scheduledTime: today,
            isPRN: true,
          ),
        );
      } else {
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

          instances.add(
            MedicationInstance(
              medication: med,
              scheduledTime: scheduledTime,
              isPRN: false,
            ),
          );
        }
      }
    }

    final todayLogs = await getLogsForDate(today);

    for (final instance in instances) {
      final matchingLogs = todayLogs.where((log) {
        if (log.medicationId != instance.medication.id) return false;
        if (instance.isPRN) return true;

        final diff = log.scheduledTime.difference(instance.scheduledTime);
        return diff.abs().inMinutes < 5;
      }).toList();

      instance.log = matchingLogs.isNotEmpty ? matchingLogs.first : null;
    }

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
    state = await AsyncValue.guard(() async {
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
      return box.values.toList();
    });

    // Rethrow error if save failed so caller can handle it
    if (state.hasError) {
      throw state.error!;
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
    state = await AsyncValue.guard(() async {
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
      return box.values.toList();
    });

    // Rethrow error if save failed so caller can handle it
    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Auto-mark doses as missed if past grace period (today only)
  /// Default grace period is 60 minutes (clinical standard)
  Future<void> autoMarkMissedDoses({int graceMinutes = 60}) async {
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

  /// Auto-mark doses as missed for past days that were never logged
  /// Only marks doses as missed for dates AFTER the user's first taken log
  Future<void> autoMarkMissedDosesForPastDays({int daysToCheck = 7}) async {
    final medications = await ref.read(medicationProvider.future);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get all existing logs to find the first taken log date
    final box = await _getBox();
    final allLogs = box.values.toList();

    // Only proceed if user has at least one taken log (they're actively tracking)
    final takenLogs = allLogs
        .where((log) => log.status == DoseStatus.taken)
        .toList();
    if (takenLogs.isEmpty) {
      return; // User hasn't started tracking yet, don't auto-mark anything
    }

    // Find the earliest taken log date - only mark missed after that date
    final firstTakenDate = takenLogs
        .map(
          (log) => DateTime(
            log.scheduledTime.year,
            log.scheduledTime.month,
            log.scheduledTime.day,
          ),
        )
        .reduce((a, b) => a.isBefore(b) ? a : b);

    for (int i = 1; i <= daysToCheck; i++) {
      final date = today.subtract(Duration(days: i));

      // Skip dates before the user started tracking
      if (date.isBefore(firstTakenDate)) {
        continue;
      }

      final existingLogs = await getLogsForDate(date);

      for (final med in medications) {
        // Skip PRN medications - they don't have mandatory schedules
        if (med.isPRN) continue;

        for (final timeStr in med.scheduledTimes) {
          final parts = timeStr.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            hour,
            minute,
          );

          // Check if log exists for this dose (within 5-minute tolerance)
          final hasLog = existingLogs.any(
            (log) =>
                log.medicationId == med.id &&
                (log.scheduledTime.difference(scheduledTime)).abs().inMinutes <
                    5,
          );

          if (!hasLog) {
            await logDoseMissed(
              medicationId: med.id,
              medicationName: med.name,
              dosage: med.dosage,
              scheduledTime: scheduledTime,
            );
          }
        }
      }
    }
  }

  /// Check and mark missed doses - call on app startup
  /// Handles both past days and today's overdue doses
  Future<void> checkAndMarkMissedDoses() async {
    await autoMarkMissedDosesForPastDays();
    await autoMarkMissedDoses();
  }

  /// Log a dose as missed
  Future<void> logDoseMissed({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
  }) async {
    state = await AsyncValue.guard(() async {
      final log = MedicationLog(
        medicationId: medicationId,
        medicationName: medicationName,
        dosage: dosage,
        scheduledTime: scheduledTime,
        status: DoseStatus.missed,
      );

      final box = await _getBox();
      await box.put(log.id, log);
      return box.values.toList();
    });

    // Rethrow error if save failed so caller can handle it
    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Delete a log entry
  Future<void> deleteLog(String logId) async {
    state = await AsyncValue.guard(() async {
      final box = await _getBox();
      await box.delete(logId);
      return box.values.toList();
    });

    // Rethrow error if delete failed so caller can handle it
    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Clear all missed logs (for fixing the auto-mark bug)
  Future<void> clearMissedLogs() async {
    state = await AsyncValue.guard(() async {
      final box = await _getBox();
      final keysToDelete = box.keys.where((key) {
        final log = box.get(key);
        return log?.status == DoseStatus.missed;
      }).toList();

      for (final key in keysToDelete) {
        await box.delete(key);
      }
      return box.values.toList();
    });

    // Rethrow error if clear failed so caller can handle it
    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Update an existing log
  Future<void> updateLog(MedicationLog log) async {
    state = await AsyncValue.guard(() async {
      final box = await _getBox();
      await box.put(log.id, log);
      return box.values.toList();
    });

    // Rethrow error if update failed so caller can handle it
    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Recover a missed dose by marking it as taken
  /// Updates the existing log rather than creating a new one
  Future<void> recoverMissedDoseAsTaken({
    required String logId,
    required DateTime actualTakenTime,
    String? notes,
  }) async {
    state = await AsyncValue.guard(() async {
      final box = await _getBox();
      final existingLog = box.get(logId);

      if (existingLog == null || existingLog.status != DoseStatus.missed) {
        throw Exception('Log not found or not a missed dose');
      }

      final updatedLog = existingLog.copyWith(
        status: DoseStatus.taken,
        actualTakenTime: actualTakenTime,
        notes: notes ?? existingLog.notes,
      );

      await box.put(logId, updatedLog);
      return box.values.toList();
    });

    // Rethrow error if recovery failed so caller can handle it
    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Recover a missed dose by marking it as skipped
  /// Updates the existing log rather than creating a new one
  Future<void> recoverMissedDoseAsSkipped({
    required String logId,
    required String skipReason,
    String? notes,
  }) async {
    state = await AsyncValue.guard(() async {
      final box = await _getBox();
      final existingLog = box.get(logId);

      if (existingLog == null || existingLog.status != DoseStatus.missed) {
        throw Exception('Log not found or not a missed dose');
      }

      final updatedLog = existingLog.copyWith(
        status: DoseStatus.skipped,
        skipReason: skipReason,
        notes: notes ?? existingLog.notes,
      );

      await box.put(logId, updatedLog);
      return box.values.toList();
    });

    // Rethrow error if recovery failed so caller can handle it
    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Dismiss a missed dose (acknowledges the miss but removes from active list)
  Future<void> dismissMissedDose({required String logId}) async {
    state = await AsyncValue.guard(() async {
      final box = await _getBox();
      final existingLog = box.get(logId);

      if (existingLog == null || existingLog.status != DoseStatus.missed) {
        throw Exception('Log not found or not a missed dose');
      }

      final updatedLog = existingLog.copyWith(isDismissed: true);

      await box.put(logId, updatedLog);
      return box.values.toList();
    });

    // Rethrow error if dismiss failed so caller can handle it
    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Get logs for a specific date
  Future<List<MedicationLog>> getLogsForDate(DateTime date) async {
    final logs = state.value ?? []; // Access current state data
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return logs.where((log) {
      return log.scheduledTime.isAfter(
            startOfDay.subtract(const Duration(seconds: 1)),
          ) &&
          log.scheduledTime.isBefore(endOfDay);
    }).toList();
  }

  /// Get logs for a date range
  Future<List<MedicationLog>> getLogsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final logs = state.value ?? []; // Access current state data
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    return logs.where((log) {
      return log.scheduledTime.isAfter(
            start.subtract(const Duration(seconds: 1)),
          ) &&
          log.scheduledTime.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  /// Calculate adherence percentage for the last 7 days
  Future<double> getWeeklyAdherence() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final logs = await getLogsForDateRange(sevenDaysAgo, now);
    if (logs.isEmpty) return 0.0;

    final takenCount = logs
        .where((log) => log.status == DoseStatus.taken)
        .length;
    return (takenCount / logs.length) * 100;
  }

  /// Calculate current streak (consecutive days with 100% adherence)
  Future<int> getCurrentStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Pre-fetch all logs once (up to 1 year)
    final yearAgo = today.subtract(const Duration(days: 365));
    final allLogs = await getLogsForDateRange(yearAgo, now);

    // Group logs by date for O(1) lookup
    final logsByDate = <DateTime, List<MedicationLog>>{};
    for (final log in allLogs) {
      final logDate = DateTime(
        log.scheduledTime.year,
        log.scheduledTime.month,
        log.scheduledTime.day,
      );
      logsByDate.putIfAbsent(logDate, () => []).add(log);
    }

    // Calculate streak using grouped data
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final dayLogs = logsByDate[date] ?? [];

      if (dayLogs.isEmpty) {
        break; // No logs for this day means streak breaks
      }

      final takenCount = dayLogs
          .where((log) => log.status == DoseStatus.taken)
          .length;
      final adherence = (takenCount / dayLogs.length) * 100;

      if (adherence >= 100.0) {
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

    final takenCount = logs
        .where((log) => log.status == DoseStatus.taken)
        .length;
    return (takenCount / logs.length) * 100;
  }

  /// Get adherence metrics summary
  Future<AdherenceMetrics> getMetrics() async {
    final weeklyAdherence = await getWeeklyAdherence();
    final currentStreak = await getCurrentStreak();

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final logs = await getLogsForDateRange(sevenDaysAgo, now);

    final takenCount = logs
        .where((log) => log.status == DoseStatus.taken)
        .length;
    final missedCount = logs
        .where((log) => log.status == DoseStatus.missed)
        .length;
    final skippedCount = logs
        .where((log) => log.status == DoseStatus.skipped)
        .length;

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

  /// Check if dose is overdue (past grace period)
  /// Uses 60-minute clinical standard window
  bool get isOverdue {
    if (isPending && !isPRN) {
      final now = DateTime.now();
      const gracePeriod = Duration(minutes: 60);
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
