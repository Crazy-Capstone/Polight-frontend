import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../app_log.dart';
import '../models/chat_answer.dart';
import 'token_storage.dart';

/// 챗봇 요청이 실패했을 때 던진다. AI 서버가 응답하지 못하면 502가 온다.
class ChatException implements Exception {
  final int statusCode;
  final String message;
  const ChatException(this.statusCode, this.message);

  /// 502는 AI 서버가 답을 만들지 못한 경우다. 이때도 질문은 서버에 저장되어 있다.
  bool get isAiUnavailable => statusCode == 502;

  @override
  String toString() => message;
}

class ChatService {
  static const String _logName = 'ChatService';

  /// AI 서버의 답변 생성을 기다리는 API라 응답까지 수 초가 걸린다.
  static const Duration _askTimeout = Duration(seconds: 120);

  final TokenStorage _tokenStorage;

  ChatService({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage();

  static String _env(String key) {
    if (!dotenv.isInitialized) return '';
    return (dotenv.env[key] ?? '').trim();
  }

  static String get _baseUrl => _env('API_BASE_URL');

  /// 웹은 HTTPS 페이지에서 HTTP 백엔드를 직접 부르면 Mixed Content로 막히므로
  /// 같은 오리진 상대 경로로 보내고 vercel.json의 /api rewrite가 프록시한다.
  static String get _requestOrigin => kIsWeb ? '' : _baseUrl;

  void _log(String message) => appLog(_logName, message);

  Future<Map<String, String>> _headers({bool json = false}) async {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    final accessToken = await _tokenStorage.readValid();
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  /// 이 여행의 대화 이력을 오래된 것부터 불러온다.
  /// 대화가 없으면 sessionId가 null이고 messages는 빈 목록이며, 오류가 아니다.
  ///
  /// [limit]은 최근 몇 개를 받을지(서버 기본 50, 최대 200). 범위를 벗어난 값은
  /// 서버가 맞춰준다. 더 오래된 대화를 이어 받는 커서는 아직 없다.
  Future<ChatHistory> getHistory({
    required String tripId,
    int? limit,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const ChatException(0, '.env에 API_BASE_URL이 설정되어 있지 않습니다.');
    }

    _log('대화 이력 조회 요청 tripId=$tripId limit=${limit ?? '기본값'}');

    final response = await http.get(
      Uri.parse(
        '$_requestOrigin/api/v1/trips/$tripId/chat/messages'
        '${limit == null ? '' : '?limit=$limit'}',
      ),
      headers: await _headers(),
    );

    _log('대화 이력 조회 응답 statusCode=${response.statusCode}');

    if (response.statusCode != 200) {
      _log('대화 이력 조회 실패 body=${response.body}');
      throw ChatException(response.statusCode, _errorMessage(response));
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final history = ChatHistory.fromJson(json);
    _log('대화 이력 조회 성공 sessionId=${history.sessionId}'
        ' messages=${history.messages.length}건');
    return history;
  }

  /// 챗봇에 질문한다. 여행에 올린 약관을 근거로 답변이 온다.
  /// 대화 세션은 여행당 하나로 서버가 알아서 만들고 재사용한다.
  Future<ChatAnswer> ask({
    required String tripId,
    required String question,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const ChatException(0, '.env에 API_BASE_URL이 설정되어 있지 않습니다.');
    }

    _log('질문 전송 tripId=$tripId question=$question');

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_requestOrigin/api/v1/trips/$tripId/chat/messages'),
            headers: await _headers(json: true),
            body: jsonEncode({'question': question}),
          )
          .timeout(_askTimeout);
    } catch (e) {
      _log('질문 전송 중 예외: $e');
      throw const ChatException(0, '답변을 받지 못했어요. 잠시 후 다시 시도해 주세요.');
    }

    _log('질문 응답 statusCode=${response.statusCode}');

    if (response.statusCode != 200) {
      _log('질문 실패 body=${response.body}');
      throw ChatException(response.statusCode, _errorMessage(response));
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final answer = ChatAnswer.fromJson(json);
    _log('질문 응답 성공 responseType=${answer.responseType}'
        ' sources=${answer.sources.length}건');
    return answer;
  }

  String _errorMessage(http.Response response) {
    if (response.statusCode == 502) {
      return 'AI 서버가 답변을 만들지 못했어요. 잠시 후 다시 물어봐 주세요.';
    }
    try {
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final message = body['message'];
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {
      // 에러 응답이 JSON이 아니면 아래 기본 문구로 대체한다
    }
    return '답변을 받지 못했어요 (${response.statusCode})';
  }
}
