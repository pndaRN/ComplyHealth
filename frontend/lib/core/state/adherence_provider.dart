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
    final medications = await ref.read(medicationProvider.future); // Access data from AsyncValue
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
  }

  /// Delete a log entry
  Future<void> deleteLog(String logId) async {
    state = await AsyncValue.guard(() async {
      final box = await _getBox();
      await box.delete(logId);
      return box.values.toList();
    });
  }

  /// Update an existing log
  Future<void> updateLog(MedicationLog log) async {
    state = await AsyncValue.guard(() async {
      final box = await _getBox();
      await box.put(log.id, log);
      return box.values.toList();
    });
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
