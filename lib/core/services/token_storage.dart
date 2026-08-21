import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_token.dart';

/// 카카오 로그인 응답에서 받은 사용자 표시 정보(닉네임 · 프로필 사진).
class UserProfile {
  final String? nickname;
  final String? profileImageUrl;

  const UserProfile({this.nickname, this.profileImageUrl});

  static const empty = UserProfile();

  /// 화면에 띄울 프로필 사진 주소.
  ///
  /// 카카오 CDN이 `http://`로 주소를 내려주는 경우가 있는데, 웹은 HTTPS 페이지라
  /// 그대로 쓰면 브라우저가 Mixed Content로 차단해서 사진이 안 보인다.
  /// 카카오 CDN은 HTTPS도 지원하므로 https로 올려서 쓴다.
  String? get displayImageUrl {
    final url = profileImageUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }
}

/// 로그인 후 발급받은 JWT와 사용자 표시 정보를
/// 기기의 보안 저장소(Keychain/Keystore)에 보관한다.
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _expiresAtKey = 'access_token_expires_at';
  static const _nicknameKey = 'nickname';
  static const _profileImageUrlKey = 'profile_image_url';

  Future<void> save(AuthToken token) async {
    final expiresAt = DateTime.now().add(
      Duration(seconds: token.expiresInSeconds),
    );
    await _storage.write(key: _accessTokenKey, value: token.accessToken);
    await _storage.write(
      key: _expiresAtKey,
      value: expiresAt.toIso8601String(),
    );
    // 백엔드가 아직 안 내려주면 null이라 기존 값을 그대로 지운다
    // (로그인할 때마다 최신 닉네임/프로필 사진으로 갱신되도록).
    await _writeOrDelete(_nicknameKey, token.nickname);
    await _writeOrDelete(_profileImageUrlKey, token.profileImageUrl);
  }

  Future<void> _writeOrDelete(String key, String? value) {
    if (value == null || value.isEmpty) {
      return _storage.delete(key: key);
    }
    return _storage.write(key: key, value: value);
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

  Future<UserProfile> readProfile() async {
    final nickname = await _storage.read(key: _nicknameKey);
    final profileImageUrl = await _storage.read(key: _profileImageUrlKey);
    return UserProfile(nickname: nickname, profileImageUrl: profileImageUrl);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _expiresAtKey);
    await _storage.delete(key: _nicknameKey);
    await _storage.delete(key: _profileImageUrlKey);
  }
}
