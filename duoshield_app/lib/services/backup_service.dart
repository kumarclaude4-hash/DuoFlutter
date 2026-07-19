import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../crypto/backup_crypto_helper.dart';
import '../crypto/seed_phrase_helper.dart';
import '../db/message_dao.dart';
import '../models/message.dart';
import '../security/secure_prefs.dart';
import '../core/constants.dart';

class BackupService {
  final MessageDao _messageDao = MessageDao();

  Future<void> createBackup(String mnemonic) async {
    final messages = await _messageDao.getAll();
    final jsonList = messages.map((m) => m.toMap()).toList();
    final jsonBytes = Uint8List.fromList(utf8.encode(jsonEncode(jsonList)));

    final backupKey = SeedPhraseHelper.deriveBackupKey(mnemonic);
    final encrypted = BackupCryptoHelper.encrypt(backupKey, jsonBytes);

    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${dir.path}/duoshield_backup_$ts.dsbak';
    final file = File(filePath);
    await file.writeAsBytes(encrypted);

    await Share.shareXFiles([XFile(filePath)], text: 'DuoShield Backup');
    await SecurePrefs.instance.set(
        AppConstants.prefLastBackupDate,
        DateTime.now().millisecondsSinceEpoch.toString());
  }

  Future<int> importBackup(String mnemonic) async {
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['dsbak'],
      type: FileType.custom,
    );
    if (result == null || result.files.isEmpty) return 0;

    final file = File(result.files.first.path!);
    final encrypted = await file.readAsBytes();

    final backupKey = SeedPhraseHelper.deriveBackupKey(mnemonic);
    final decrypted = BackupCryptoHelper.decrypt(backupKey, encrypted);
    if (decrypted == null) throw Exception('Failed to decrypt backup');

    final jsonList = jsonDecode(utf8.decode(decrypted)) as List;
    int count = 0;
    for (final item in jsonList) {
      try {
        final m = Message.fromMap(item as Map<String, dynamic>);
        await _messageDao.insert(m);
        count++;
      } catch (_) {}
    }
    return count;
  }
}
