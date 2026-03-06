import 'package:hive_ce/hive_ce.dart';
import 'package:uuid/uuid.dart';

part 'medication_log.g.dart';

/// Enum representing the status of a medication dose
@HiveType(typeId: 3)
enum DoseStatus {
  @HiveField(0)
  taken,

  @HiveField(1)
  skipped,

  @HiveField(2)
  missed,
}

/// Model representing a medication dose log entry
@HiveType(typeId: 4)
class MedicationLog {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String medicationId;

  @HiveField(2)
  final String medicationName;

  @HiveField(3)
  final DateTime scheduledTime;

  @HiveField(4)
  final DateTime? actualTakenTime;

  @HiveField(5)
  final DoseStatus status;

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final String dosage;

  @HiveField(8)
  final String? skipReason;

  @HiveField(9, defaultValue: false)
  final bool isDismissed;

  MedicationLog({
    String? id,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    this.actualTakenTime,
    required this.status,
    this.notes,
    required this.dosage,
    this.skipReason,
    this.isDismissed = false,
  }) : id = id ?? const Uuid().v4();

  /// Create a copy with modified fields
  MedicationLog copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    DateTime? scheduledTime,
    DateTime? actualTakenTime,
    DoseStatus? status,
    String? notes,
    String? dosage,
    String? skipReason,
    bool? isDismissed,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actualTakenTime: actualTakenTime ?? this.actualTakenTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      dosage: dosage ?? this.dosage,
      skipReason: skipReason ?? this.skipReason,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  /// Check if this log is for today
  bool isToday() {
    final now = DateTime.now();
    return scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day;
  }

  /// Check if this dose is overdue (past scheduled time + grace period)
  /// Default grace period is 60 minutes (clinical standard)
  bool isOverdue({int graceMinutes = 60}) {
    if (status != DoseStatus.taken) {
      final gracePeriod = Duration(minutes: graceMinutes);
      final deadline = scheduledTime.add(gracePeriod);
      return DateTime.now().isAfter(deadline);
    }
    return false;
  }

  @override
  String toString() {
    return 'MedicationLog(id: $id, medication: $medicationName, scheduled: $scheduledTime, status: $status)';
  }
}
