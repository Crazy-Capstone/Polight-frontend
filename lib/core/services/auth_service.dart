import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/auth_token.dart';
import 'token_storage.dart';

/// 카카오 인가 코드로 전달할 리다이렉트 URI를 얻지 못했을 때(=.env 미설정) 던진다.
class KakaoConfigException implements Exception {
  final String message;
  const KakaoConfigException(this.message);

  @override
  String toString() => message;
}

/// 백엔드가 카카오 로그인 요청을 거절했을 때(잘못된/만료된 인가 코드 등) 던진다.
class AuthException implements Exception {
  final int statusCode;
  final String message;
  const AuthException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class AuthService {
  static const String _logName = 'AuthService';

  final TokenStorage _tokenStorage;

  AuthService({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage();

  // dotenv.load()가 아직 호출되지 않았으면(테스트 등) NotInitializedError를 던지므로,
  // 그 경우도 "설정 안 됨"과 동일하게 취급한다.
  static String _env(String key) {
    if (!dotenv.isInitialized) return '';
    return (dotenv.env[key] ?? '').trim();
  }

  static String get _baseUrl => _env('API_BASE_URL');

  static String get kakaoRestApiKey => _env('KAKAO_REST_API_KEY');

  static String get kakaoRedirectUri => _env('KAKAO_REDIRECT_URI');

  void _log(String message) => developer.log(message, name: _logName);

  /// 사용자가 카카오 로그인 동의 화면에서 인증을 마치면 이동하는 인가 URL.
  /// 여기로 브라우저/웹뷰를 열고, redirect_uri 로 돌아올 때 붙는 `code` 파라미터를
  /// 인가 코드로 사용한다.
  Uri buildKakaoAuthorizeUri() {
    if (kakaoRestApiKey.isEmpty || kakaoRedirectUri.isEmpty) {
      throw const KakaoConfigException(
        '.env에 KAKAO_REST_API_KEY / KAKAO_REDIRECT_URI 를 설정해야 카카오 로그인을 시작할 수 있습니다.',
      );
    }
    return Uri.https('kauth.kakao.com', '/oauth/authorize', {
      'client_id': kakaoRestApiKey,
      'redirect_uri': kakaoRedirectUri,
      'response_type': 'code',
    });
  }

  /// 카카오 인가 코드를 백엔드에 전달해 서비스 JWT를 발급받고, 보안 저장소에 저장한다.
  Future<AuthToken> loginWithKakao(String authorizationCode) async {
    if (_baseUrl.isEmpty) {
      throw const KakaoConfigException(
        '.env에 API_BASE_URL이 설정되어 있지 않습니다.',
      );
    }

    _log('카카오 로그인 요청 시작');

    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/kakao/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'authorizationCode': authorizationCode}),
    );

    _log('카카오 로그인 응답 statusCode=${response.statusCode}');

    if (response.statusCode != 200) {
      _log('카카오 로그인 실패 body=${response.body}');
      throw AuthException(response.statusCode, _errorMessage(response));
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes))
        as Map<String, dynamic>;
    final token = AuthToken.fromJson(json);
    await _tokenStorage.save(token);
    _log('카카오 로그인 성공, access token 저장 완료');
    return token;
  }

  /// 백엔드가 `{"code": "...", "message": "..."}` 형태로 보내주는 에러 메시지를
  /// 최대한 그대로 보여주고, 형태가 다르면 상태 코드 기반 문구로 대체한다.
  String _errorMessage(http.Response response) {
    try {
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final message = body['message'];
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {
      // 에러 응답이 JSON이 아니면 아래 기본 문구로 대체한다
    }
    return '카카오 로그인에 실패했습니다 (${response.statusCode})';
  }
}
