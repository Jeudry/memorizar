import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacén cifrado para secretos de sesión (token bearer + JSON del usuario).
///
/// En macOS/iOS usa el Keychain; en Android, EncryptedSharedPreferences. Antes
/// estos valores vivían en SharedPreferences en texto plano — ver
/// [migrateFromPrefs] para el traspaso único.
class SecureStore {
  SecureStore._();
  static final SecureStore instance = SecureStore._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      // El backend de keychain puede fallar en entornos sin entitlement;
      // tratamos como "sin valor" para no romper el arranque.
      return null;
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }
}
