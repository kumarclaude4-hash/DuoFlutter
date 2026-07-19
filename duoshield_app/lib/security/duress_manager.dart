import 'package:firebase_auth/firebase_auth.dart';
import '../db/app_database.dart';
import 'secure_prefs.dart';
import '../core/constants.dart';

class DuressManager {
  static Future<void> performWipe() async {
    await SecurePrefs.instance.set(AppConstants.prefDuressWipeInProgress, 'true');
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    try {
      final db = await AppDatabase.instance.database;
      await db.execute('DELETE FROM messages');
      await db.execute('DELETE FROM contacts');
      await db.execute('DELETE FROM conversations');
      await db.execute('DELETE FROM groups');
      await db.execute('DELETE FROM group_members');
      await db.execute('DELETE FROM signal_sessions');
      await db.execute('DELETE FROM signal_prekeys');
      await db.execute('DELETE FROM signal_signed_prekeys');
      await db.execute('DELETE FROM signal_identities');
      await db.execute('DELETE FROM call_history');
    } catch (_) {}
    await SecurePrefs.instance.clearAll();
  }
}
