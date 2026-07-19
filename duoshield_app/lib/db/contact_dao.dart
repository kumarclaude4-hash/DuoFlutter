import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/contact.dart';
import 'app_database.dart';

class ContactDao {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<void> insert(Contact contact) async {
    final db = await _db;
    await db.insert(
      'contacts',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Contact>> getAll() async {
    final db = await _db;
    final rows = await db.query('contacts', orderBy: 'displayName ASC');
    return rows.map(Contact.fromMap).toList();
  }

  Future<Contact?> getByUid(String uid) async {
    final db = await _db;
    final rows = await db.query('contacts', where: 'uid = ?', whereArgs: [uid]);
    if (rows.isEmpty) return null;
    return Contact.fromMap(rows.first);
  }

  Future<void> update(String uid, Map<String, dynamic> values) async {
    final db = await _db;
    await db.update('contacts', values, where: 'uid = ?', whereArgs: [uid]);
  }

  Future<void> delete(String uid) async {
    final db = await _db;
    await db.delete('contacts', where: 'uid = ?', whereArgs: [uid]);
  }
}
