// 임시 검증용 테스트 (카카오 로그인 연동 확인 후 삭제).
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:polight_frontend/core/models/auth_token.dart';
import 'package:polight_frontend/core/services/auth_service.dart';
import 'package:polight_frontend/core/services/token_storage.dart';

/// AuthService.loginWithKakao가 TokenStorage에 접근하지 않고 실패하는지 확인할 때
/// 사용하는 더미. flutter_secure_storage는 플랫폼 채널이 필요해 순수 Dart 테스트에서
/// 호출되면 안 되므로, 호출되면 바로 실패하도록 만든다.
class _UnusedTokenStorage implements TokenStorage {
  @override
  Future<void> save(AuthToken token) async {
    fail('토큰 저장이 호출되면 안 되는 상황에서 저장이 시도됐습니다');
  }

  @override
  Future<String?> readValid() async => null;

  @override
  Future<UserProfile> readProfile() async => UserProfile.empty;

  @override
  Future<void> clear() async {}
}

void main() {
  group('AuthToken.fromJson', () {
    test('Swagger 응답 형태(accessToken, expiresInSeconds)를 그대로 읽는다', () {
      final token = AuthToken.fromJson({
        'accessToken': 'eyJhbGciOiJIUzI1NiJ9...',
        'expiresInSeconds': 3600,
      });

      expect(token.accessToken, 'eyJhbGciOiJIUzI1NiJ9...');
      expect(token.expiresInSeconds, 3600);
      // 백엔드가 아직 안 내려주는 필드라 지금은 null이어야 한다
      expect(token.nickname, isNull);
      expect(token.profileImageUrl, isNull);
    });

    test('백엔드가 nickname/profileImageUrl을 추가로 내려주면 그대로 읽는다', () {
      final token = AuthToken.fromJson({
        'accessToken': 'eyJhbGciOiJIUzI1NiJ9...',
        'expiresInSeconds': 3600,
        'nickname': '류지',
        'profileImageUrl': 'https://k.kakaocdn.net/dn/profile.jpg',
      });

      expect(token.nickname, '류지');
      expect(token.profileImageUrl, 'https://k.kakaocdn.net/dn/profile.jpg');
    });
  });

  group('AuthService.buildKakaoAuthorizeUri', () {
    test('.env가 아직 로드되지 않았으면 KakaoConfigException을 던진다', () {
      // dotenv.load()를 호출하지 않은 상태 = 앱이 아직 .env를 읽지 않은 상태와 동일
      expect(
        () => AuthService().buildKakaoAuthorizeUri(),
        throwsA(isA<KakaoConfigException>()),
      );
    });

    test('REST API 키/redirect_uri가 설정되면 카카오 인가 URL을 정확히 만든다', () {
      dotenv.testLoad(
        fileInput: '''
KAKAO_REST_API_KEY=test-rest-api-key
KAKAO_REDIRECT_URI=https://polight.example.com/oauth/kakao/callback
''',
      );
      addTearDown(() => dotenv.clean());

      final uri = AuthService().buildKakaoAuthorizeUri();

      expect(uri.scheme, 'https');
      expect(uri.host, 'kauth.kakao.com');
      expect(uri.path, '/oauth/authorize');
      expect(uri.queryParameters['client_id'], 'test-rest-api-key');
      expect(
        uri.queryParameters['redirect_uri'],
        'https://polight.example.com/oauth/kakao/callback',
      );
      expect(uri.queryParameters['response_type'], 'code');
    });

    test('REST API 키만 비어 있어도 설정 오류로 취급한다', () {
      dotenv.testLoad(
        fileInput: 'KAKAO_REDIRECT_URI=https://polight.example.com/callback',
      );
      addTearDown(() => dotenv.clean());

      expect(
        () => AuthService().buildKakaoAuthorizeUri(),
        throwsA(isA<KakaoConfigException>()),
      );
    });
  });

  group('AuthService.loginWithKakao (실제 백엔드 호출)', () {
    // 실서버(52.78.29.250)에 실제로 요청을 보내 요청 형태(JSON body의
    // authorizationCode 필드, 경로 /api/auth/kakao/login)가 서버 스펙과
    // 맞는지 확인한다. 가짜 인가 코드이므로 401을 기대한다 — 200이 오면
    // 오히려 이상한 상황이다. 네트워크가 필요한 임시 확인용 테스트다.
    test(
      '가짜 인가 코드를 보내면 서버가 이해하고 401로 거절한다(엔드포인트·요청 형태 검증)',
      () async {
        dotenv.testLoad(fileInput: 'API_BASE_URL=http://52.78.29.250');
        addTearDown(() => dotenv.clean());

        final authService = AuthService(tokenStorage: _UnusedTokenStorage());

        await expectLater(
          authService.loginWithKakao('obviously-fake-code-for-contract-check'),
          throwsA(
            isA<AuthException>()
                .having((e) => e.statusCode, 'statusCode', 401)
                .having((e) => e.message, 'message', isNotEmpty),
          ),
        );
      },
    );
  });
}
