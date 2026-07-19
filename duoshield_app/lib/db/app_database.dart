import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import '../crypto/database_key_provider.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._();
  static AppDatabase get instance => _instance;

  Database? _database;
  String? _uid;

  AppDatabase._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    throw Exception('Database not initialized. Call init(uid) first.');
  }

  Future<void> init(String uid) async {
    _uid = uid;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'duoshield.db');
    final key = DatabaseKeyProvider.getKey(uid);

    try {
      _database = await openDatabase(
        path,
        version: 12,
        password: key,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw Exception('Failed to open secure database: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        chatId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        text TEXT,
        mediaUrl TEXT,
        mediaType TEXT,
        mediaKey TEXT,
        timestamp INTEGER NOT NULL,
        status TEXT DEFAULT 'sent',
        deletedForAll INTEGER DEFAULT 0,
        replyToId TEXT,
        reactionBy TEXT,
        edited INTEGER DEFAULT 0,
        editedText TEXT,
        starred INTEGER DEFAULT 0,
        pinned INTEGER DEFAULT 0,
        disappearMs INTEGER,
        sigType INTEGER DEFAULT 0,
        linkPreviewUrl TEXT,
        linkPreviewTitle TEXT,
        linkPreviewImage TEXT
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_chat ON messages(chatId, timestamp DESC)');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS contacts (
        uid TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        displayName TEXT NOT NULL,
        avatarUrl TEXT,
        conversationId TEXT,
        addedAt INTEGER NOT NULL,
        blocked INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id TEXT PRIMARY KEY,
        partnerUid TEXT NOT NULL,
        partnerName TEXT,
        partnerAvatar TEXT,
        lastMessage TEXT,
        lastMessageTs INTEGER DEFAULT 0,
        unreadCount INTEGER DEFAULT 0,
        muted INTEGER DEFAULT 0,
        archived INTEGER DEFAULT 0,
        disappearing INTEGER DEFAULT 0,
        disappearMs INTEGER,
        isGroup INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatarUrl TEXT,
        createdBy TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        groupKey TEXT NOT NULL,
        lastMessage TEXT,
        lastMessageTs INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS group_members (
        groupId TEXT NOT NULL,
        memberUid TEXT NOT NULL,
        displayName TEXT,
        joinedAt INTEGER,
        PRIMARY KEY (groupId, memberUid)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS signal_sessions (
        address TEXT PRIMARY KEY,
        session_data BLOB NOT NULL,
        updated_at INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS signal_prekeys (
        id INTEGER PRIMARY KEY,
        key_data BLOB NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS signal_signed_prekeys (
        id INTEGER PRIMARY KEY,
        key_data BLOB NOT NULL,
        created_at INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS signal_identities (
        address TEXT PRIMARY KEY,
        identity_key BLOB NOT NULL,
        verified INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS call_history (
        id TEXT PRIMARY KEY,
        peerUid TEXT NOT NULL,
        peerName TEXT,
        type TEXT DEFAULT 'audio',
        direction TEXT NOT NULL,
        status TEXT NOT NULL,
        startedAt INTEGER NOT NULL,
        durationSecs INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _onCreate(db, newVersion);
  }

  Future<void> clearAll() async {
    final db = _database;
    if (db == null) return;
    for (final table in [
      'messages', 'contacts', 'conversations', 'groups',
      'group_members', 'signal_sessions', 'signal_prekeys',
      'signal_signed_prekeys', 'signal_identities', 'call_history'
    ]) {
      await db.delete(table);
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
