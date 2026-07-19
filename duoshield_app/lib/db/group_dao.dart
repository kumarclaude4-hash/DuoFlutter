import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import 'app_database.dart';

class GroupDao {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<void> insertGroup(Group group) async {
    final db = await _db;
    await db.insert('groups', group.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Group>> getAllGroups() async {
    final db = await _db;
    final rows = await db.query('groups', orderBy: 'lastMessageTs DESC');
    return rows.map(Group.fromMap).toList();
  }

  Future<Group?> getGroupById(String id) async {
    final db = await _db;
    final rows = await db.query('groups', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Group.fromMap(rows.first);
  }

  Future<void> insertMember(GroupMember member) async {
    final db = await _db;
    await db.insert('group_members', member.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<GroupMember>> getMembersByGroup(String groupId) async {
    final db = await _db;
    final rows = await db.query('group_members', where: 'groupId = ?', whereArgs: [groupId]);
    return rows.map(GroupMember.fromMap).toList();
  }

  Future<void> deleteMember(String groupId, String memberUid) async {
    final db = await _db;
    await db.delete('group_members', where: 'groupId = ? AND memberUid = ?', whereArgs: [groupId, memberUid]);
  }

  Future<void> deleteGroup(String id) async {
    final db = await _db;
    await db.delete('groups', where: 'id = ?', whereArgs: [id]);
    await db.delete('group_members', where: 'groupId = ?', whereArgs: [id]);
  }
}
