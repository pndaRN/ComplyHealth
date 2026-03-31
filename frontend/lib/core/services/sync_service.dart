import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import '../models/disease.dart';
import '../models/medication.dart';
import '../models/medication_log.dart';
import '../models/profile.dart';
import '../models/notebook_entry.dart';
import 'field_encryption_service.dart';
import 'encryption_migration_service.dart';

class SyncService {
  final FieldEncryptionService _encryption = FieldEncryptionService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<StreamSubscription> _listeners = [];
  bool _isSyncing = false;

  /// Upload all local data to Firestore (first-time sync).
  Future<void> initialUpload(String uid) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final key = await EncryptionMigrationService.getEncryptionKey();

      // Upload profile
      await _uploadProfile(uid, key);

      // Upload conditions
      await _uploadConditions(uid, key);

      // Upload medications
      await _uploadMedications(uid, key);

      // Upload medication logs
      await _uploadMedicationLogs(uid, key);

      // Upload notebook entries
      await _uploadNotebookEntries(uid, key);

      // Upload settings
      await _uploadSettings(key);

      debugPrint('Initial upload completed for $uid');
    } catch (e) {
      debugPrint('Initial upload failed: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Download all Firestore data to local Hive (new device login).
  Future<void> initialDownload(String uid) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final key = await EncryptionMigrationService.getEncryptionKey();

      await _downloadProfile(uid, key);
      await _downloadConditions(uid, key);
      await _downloadMedications(uid, key);
      await _downloadMedicationLogs(uid, key);
      await _downloadNotebookEntries(uid, key);
      await _downloadSettings(uid, key);

      debugPrint('Initial download completed for $uid');
    } catch (e) {
      debugPrint('Initial download failed: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Check if user has data in Firestore.
  Future<bool> hasRemoteData(String uid) async {
    try {
      final profileDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('data')
          .get();
      return profileDoc.exists;
    } catch (e) {
      return false;
    }
  }

  // ===== Sync individual documents =====

  Future<void> syncProfile(String uid, Profile profile) async {
    try {
      final encrypted = {
        'encrypted_firstName': await _encryption.encrypt(profile.firstName, uid),
        'encrypted_lastName': await _encryption.encrypt(profile.lastName, uid),
        'encrypted_dob': await _encryption.encrypt(profile.dob, uid),
        'encrypted_allergies': await _encryption.encrypt(profile.allergies, uid),
        'xp': profile.xp,
        'streak': profile.streak,
        'levelProgress': profile.levelProgress,
        'lastXpAwardDate': profile.lastXpAwardDate?.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('data')
          .set(encrypted, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Profile sync failed: $e');
    }
  }

  Future<void> syncCondition(String uid, Disease disease) async {
    try {
      final encrypted = {
        'encrypted_name': await _encryption.encrypt(disease.name, uid),
        'encrypted_code': await _encryption.encrypt(disease.code, uid),
        'encrypted_category': await _encryption.encrypt(disease.category, uid),
        'encrypted_commonName': await _encryption.encrypt(disease.commonName, uid),
        'encrypted_description': await _encryption.encrypt(disease.description, uid),
        'encrypted_personalNotes': await _encryption.encrypt(disease.personalNotes ?? '', uid),
        'isCustom': disease.isCustom,
        'createdAt': disease.createdAt?.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('conditions')
          .doc(disease.code)
          .set(encrypted, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Condition sync failed: $e');
    }
  }

  Future<void> deleteConditionRemote(String uid, String code) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('conditions')
          .doc(code)
          .delete();
    } catch (e) {
      debugPrint('Condition delete sync failed: $e');
    }
  }

  Future<void> syncMedication(String uid, Medication med) async {
    try {
      final encrypted = {
        'encrypted_name': await _encryption.encrypt(med.name, uid),
        'encrypted_dosage': await _encryption.encrypt(med.dosage, uid),
        'encrypted_conditionNames': await _encryption.encrypt(med.conditionNames.join('|||'), uid),
        'encrypted_personalNotes': await _encryption.encrypt(med.personalNotes ?? '', uid),
        'isPRN': med.isPRN,
        'scheduledTimesCount': med.scheduledTimes.length,
        'isTimeSensitive': med.isTimeSensitive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('medications')
          .doc(med.id)
          .set(encrypted, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Medication sync failed: $e');
    }
  }

  Future<void> deleteMedicationRemote(String uid, String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('medications')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Medication delete sync failed: $e');
    }
  }

  Future<void> syncMedicationLog(String uid, MedicationLog log) async {
    try {
      final encrypted = {
        'medicationId': log.medicationId,
        'encrypted_medicationName': await _encryption.encrypt(log.medicationName, uid),
        'encrypted_dosage': await _encryption.encrypt(log.dosage, uid),
        'encrypted_notes': await _encryption.encrypt(log.notes ?? '', uid),
        'encrypted_skipReason': await _encryption.encrypt(log.skipReason ?? '', uid),
        'scheduledTime': Timestamp.fromDate(log.scheduledTime),
        'actualTakenTime': log.actualTakenTime != null
            ? Timestamp.fromDate(log.actualTakenTime!)
            : null,
        'status': log.status.name,
        'isDismissed': log.isDismissed,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('medicationLogs')
          .doc(log.id)
          .set(encrypted, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Medication log sync failed: $e');
    }
  }

  Future<void> syncNotebookEntry(String uid, NotebookEntry entry) async {
    try {
      final encrypted = {
        'sourceType': entry.sourceType,
        'encrypted_sourceName': await _encryption.encrypt(entry.sourceName, uid),
        'encrypted_sourceCode': await _encryption.encrypt(entry.sourceCode, uid),
        'encrypted_content': await _encryption.encrypt(entry.content, uid),
        'timestamp': Timestamp.fromDate(entry.timestamp),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notebookEntries')
          .doc(entry.id)
          .set(encrypted, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Notebook entry sync failed: $e');
    }
  }

  Future<void> deleteNotebookEntryRemote(String uid, String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notebookEntries')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Notebook entry delete sync failed: $e');
    }
  }

  /// Start real-time sync listeners for cross-device updates.
  void startRealtimeSync(String uid) {
    stopRealtimeSync();

    // Listen for remote condition changes
    _listeners.add(
      _firestore
          .collection('users')
          .doc(uid)
          .collection('conditions')
          .snapshots()
          .listen(
        (snapshot) => _handleRemoteConditions(uid, snapshot),
        onError: (e) => debugPrint('Conditions listener error: $e'),
      ),
    );

    // Listen for remote medication changes
    _listeners.add(
      _firestore
          .collection('users')
          .doc(uid)
          .collection('medications')
          .snapshots()
          .listen(
        (snapshot) => _handleRemoteMedications(uid, snapshot),
        onError: (e) => debugPrint('Medications listener error: $e'),
      ),
    );

    debugPrint('Real-time sync started for $uid');
  }

  /// Stop all real-time sync listeners.
  void stopRealtimeSync() {
    for (final sub in _listeners) {
      sub.cancel();
    }
    _listeners.clear();
    _encryption.clearCache();
  }

  /// Delete all user data from Firestore (account deletion).
  Future<void> deleteAllRemoteData(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);

    // Delete subcollections
    for (final collection in [
      'profile',
      'conditions',
      'medications',
      'medicationLogs',
      'notebookEntries',
      'settings',
      'keychain',
    ]) {
      final docs = await userRef.collection(collection).get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    }

    // Delete compliance data
    final complianceRef = _firestore.collection('compliance').doc(uid);
    final summaryDoc = await complianceRef.get();
    if (summaryDoc.exists) await complianceRef.delete();

    final dailyDocs = await complianceRef.collection('dailyMetrics').get();
    for (final doc in dailyDocs.docs) {
      await doc.reference.delete();
    }
  }

  // ===== Private upload methods =====

  Future<void> _uploadProfile(String uid, List<int> hiveKey) async {
    final box = await Hive.openBox<Profile>(
      'profile',
      encryptionCipher: HiveAesCipher(hiveKey),
    );
    final profile = box.get('user');
    if (profile != null) {
      await syncProfile(uid, profile);
    }
  }

  Future<void> _uploadConditions(String uid, List<int> hiveKey) async {
    final box = await Hive.openBox<Disease>(
      'conditions',
      encryptionCipher: HiveAesCipher(hiveKey),
    );
    final batch = _firestore.batch();
    for (final disease in box.values) {
      final ref = _firestore
          .collection('users')
          .doc(uid)
          .collection('conditions')
          .doc(disease.code);
      batch.set(ref, {
        'encrypted_name': await _encryption.encrypt(disease.name, uid),
        'encrypted_code': await _encryption.encrypt(disease.code, uid),
        'encrypted_category': await _encryption.encrypt(disease.category, uid),
        'encrypted_commonName': await _encryption.encrypt(disease.commonName, uid),
        'encrypted_description': await _encryption.encrypt(disease.description, uid),
        'encrypted_personalNotes': await _encryption.encrypt(disease.personalNotes ?? '', uid),
        'isCustom': disease.isCustom,
        'createdAt': disease.createdAt?.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> _uploadMedications(String uid, List<int> hiveKey) async {
    final box = await Hive.openBox<Medication>(
      'medications',
      encryptionCipher: HiveAesCipher(hiveKey),
    );
    final batch = _firestore.batch();
    for (final med in box.values) {
      final ref = _firestore
          .collection('users')
          .doc(uid)
          .collection('medications')
          .doc(med.id);
      batch.set(ref, {
        'encrypted_name': await _encryption.encrypt(med.name, uid),
        'encrypted_dosage': await _encryption.encrypt(med.dosage, uid),
        'encrypted_conditionNames': await _encryption.encrypt(med.conditionNames.join('|||'), uid),
        'encrypted_personalNotes': await _encryption.encrypt(med.personalNotes ?? '', uid),
        'encrypted_scheduledTimes': await _encryption.encrypt(med.scheduledTimes.join('|||'), uid),
        'isPRN': med.isPRN,
        'scheduledTimesCount': med.scheduledTimes.length,
        'isTimeSensitive': med.isTimeSensitive,
        'maxDailyDoses': med.maxDailyDoses,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> _uploadMedicationLogs(String uid, List<int> hiveKey) async {
    final box = await Hive.openBox<MedicationLog>(
      'medication_logs',
      encryptionCipher: HiveAesCipher(hiveKey),
    );

    // Batch in groups of 500 (Firestore limit)
    final logs = box.values.toList();
    for (int i = 0; i < logs.length; i += 500) {
      final batch = _firestore.batch();
      final chunk = logs.skip(i).take(500);
      for (final log in chunk) {
        final ref = _firestore
            .collection('users')
            .doc(uid)
            .collection('medicationLogs')
            .doc(log.id);
        batch.set(ref, {
          'medicationId': log.medicationId,
          'encrypted_medicationName': await _encryption.encrypt(log.medicationName, uid),
          'encrypted_dosage': await _encryption.encrypt(log.dosage, uid),
          'encrypted_notes': await _encryption.encrypt(log.notes ?? '', uid),
          'encrypted_skipReason': await _encryption.encrypt(log.skipReason ?? '', uid),
          'scheduledTime': Timestamp.fromDate(log.scheduledTime),
          'actualTakenTime': log.actualTakenTime != null
              ? Timestamp.fromDate(log.actualTakenTime!)
              : null,
          'status': log.status.name,
          'isDismissed': log.isDismissed,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Future<void> _uploadNotebookEntries(String uid, List<int> hiveKey) async {
    final box = await Hive.openBox<NotebookEntry>(
      'notebook',
      encryptionCipher: HiveAesCipher(hiveKey),
    );
    final batch = _firestore.batch();
    for (final entry in box.values) {
      final ref = _firestore
          .collection('users')
          .doc(uid)
          .collection('notebookEntries')
          .doc(entry.id);
      batch.set(ref, {
        'sourceType': entry.sourceType,
        'encrypted_sourceName': await _encryption.encrypt(entry.sourceName, uid),
        'encrypted_sourceCode': await _encryption.encrypt(entry.sourceCode, uid),
        'encrypted_content': await _encryption.encrypt(entry.content, uid),
        'timestamp': Timestamp.fromDate(entry.timestamp),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> _uploadSettings(List<int> hiveKey) async {
    // Settings are handled by the settings provider sync
  }

  // ===== Private download methods =====

  Future<void> _downloadProfile(String uid, List<int> hiveKey) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('data')
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    final profile = Profile(
      firstName: await _encryption.decrypt(data['encrypted_firstName'] ?? '', uid),
      lastName: await _encryption.decrypt(data['encrypted_lastName'] ?? '', uid),
      dob: await _encryption.decrypt(data['encrypted_dob'] ?? '', uid),
      allergies: await _encryption.decrypt(data['encrypted_allergies'] ?? '', uid),
      xp: data['xp'] ?? 0,
      streak: data['streak'] ?? 0,
      levelProgress: (data['levelProgress'] ?? 0.0).toDouble(),
      lastXpAwardDate: data['lastXpAwardDate'] != null
          ? DateTime.tryParse(data['lastXpAwardDate'])
          : null,
    );

    final box = await Hive.openBox<Profile>(
      'profile',
      encryptionCipher: HiveAesCipher(hiveKey),
    );
    await box.put('user', profile);
  }

  Future<void> _downloadConditions(String uid, List<int> hiveKey) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('conditions')
        .get();

    final box = await Hive.openBox<Disease>(
      'conditions',
      encryptionCipher: HiveAesCipher(hiveKey),
    );

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final disease = Disease(
        code: await _encryption.decrypt(data['encrypted_code'] ?? '', uid),
        name: await _encryption.decrypt(data['encrypted_name'] ?? '', uid),
        category: await _encryption.decrypt(data['encrypted_category'] ?? '', uid),
        commonName: await _encryption.decrypt(data['encrypted_commonName'] ?? '', uid),
        description: await _encryption.decrypt(data['encrypted_description'] ?? '', uid),
        personalNotes: await _encryption.decrypt(data['encrypted_personalNotes'] ?? '', uid),
        isCustom: data['isCustom'] ?? false,
        createdAt: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt'])
            : null,
      );
      await box.put(disease.code, disease);
    }
  }

  Future<void> _downloadMedications(String uid, List<int> hiveKey) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('medications')
        .get();

    final box = await Hive.openBox<Medication>(
      'medications',
      encryptionCipher: HiveAesCipher(hiveKey),
    );

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final conditionNamesStr =
          await _encryption.decrypt(data['encrypted_conditionNames'] ?? '', uid);
      final scheduledTimesStr =
          await _encryption.decrypt(data['encrypted_scheduledTimes'] ?? '', uid);

      final med = Medication(
        id: doc.id,
        name: await _encryption.decrypt(data['encrypted_name'] ?? '', uid),
        dosage: await _encryption.decrypt(data['encrypted_dosage'] ?? '', uid),
        conditionNames: conditionNamesStr.isNotEmpty
            ? conditionNamesStr.split('|||')
            : [],
        personalNotes: await _encryption.decrypt(data['encrypted_personalNotes'] ?? '', uid),
        isPRN: data['isPRN'] ?? false,
        scheduledTimes: scheduledTimesStr.isNotEmpty
            ? scheduledTimesStr.split('|||')
            : [],
        isTimeSensitive: data['isTimeSensitive'] ?? true,
        maxDailyDoses: data['maxDailyDoses'],
      );
      await box.put(med.id, med);
    }
  }

  Future<void> _downloadMedicationLogs(String uid, List<int> hiveKey) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('medicationLogs')
        .get();

    final box = await Hive.openBox<MedicationLog>(
      'medication_logs',
      encryptionCipher: HiveAesCipher(hiveKey),
    );

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final statusStr = data['status'] as String? ?? 'missed';
      final status = DoseStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => DoseStatus.missed,
      );

      final log = MedicationLog(
        id: doc.id,
        medicationId: data['medicationId'] ?? '',
        medicationName: await _encryption.decrypt(data['encrypted_medicationName'] ?? '', uid),
        dosage: await _encryption.decrypt(data['encrypted_dosage'] ?? '', uid),
        scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
        actualTakenTime: data['actualTakenTime'] != null
            ? (data['actualTakenTime'] as Timestamp).toDate()
            : null,
        status: status,
        notes: await _encryption.decrypt(data['encrypted_notes'] ?? '', uid),
        skipReason: await _encryption.decrypt(data['encrypted_skipReason'] ?? '', uid),
        isDismissed: data['isDismissed'] ?? false,
      );
      await box.put(log.id, log);
    }
  }

  Future<void> _downloadNotebookEntries(String uid, List<int> hiveKey) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('notebookEntries')
        .get();

    final box = await Hive.openBox<NotebookEntry>(
      'notebook',
      encryptionCipher: HiveAesCipher(hiveKey),
    );

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final entry = NotebookEntry(
        id: doc.id,
        sourceType: data['sourceType'] ?? 0,
        sourceName: await _encryption.decrypt(data['encrypted_sourceName'] ?? '', uid),
        sourceCode: await _encryption.decrypt(data['encrypted_sourceCode'] ?? '', uid),
        content: await _encryption.decrypt(data['encrypted_content'] ?? '', uid),
        timestamp: (data['timestamp'] as Timestamp).toDate(),
      );
      await box.put(entry.id, entry);
    }
  }

  Future<void> _downloadSettings(String uid, List<int> hiveKey) async {
    // Settings download is handled during initial setup
  }

  // ===== Private real-time handlers =====

  Future<void> _handleRemoteConditions(
    String uid,
    QuerySnapshot snapshot,
  ) async {
    // Only process changes from other devices (not our own writes)
    if (_isSyncing) return;

    try {
      final key = await EncryptionMigrationService.getEncryptionKey();
      final box = await Hive.openBox<Disease>(
        'conditions',
        encryptionCipher: HiveAesCipher(key),
      );

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          await box.delete(change.doc.id);
        } else {
          final data = change.doc.data() as Map<String, dynamic>;
          final disease = Disease(
            code: await _encryption.decrypt(data['encrypted_code'] ?? '', uid),
            name: await _encryption.decrypt(data['encrypted_name'] ?? '', uid),
            category: await _encryption.decrypt(data['encrypted_category'] ?? '', uid),
            commonName: await _encryption.decrypt(data['encrypted_commonName'] ?? '', uid),
            description: await _encryption.decrypt(data['encrypted_description'] ?? '', uid),
            personalNotes: await _encryption.decrypt(data['encrypted_personalNotes'] ?? '', uid),
            isCustom: data['isCustom'] ?? false,
            createdAt: data['createdAt'] != null
                ? DateTime.tryParse(data['createdAt'])
                : null,
          );
          await box.put(disease.code, disease);
        }
      }
    } catch (e) {
      debugPrint('Remote conditions sync error: $e');
    }
  }

  Future<void> _handleRemoteMedications(
    String uid,
    QuerySnapshot snapshot,
  ) async {
    if (_isSyncing) return;

    try {
      final key = await EncryptionMigrationService.getEncryptionKey();
      final box = await Hive.openBox<Medication>(
        'medications',
        encryptionCipher: HiveAesCipher(key),
      );

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          await box.delete(change.doc.id);
        } else {
          final data = change.doc.data() as Map<String, dynamic>;
          final conditionNamesStr =
              await _encryption.decrypt(data['encrypted_conditionNames'] ?? '', uid);
          final scheduledTimesStr =
              await _encryption.decrypt(data['encrypted_scheduledTimes'] ?? '', uid);

          final med = Medication(
            id: change.doc.id,
            name: await _encryption.decrypt(data['encrypted_name'] ?? '', uid),
            dosage: await _encryption.decrypt(data['encrypted_dosage'] ?? '', uid),
            conditionNames: conditionNamesStr.isNotEmpty
                ? conditionNamesStr.split('|||')
                : [],
            personalNotes: await _encryption.decrypt(data['encrypted_personalNotes'] ?? '', uid),
            isPRN: data['isPRN'] ?? false,
            scheduledTimes: scheduledTimesStr.isNotEmpty
                ? scheduledTimesStr.split('|||')
                : [],
            isTimeSensitive: data['isTimeSensitive'] ?? true,
            maxDailyDoses: data['maxDailyDoses'],
          );
          await box.put(med.id, med);
        }
      }
    } catch (e) {
      debugPrint('Remote medications sync error: $e');
    }
  }
}
