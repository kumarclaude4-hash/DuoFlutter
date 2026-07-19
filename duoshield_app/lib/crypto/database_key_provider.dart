import 'dart:convert';
import 'dart:typed_data';
import 'seed_phrase_helper.dart';

class DatabaseKeyProvider {
  static String getKey(String uid) {
    final ikm = Uint8List.fromList(utf8.encode(uid));
    final info = Uint8List.fromList(utf8.encode('db_key'));
    final keyBytes = SeedPhraseHelper.hkdfSha256(ikm, info, 32);
    return base64.encode(keyBytes);
  }
}
