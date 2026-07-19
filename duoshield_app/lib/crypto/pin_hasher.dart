import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:convert/convert.dart';

class PinHasher {
  static const int _iterations = 310000;
  static const int _keyLength = 32;
  static const int _saltLength = 16;

  static String hashPin(String pin) {
    final salt = _secureRandom(_saltLength);
    final hash = _pbkdf2(utf8.encode(pin), salt, _iterations, _keyLength);
    return '${hex.encode(salt)}:${hex.encode(hash)}';
  }

  static bool verifyPin(String pin, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final salt = hex.decode(parts[0]);
    final expectedHash = hex.decode(parts[1]);
    final actualHash = _pbkdf2(utf8.encode(pin), salt, _iterations, _keyLength);
    return _constantTimeEquals(actualHash, expectedHash);
  }

  static Uint8List _pbkdf2(List<int> password, List<int> salt, int iterations, int keyLength) {
    final params = pc.Pbkdf2Parameters(
      Uint8List.fromList(salt),
      iterations,
      keyLength,
    );
    final pbkdf2 = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64));
    pbkdf2.init(params);
    return pbkdf2.process(Uint8List.fromList(password));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  static Uint8List _secureRandom(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rng.nextInt(256)));
  }
}
