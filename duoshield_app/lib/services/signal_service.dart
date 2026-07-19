import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../security/secure_prefs.dart';
import '../core/constants.dart';

class SignalService {
  static Future<void> rotateSignedPreKeyIfNeeded() async {
    final rotatedAtStr = await SecurePrefs.instance.get(AppConstants.prefSpkRotatedAt);
    if (rotatedAtStr != null) {
      final rotatedAt = int.tryParse(rotatedAtStr) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final daysSince = (now - rotatedAt) / (1000 * 60 * 60 * 24);
      if (daysSince < AppConstants.spkRotationDays) return;
    }
    await _generateAndUploadSignedPreKey();
  }

  static Future<void> checkAndReplenishPreKeys() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('identities')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data == null) return;
      final preKeys = (data['preKeys'] as List?)?.length ?? 0;
      if (preKeys < AppConstants.preKeyThreshold) {
        await _generateAndUploadPreKeys();
      }
    } catch (_) {}
  }

  static Future<void> _generateAndUploadPreKeys() async {
    final nextIdStr = await SecurePrefs.instance.get(AppConstants.prefSignalPreKeyNextId);
    int nextId = int.tryParse(nextIdStr ?? '1') ?? 1;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final rng = Random.secure();
    final newPreKeys = <Map<String, dynamic>>[];
    for (int i = 0; i < AppConstants.preKeyBatchSize; i++) {
      final id = nextId + i;
      final keyBytes = Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
      newPreKeys.add({
        'id': id,
        'publicKey': base64.encode(keyBytes),
      });
    }
    nextId += AppConstants.preKeyBatchSize;
    await SecurePrefs.instance.set(AppConstants.prefSignalPreKeyNextId, nextId.toString());

    await FirebaseFirestore.instance.collection('identities').doc(uid).update({
      'preKeys': FieldValue.arrayUnion(newPreKeys),
    });
  }

  static Future<void> _generateAndUploadSignedPreKey() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final rng = Random.secure();
    final keyBytes = Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
    final sigBytes = Uint8List.fromList(List.generate(64, (_) => rng.nextInt(256)));
    final spk = {
      'id': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'publicKey': base64.encode(keyBytes),
      'signature': base64.encode(sigBytes),
    };
    await FirebaseFirestore.instance
        .collection('identities')
        .doc(uid)
        .update({'signedPreKey': spk});
    await SecurePrefs.instance.set(
        AppConstants.prefSpkRotatedAt,
        DateTime.now().millisecondsSinceEpoch.toString());
  }
}
