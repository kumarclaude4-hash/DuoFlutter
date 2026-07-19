import 'dart:convert';
import 'dart:typed_data';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class SignalCipherHelper {
  static final Map<String, SessionCipher> _ciphers = {};

  static SignalProtocolStore? _store;

  static void setStore(SignalProtocolStore store) {
    _store = store;
  }

  static Future<Uint8List?> encrypt(String address, Uint8List plaintext) async {
    try {
      final store = _store;
      if (store == null) return null;
      final signalAddress = SignalProtocolAddress(address, 1);
      final cipher = SessionCipher.fromStore(store, signalAddress);
      final cipherMessage = await cipher.encrypt(plaintext);
      final encoded = base64.encode(cipherMessage.serialize());
      return Uint8List.fromList(utf8.encode(encoded));
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> decrypt(String address, Uint8List ciphertext, int sigType) async {
    try {
      final store = _store;
      if (store == null) return null;
      final signalAddress = SignalProtocolAddress(address, 1);
      final cipher = SessionCipher.fromStore(store, signalAddress);
      final decoded = base64.decode(utf8.decode(ciphertext));
      Uint8List plaintext;
      if (sigType == 3) {
        final preKeyMsg = PreKeySignalMessage(decoded);
        plaintext = await cipher.decrypt(preKeyMsg);
      } else if (sigType == 1) {
        final whisperMsg = SignalMessage.fromSerialized(decoded);
        plaintext = await cipher.decryptFromSignal(whisperMsg);
      } else {
        return null;
      }
      return plaintext;
    } catch (_) {
      return null;
    }
  }

  static Future<void> processPreKeyBundle(
    String address,
    PreKeyBundle bundle,
    SignalProtocolStore store,
  ) async {
    final signalAddress = SignalProtocolAddress(address, 1);
    final sessionBuilder = SessionBuilder.fromSignalStore(store, signalAddress);
    await sessionBuilder.processPreKeyBundle(bundle);
  }
}
