import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive_ce.dart';

/// Holds the AES keys that encrypt on-device boxes. Keys never leave the
/// platform keystore (Keychain / Android Keystore).
abstract interface class CipherKeyStore {
  /// The 256-bit key named [name], created on first use.
  Future<List<int>> loadOrCreate(String name);

  Future<void> delete(String name);
}

final class SecureCipherKeyStore implements CipherKeyStore {
  const SecureCipherKeyStore(this._storage);

  final FlutterSecureStorage _storage;

  static String _storageKey(String name) => 'cipher.$name';

  @override
  Future<List<int>> loadOrCreate(String name) async {
    final stored = await _storage.read(key: _storageKey(name));
    if (stored != null) {
      final decoded = _tryDecode(stored);
      if (decoded != null) return decoded;
      // A corrupt key cannot decrypt anything; refuse rather than silently
      // replacing it, which would make existing data unreadable.
      throw StateError('Stored cipher key "$name" is malformed.');
    }
    final key = Hive.generateSecureKey();
    await _storage.write(key: _storageKey(name), value: base64Encode(key));
    return key;
  }

  @override
  Future<void> delete(String name) => _storage.delete(key: _storageKey(name));

  static List<int>? _tryDecode(String value) {
    try {
      final bytes = base64Decode(value);
      return bytes.length == 32 ? bytes : null;
    } on FormatException {
      return null;
    }
  }
}

/// Opens encrypted `Box<String>`s with a key from [CipherKeyStore].
final class EncryptedBoxOpener {
  const EncryptedBoxOpener(this._keys);

  final CipherKeyStore _keys;

  static const _keyName = 'device';

  Future<Box<String>> open(String name) async {
    final key = await _keys.loadOrCreate(_keyName);
    return Hive.openBox<String>(name, encryptionCipher: HiveAesCipher(key));
  }
}
