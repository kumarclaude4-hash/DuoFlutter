import 'dart:convert';
import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart' as pc;

class SeedPhraseHelper {
  static const String _customAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String generateMnemonic() {
    return bip39.generateMnemonic();
  }

  static bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic);
  }

  static ({bool valid, String? error}) validateMnemonicDetailed(String mnemonic) {
    final words = mnemonic.trim().toLowerCase().split(RegExp(r'\s+'));
    if (words.length != 12) {
      return (valid: false, error: 'Please enter exactly 12 words.');
    }
    if (!bip39.validateMnemonic(words.join(' '))) {
      // Find which word is invalid by testing each in isolation
      for (final word in words) {
        if (!bip39.validateMnemonic(List.filled(12, word).join(' '))) {
          return (valid: false, error: 'Invalid word: "$word". Please check your phrase.');
        }
      }
      return (valid: false, error: 'Invalid seed phrase. Please check your words.');
    }
    return (valid: true, error: null);
  }

  static Uint8List mnemonicToSeedBytes(String mnemonic) {
    final seedHex = bip39.mnemonicToSeedHex(mnemonic);
    return _hexToBytes(seedHex);
  }

  static String deriveUserId(String mnemonic) {
    final seed = mnemonicToSeedBytes(mnemonic);
    final first20 = seed.sublist(0, 20);
    final encoded = _encodeBase32Custom(first20);
    return '${encoded.substring(0, 5)}-${encoded.substring(5, 10)}-${encoded.substring(10, 13)}';
  }

  static Uint8List deriveIdentityKeyPrivate(String mnemonic) {
    final seed = mnemonicToSeedBytes(mnemonic);
    final ikm = seed.sublist(0, 32);
    final info = Uint8List.fromList(utf8.encode('identity_key'));
    return hkdfSha256(ikm, info, 32);
  }

  static Uint8List deriveBackupKey(String mnemonic) {
    final seed = mnemonicToSeedBytes(mnemonic);
    final ikm = seed.sublist(0, 32);
    final info = Uint8List.fromList(utf8.encode('backup_key'));
    return hkdfSha256(ikm, info, 32);
  }

  static Uint8List hkdfSha256(Uint8List ikm, Uint8List info, int length) {
    final salt = Uint8List(32);

    final hmacExtract = Hmac(sha256, salt);
    final prk = Uint8List.fromList(hmacExtract.convert(ikm).bytes);

    final hmacExpand = Hmac(sha256, prk);
    final blocks = <int>[];
    Uint8List prev = Uint8List(0);
    int counter = 1;

    while (blocks.length < length) {
      final data = Uint8List.fromList([...prev, ...info, counter]);
      final block = Uint8List.fromList(hmacExpand.convert(data).bytes);
      blocks.addAll(block);
      prev = block;
      counter++;
    }

    return Uint8List.fromList(blocks.sublist(0, length));
  }

  static String _encodeBase32Custom(Uint8List data) {
    final result = StringBuffer();
    int buffer = 0;
    int bitsLeft = 0;

    for (final byte in data) {
      buffer = (buffer << 8) | byte;
      bitsLeft += 8;
      while (bitsLeft >= 5) {
        bitsLeft -= 5;
        result.write(_customAlphabet[(buffer >> bitsLeft) & 0x1F]);
      }
    }

    if (bitsLeft > 0) {
      result.write(_customAlphabet[(buffer << (5 - bitsLeft)) & 0x1F]);
    }

    return result.toString();
  }

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }
}
