import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/conversation.dart';
import 'app_database.dart';

class ConversationDao {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<void> insert(Conversation conv) async {
    final db = await _db;
    await db.insert(
      'conversations',
      conv.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Conversation>> getAll() async {
    final db = await _db;
    final rows = await db.query('conversations', orderBy: 'lastMessageTs DESC');
    return rows.map(Conversation.fromMap).toList();
  }

  Future<Conversation?> getById(String id) async {
    final db = await _db;
    final rows = await db.query('conversations', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Conversation.fromMap(rows.first);
  }

  Future<void> update(String id, Map<String, dynamic> values) async {
    final db = await _db;
    await db.update('conversations', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }
}
