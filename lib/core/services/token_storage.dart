import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_token.dart';

/// 로그인 후 발급받은 JWT를 기기의 보안 저장소(Keychain/Keystore)에 보관한다.
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _expiresAtKey = 'access_token_expires_at';

  Future<void> save(AuthToken token) async {
    final expiresAt = DateTime.now().add(
      Duration(seconds: token.expiresInSeconds),
    );
    await _storage.write(key: _accessTokenKey, value: token.accessToken);
    await _storage.write(
      key: _expiresAtKey,
      value: expiresAt.toIso8601String(),
    );
  }

  /// 만료되지 않은 access token이 있으면 반환하고, 없거나 만료됐으면 null.
  Future<String?> readValid() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null) return null;

    final expiresAtRaw = await _storage.read(key: _expiresAtKey);
    final expiresAt = expiresAtRaw != null
        ? DateTime.tryParse(expiresAtRaw)
        : null;
    if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
      return null;
    }
    return token;
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _expiresAtKey);
  }
}
