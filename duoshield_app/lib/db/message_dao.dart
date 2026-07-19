import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/message.dart';
import 'app_database.dart';

class MessageDao {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<void> insert(Message message) async {
    final db = await _db;
    await db.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertAll(List<Message> messages) async {
    final db = await _db;
    final batch = db.batch();
    for (final m in messages) {
      batch.insert('messages', m.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Message>> getByChat(String chatId) async {
    final db = await _db;
    final rows = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(Message.fromMap).toList();
  }

  Future<void> update(String id, Map<String, dynamic> values) async {
    final db = await _db;
    await db.update('messages', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllByChat(String chatId) async {
    final db = await _db;
    await db.delete('messages', where: 'chatId = ?', whereArgs: [chatId]);
  }

  Future<List<Message>> getAll() async {
    final db = await _db;
    final rows = await db.query('messages', orderBy: 'timestamp ASC');
    return rows.map(Message.fromMap).toList();
  }
}
