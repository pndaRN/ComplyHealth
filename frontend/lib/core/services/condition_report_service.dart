import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ConditionReportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submits a custom condition request to the admin collection for review
  /// Returns true if successful, false otherwise
  static Future<bool> submitConditionRequest({
    required String conditionName,
    String? userId,
  }) async {
    try {
      await _firestore.collection('conditionRequests').add({
        'conditionName': conditionName,
        'requestedAt': FieldValue.serverTimestamp(),
        'userId': userId ?? 'anonymous',
        'status': 'pending',
      });
      return true;
    } catch (e) {
      // Log error for debugging
      debugPrint('Error submitting condition request: $e');
      return false;
    }
  }
}
