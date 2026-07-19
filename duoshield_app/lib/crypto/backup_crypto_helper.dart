import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart' as pc;

class BackupCryptoHelper {
  static Uint8List encrypt(Uint8List key, Uint8List plaintext) {
    final nonce = _randomBytes(12);
    final cipher = pc.GCMBlockCipher(pc.AESEngine());
    final params = pc.AEADParameters(pc.KeyParameter(key), 128, nonce, Uint8List(0));
    cipher.init(true, params);
    final ciphertext = cipher.process(plaintext);
    return Uint8List.fromList([...nonce, ...ciphertext]);
  }

  static Uint8List? decrypt(Uint8List key, Uint8List data) {
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
