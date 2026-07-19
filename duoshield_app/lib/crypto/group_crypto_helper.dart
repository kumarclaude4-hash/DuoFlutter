import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart' as pc;

class GroupCryptoHelper {
  static Uint8List encryptGroup(Uint8List key, Uint8List plaintext) {
    final nonce = _randomBytes(12);
    final cipher = pc.GCMBlockCipher(pc.AESEngine());
    final params = pc.AEADParameters(pc.KeyParameter(key), 128, nonce, Uint8List(0));
    cipher.init(true, params);
    final ciphertext = cipher.process(plaintext);
    return Uint8List.fromList([...nonce, ...ciphertext]);
  }

  static Uint8List? decryptGroup(Uint8List key, Uint8List ciphertext) {
    try {
      if (ciphertext.length < 12 + 16) return null;
      final nonce = ciphertext.sublist(0, 12);
      final encrypted = ciphertext.sublist(12);
      final cipher = pc.GCMBlockCipher(pc.AESEngine());
      final params = pc.AEADParameters(pc.KeyParameter(key), 128, nonce, Uint8List(0));
      cipher.init(false, params);
      return cipher.process(encrypted);
    } catch (_) {
      return null;
    }
  }

  static Uint8List generateGroupKey() => _randomBytes(32);

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rng.nextInt(256)));
  }
}
