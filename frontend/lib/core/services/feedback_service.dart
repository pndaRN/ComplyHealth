import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:complyhealth/core/models/feedback.dart' as local_feedback;
import 'package:uuid/uuid.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _boxName = 'feedback';
  final Uuid _uuid = const Uuid();

  /// Submit feedback - tries Firestore first, queues locally if offline
  Future<void> submitFeedback({
    required String type,
    required String subject,
    required String message,
  }) async {
    final feedbackId = _uuid.v4();
    final timestamp = DateTime.now();

    final feedback = local_feedback.Feedback(
      id: feedbackId,
      type: type,
      subject: subject,
      message: message,
      timestamp: timestamp,
      synced: false,
    );

    // Save to Hive first (local backup)
    await _saveToHive(feedback);

    // Try to sync to Firestore
    try {
      await _syncToFirestore(feedback);
      // Mark as synced in Hive
      await _markAsSynced(feedbackId);
    } catch (_) {
      // Network error or Firestore error - feedback is queued locally
      // Will be synced later when connectivity is restored
    }
  }

  /// Save feedback to local Hive storage
  Future<void> _saveToHive(local_feedback.Feedback feedback) async {
    final box = await Hive.openBox<local_feedback.Feedback>(_boxName);
    await box.put(feedback.id, feedback);
  }

  /// Sync feedback to Firestore
  Future<void> _syncToFirestore(local_feedback.Feedback feedback) async {
    await _firestore.collection('feedback').add(feedback.toFirestore());
  }

  /// Mark feedback as synced in local storage
  Future<void> _markAsSynced(String feedbackId) async {
    final box = await Hive.openBox<local_feedback.Feedback>(_boxName);
    final feedback = box.get(feedbackId);
    if (feedback != null) {
      await box.put(feedbackId, feedback.copyWith(synced: true));
    }
  }

  /// Sync all pending (unsynced) feedback to Firestore
  Future<int> syncPendingFeedback() async {
    final box = await Hive.openBox<local_feedback.Feedback>(_boxName);
    int syncedCount = 0;

    for (final key in box.keys) {
      final feedback = box.get(key);
      if (feedback != null && !feedback.synced) {
        try {
          await _syncToFirestore(feedback);
          await _markAsSynced(feedback.id);
          syncedCount++;
        } catch (_) {
          // Continue with next feedback
        }
      }
    }

    return syncedCount;
  }

  /// Get count of pending (unsynced) feedback
  Future<int> getPendingCount() async {
    final box = await Hive.openBox<local_feedback.Feedback>(_boxName);
    int count = 0;
    for (final key in box.keys) {
      final feedback = box.get(key);
      if (feedback != null && !feedback.synced) {
        count++;
      }
    }
    return count;
  }

  /// Clear all synced feedback from local storage (optional cleanup)
  Future<void> clearSyncedFeedback() async {
    final box = await Hive.openBox<local_feedback.Feedback>(_boxName);
    final keysToDelete = <dynamic>[];

    for (final key in box.keys) {
      final feedback = box.get(key);
      if (feedback != null && feedback.synced) {
        keysToDelete.add(key);
      }
    }

    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }
}
