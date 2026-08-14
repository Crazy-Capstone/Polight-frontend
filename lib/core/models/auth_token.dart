/// POST /api/auth/kakao/login 응답(AuthTokenResponse) 모델.
///
/// nickname/profileImageUrl은 백엔드가 아직 내려주지 않을 수 있어 nullable로 둔다.
/// 백엔드가 필드를 추가하는 즉시(응답에 포함되는 즉시) 별도 코드 변경 없이 채워진다.
class AuthToken {
  final String accessToken;
  final int expiresInSeconds;
  final String? nickname;
  final String? profileImageUrl;

  const AuthToken({
    required this.accessToken,
    required this.expiresInSeconds,
    this.nickname,
    this.profileImageUrl,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['accessToken'] as String,
      expiresInSeconds: (json['expiresInSeconds'] as num).toInt(),
      nickname: json['nickname'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
