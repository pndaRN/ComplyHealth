import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class ComplianceReportingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update daily compliance metrics after a dose log action.
  Future<void> updateDailyMetrics({
    required String uid,
    required DateTime date,
    required int scheduledCount,
    required int takenCount,
    required int missedCount,
    required int skippedCount,
  }) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final adherencePercent = scheduledCount > 0
          ? (takenCount / scheduledCount) * 100
          : 0.0;

      await _firestore
          .collection('compliance')
          .doc(uid)
          .collection('dailyMetrics')
          .doc(dateKey)
          .set({
        'date': Timestamp.fromDate(date),
        'scheduledCount': scheduledCount,
        'takenCount': takenCount,
        'missedCount': missedCount,
        'skippedCount': skippedCount,
        'adherencePercent': adherencePercent,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to update daily metrics: $e');
    }
  }

  /// Update the overall compliance summary.
  Future<void> updateSummary({
    required String uid,
    required double overallAdherencePercent,
    required int currentStreak,
    required int totalDosesTaken,
    required int totalDosesMissed,
    required int totalDosesSkipped,
    required int totalDosesScheduled,
    required int xp,
    required int level,
    required int medicationCount,
    required int conditionCount,
  }) async {
    try {
      await _firestore.collection('compliance').doc(uid).set({
        'overallAdherencePercent': overallAdherencePercent,
        'currentStreak': currentStreak,
        'totalDosesTaken': totalDosesTaken,
        'totalDosesMissed': totalDosesMissed,
        'totalDosesSkipped': totalDosesSkipped,
        'totalDosesScheduled': totalDosesScheduled,
        'xp': xp,
        'level': level,
        'medicationCount': medicationCount,
        'conditionCount': conditionCount,
        'lastActiveDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to update compliance summary: $e');
    }
  }
}
