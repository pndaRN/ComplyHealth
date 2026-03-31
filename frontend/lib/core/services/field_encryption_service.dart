import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ce/hive_ce.dart';

class FieldEncryptionService {
  static const _secureStorage = FlutterSecureStorage();
  static const _syncKeyPrefix = 'sync_key_';
  static const _passphraseSetKey = 'passphrase_set_';

  Uint8List? _cachedKey;
  String? _cachedUid;

  /// Get or generate the sync encryption key for this user.
  /// Stored locally in flutter_secure_storage.
  Future<Uint8List> getSyncKey(String uid) async {
    if (_cachedKey != null && _cachedUid == uid) return _cachedKey!;

    final stored = await _secureStorage.read(key: '$_syncKeyPrefix$uid');
    if (stored != null) {
      _cachedKey = base64Url.decode(stored);
      _cachedUid = uid;
      return _cachedKey!;
    }

    // Generate a new 256-bit key
    final key = Uint8List.fromList(Hive.generateSecureKey().sublist(0, 32));
    await _secureStorage.write(
      key: '$_syncKeyPrefix$uid',
      value: base64Url.encode(key),
    );
    _cachedKey = key;
    _cachedUid = uid;
    return key;
  }

  /// Check if this user has a sync key stored locally.
  Future<bool> hasSyncKey(String uid) async {
    final stored = await _secureStorage.read(key: '$_syncKeyPrefix$uid');
    return stored != null;
  }

  /// Check if user has set a sync passphrase (has keychain in Firestore).
  Future<bool> hasPassphraseSet(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('keychain')
          .doc('master')
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking passphrase: $e');
      return false;
    }
  }

  /// Encrypt the sync key with a passphrase and store in Firestore.
  /// Called when user sets their sync passphrase for the first time.
  Future<void> setSyncPassphrase(String uid, String passphrase) async {
    final syncKey = await getSyncKey(uid);

    // Generate a random salt
    final random = Random.secure();
    final salt = Uint8List.fromList(
      List.generate(32, (_) => random.nextInt(256)),
    );

    // Derive wrapping key from passphrase using PBKDF2-like approach
    final wrappingKey = _deriveKey(passphrase, salt);

    // XOR encrypt the sync key with the wrapping key
    final encryptedKey = _xorBytes(syncKey, wrappingKey);

    // Store in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('keychain')
        .doc('master')
        .set({
      'encryptedSyncKey': base64Url.encode(encryptedKey),
      'salt': base64Url.encode(salt),
      'keyCreatedAt': FieldValue.serverTimestamp(),
    });

    await _secureStorage.write(
      key: '$_passphraseSetKey$uid',
      value: 'true',
    );
  }

  /// Recover the sync key from Firestore using the passphrase.
  /// Called when user signs in on a new device.
  Future<bool> recoverSyncKey(String uid, String passphrase) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('keychain')
          .doc('master')
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final encryptedKey = base64Url.decode(data['encryptedSyncKey'] as String);
      final salt = base64Url.decode(data['salt'] as String);

      // Derive the same wrapping key
      final wrappingKey = _deriveKey(passphrase, salt);

      // Decrypt the sync key
      final syncKey = _xorBytes(Uint8List.fromList(encryptedKey), wrappingKey);

      // Store locally
      await _secureStorage.write(
        key: '$_syncKeyPrefix$uid',
        value: base64Url.encode(syncKey),
      );
      _cachedKey = syncKey;
      _cachedUid = uid;

      return true;
    } catch (e) {
      debugPrint('Error recovering sync key: $e');
      return false;
    }
  }

  /// Encrypt a string value for storage in Firestore.
  Future<String> encrypt(String plaintext, String uid) async {
    if (plaintext.isEmpty) return '';
    final key = await getSyncKey(uid);
    final bytes = utf8.encode(plaintext);
    final encrypted = _xorBytes(Uint8List.fromList(bytes), key);
    return base64Url.encode(encrypted);
  }

  /// Decrypt a string value from Firestore.
  Future<String> decrypt(String ciphertext, String uid) async {
    if (ciphertext.isEmpty) return '';
    try {
      final key = await getSyncKey(uid);
      final encrypted = base64Url.decode(ciphertext);
      final decrypted = _xorBytes(Uint8List.fromList(encrypted), key);
      return utf8.decode(decrypted);
    } catch (e) {
      debugPrint('Decryption failed: $e');
      return '';
    }
  }

  /// Derive a 32-byte key from a passphrase and salt using iterated HMAC-SHA256.
  Uint8List _deriveKey(String passphrase, Uint8List salt) {
    final passphraseBytes = utf8.encode(passphrase);
    var key = Uint8List.fromList([...passphraseBytes, ...salt]);

    // Iterate HMAC-SHA256 for key strengthening
    for (int i = 0; i < 10000; i++) {
      final hmacSha256 = Hmac(sha256, key);
      final digest = hmacSha256.convert(salt);
      key = Uint8List.fromList(digest.bytes);
    }

    return key.sublist(0, 32);
  }

  /// XOR two byte arrays. The key is repeated if shorter than data.
  Uint8List _xorBytes(Uint8List data, Uint8List key) {
    final result = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      result[i] = data[i] ^ key[i % key.length];
    }
    return result;
  }

  /// Clear cached key (on sign out).
  void clearCache() {
    _cachedKey = null;
    _cachedUid = null;
  }
}
