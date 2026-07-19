import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/call_record.dart';
import 'app_database.dart';

class CallDao {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<void> insert(CallRecord record) async {
    final db = await _db;
    await db.insert('call_history', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CallRecord>> getAll() async {
    final db = await _db;
    final rows = await db.query('call_history', orderBy: 'startedAt DESC');
    return rows.map(CallRecord.fromMap).toList();
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('call_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('call_history');
  }
}
