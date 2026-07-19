import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart' as pc;
import 'push_server.dart';

class B2Storage {
  static Future<({String objectKey, String mediaKeyBase64})> uploadMedia(
    String chatId,
    String messageId,
    String filename,
    Uint8List fileBytes,
    String contentType,
    String idToken,
  ) async {
    final mediaKey = _randomBytes(32);
    final encrypted = _encryptAesGcm(mediaKey, fileBytes);
    final objectKey = '$chatId/${messageId}_$filename';
    final presigned = await PushServer.b2PresignedPut(objectKey, contentType, idToken);
    final putUrl = presigned['url'] as String;
    await http.put(
      Uri.parse(putUrl),
      headers: {'Content-Type': contentType},
      body: encrypted,
    );
    final mediaKeyBase64 = base64.encode(mediaKey);
    return (objectKey: objectKey, mediaKeyBase64: mediaKeyBase64);
  }

  static Future<Uint8List?> downloadMedia(
    String objectKey,
    String mediaKeyBase64,
    String idToken,
  ) async {
    try {
      final mediaKey = base64.decode(mediaKeyBase64);
      final getUrl = await PushServer.b2PresignedGet(objectKey, idToken);
      final response = await http.get(Uri.parse(getUrl));
      if (response.statusCode != 200) return null;
      return _decryptAesGcm(mediaKey, response.bodyBytes);
    } catch (_) {
      return null;
    }
  }

  static Uint8List _encryptAesGcm(Uint8List key, Uint8List plaintext) {
    final nonce = _randomBytes(12);
    final cipher = pc.GCMBlockCipher(pc.AESEngine());
    final params = pc.AEADParameters(pc.KeyParameter(key), 128, nonce, Uint8List(0));
    cipher.init(true, params);
    final ciphertext = cipher.process(plaintext);
    return Uint8List.fromList([...nonce, ...ciphertext]);
  }

  static Uint8List? _decryptAesGcm(Uint8List key, Uint8List data) {
    try {
      if (data.length < 12 + 16) return null;
      final nonce = data.sublist(0, 12);
      final ciphertext = data.sublist(12);
      final cipher = pc.GCMBlockCipher(pc.AESEngine());
      final params = pc.AEADParameters(pc.KeyParameter(key), 128, nonce, Uint8List(0));
      cipher.init(false, params);
      return cipher.process(ciphertext);
    } catch (_) {
      return null;
    }
  }

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rng.nextInt(256)));
  }
}
