/// POST /api/auth/kakao/login 응답(AuthTokenResponse) 모델.
class AuthToken {
  final String accessToken;
  final int expiresInSeconds;

  const AuthToken({
    required this.accessToken,
    required this.expiresInSeconds,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['accessToken'] as String,
      expiresInSeconds: (json['expiresInSeconds'] as num).toInt(),
    );
  }
}
