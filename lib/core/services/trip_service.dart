import 'dart:convert';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/trip_session.dart';
import 'token_storage.dart';

/// 백엔드가 여행 세션 생성 요청을 거절했을 때(.env 미설정, 잘못된 파일 등) 던진다.
class TripException implements Exception {
  final int statusCode;
  final String message;
  const TripException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class TripService {
  static const String _logName = 'TripService';

  final TokenStorage _tokenStorage;

  TripService({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage();

  static String _env(String key) {
    if (!dotenv.isInitialized) return '';
    return (dotenv.env[key] ?? '').trim();
  }

  static String get _baseUrl => _env('API_BASE_URL');

  void _log(String message) => developer.log(message, name: _logName);

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// 여행 이름/기간과 보험 증권 PDF로 여행 세션을 만든다.
  /// 약관은 이 요청에 포함되지 않고, 이후 별도의 문서 업로드 API로 올린다.
  Future<TripSession> createTrip({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required PlatformFile file,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const TripException(0, '.env에 API_BASE_URL이 설정되어 있지 않습니다.');
    }
    if (file.path == null) {
      throw const TripException(0, '파일을 다시 선택해 주세요.');
    }

    _log('여행 세션 생성 요청 시작');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/v1/trips'),
    )
      ..files.add(
        http.MultipartFile.fromString(
          'trip',
          jsonEncode({
            'name': name,
            'startDate': _formatDate(startDate),
            'endDate': _formatDate(endDate),
          }),
          contentType: MediaType('application', 'json'),
        ),
      )
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ),
      );

    final accessToken = await _tokenStorage.readValid();
    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    _log('여행 세션 생성 응답 statusCode=${response.statusCode}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      _log('여행 세션 생성 실패 body=${response.body}');
      throw TripException(response.statusCode, _errorMessage(response));
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    // 응답이 {"trip": {...}, "document": {...}} 형태로 오므로 trip만 꺼내 쓴다.
    final tripJson = json['trip'] as Map<String, dynamic>;
    _log('여행 세션 생성 성공 id=${tripJson['id']}');
    return TripSession.fromJson(tripJson);
  }

  /// 내가 만든 여행 세션 목록을 최신순 그대로 받아온다.
  Future<List<TripSession>> listTrips() async {
    if (_baseUrl.isEmpty) {
      throw const TripException(0, '.env에 API_BASE_URL이 설정되어 있지 않습니다.');
    }

    _log('여행 세션 목록 조회 요청 시작');

    final headers = <String, String>{};
    final accessToken = await _tokenStorage.readValid();
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/trips'),
      headers: headers,
    );

    _log('여행 세션 목록 조회 응답 statusCode=${response.statusCode}');

    if (response.statusCode != 200) {
      _log('여행 세션 목록 조회 실패 body=${response.body}');
      throw TripException(response.statusCode, _errorMessage(response));
    }

    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return list
        .map((e) => TripSession.fromJson(e as Map<String, dynamic>))
        .toList();
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
    return '여행 세션을 만드는 데 실패했습니다 (${response.statusCode})';
  }
}
