import 'dart:typed_data';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'app_database.dart';

class SignalStoreDao {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<void> saveSession(String address, Uint8List sessionData) async {
    final db = await _db;
    await db.insert('signal_sessions', {
      'address': address,
      'session_data': sessionData,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Uint8List?> loadSession(String address) async {
    final db = await _db;
    final rows = await db.query('signal_sessions', where: 'address = ?', whereArgs: [address]);
    if (rows.isEmpty) return null;
    return rows.first['session_data'] as Uint8List?;
  }

  Future<void> deleteSession(String address) async {
    final db = await _db;
    await db.delete('signal_sessions', where: 'address = ?', whereArgs: [address]);
  }

  Future<void> savePreKey(int id, Uint8List keyData) async {
    final db = await _db;
    await db.insert('signal_prekeys', {'id': id, 'key_data': keyData},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Uint8List?> loadPreKey(int id) async {
    final db = await _db;
    final rows = await db.query('signal_prekeys', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return rows.first['key_data'] as Uint8List?;
  }

  Future<void> deletePreKey(int id) async {
    final db = await _db;
    await db.delete('signal_prekeys', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countPreKeys() async {
    final db = await _db;
    final rows = await db.query('signal_prekeys');
    return rows.length;
  }

  Future<void> saveSignedPreKey(int id, Uint8List keyData) async {
    final db = await _db;
    await db.insert('signal_signed_prekeys', {
      'id': id,
      'key_data': keyData,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Uint8List?> loadSignedPreKey(int id) async {
    final db = await _db;
    final rows = await db.query('signal_signed_prekeys', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return rows.first['key_data'] as Uint8List?;
  }

  Future<void> saveIdentity(String address, Uint8List identityKey, {bool verified = false}) async {
    final db = await _db;
    await db.insert('signal_identities', {
      'address': address,
      'identity_key': identityKey,
      'verified': verified ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Uint8List?> loadIdentity(String address) async {
    final db = await _db;
    final rows = await db.query('signal_identities', where: 'address = ?', whereArgs: [address]);
    if (rows.isEmpty) return null;
    return rows.first['identity_key'] as Uint8List?;
  }

  Future<void> setVerified(String address, bool verified) async {
    final db = await _db;
    await db.update('signal_identities', {'verified': verified ? 1 : 0},
        where: 'address = ?', whereArgs: [address]);
  }

  Future<bool> isVerified(String address) async {
    final db = await _db;
    final rows = await db.query('signal_identities', where: 'address = ?', whereArgs: [address]);
    if (rows.isEmpty) return false;
    return (rows.first['verified'] as int? ?? 0) == 1;
  }
}
