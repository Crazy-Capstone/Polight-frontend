import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../app_log.dart';
import '../models/coverage_result.dart';
import '../models/trip_analysis.dart';
import '../models/trip_document.dart';
import '../models/trip_session.dart';
import 'token_storage.dart';

/// POST /api/v1/trips 응답 전체. trip.id와 document.id로 분석 시작 API를 호출한다.
class TripCreationResult {
  final TripSession trip;
  final TripDocument document;

  const TripCreationResult({required this.trip, required this.document});
}

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

  /// 실제 요청에 붙일 origin. 웹은 HTTPS로 떠 있는데 백엔드가 아직 HTTP라
  /// Mixed Content로 막히므로, 같은 오리진의 상대 경로로 요청하고
  /// vercel.json의 /api rewrite가 서버사이드에서 실제 백엔드로 프록시한다.
  /// (모바일은 이 제약이 없어 .env의 절대 주소를 그대로 쓴다.)
  static String get _requestOrigin => kIsWeb ? '' : _baseUrl;

  void _log(String message) => appLog(_logName, message);

  /// 백엔드 응답에 담긴 필드를 빠짐없이 보기 위해 원본 JSON을 그대로 찍는다.
  void _logBody(String label, dynamic json) {
    _log('$label body=${const JsonEncoder.withIndent('  ').convert(json)}');
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// 여행 이름/기간과 보험 문서(PDF)로 여행 세션을 만든다.
  /// documentKind를 생략하면 백엔드가 CERTIFICATE(증권)로 처리한다.
  /// 응답의 trip.id와 document.id로 이어서 분석 시작 API를 호출한다.
  Future<TripCreationResult> createTrip({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required PlatformFile file,
    String? documentKind,
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
      Uri.parse('$_requestOrigin/api/v1/trips'),
    )
      ..files.add(
        http.MultipartFile.fromString(
          'trip',
          jsonEncode({
            'name': name,
            'startDate': _formatDate(startDate),
            'endDate': _formatDate(endDate),
            if (documentKind != null) 'documentKind': documentKind,
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
    _logBody('여행 세션 생성 성공', json);
    final tripJson = json['trip'] as Map<String, dynamic>;
    final documentJson = json['document'] as Map<String, dynamic>;
    return TripCreationResult(
      trip: TripSession.fromJson(tripJson),
      document: TripDocument.fromJson(documentJson),
    );
  }

  /// 문서 분석을 시작한다. 증권은 업로드 시점에 자동으로 분석이 시작되므로,
  /// 이 API는 DB에 없어 사용자가 새로 올린 약관의 분석을 시작할 때만 쓴다.
  /// 이미 분석 중인 문서에 다시 호출하면 재분석 없이 기존 작업을 그대로 반환한다.
  Future<TripAnalysis> startAnalysis({
    required String tripId,
    required String documentId,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const TripException(0, '.env에 API_BASE_URL이 설정되어 있지 않습니다.');
    }

    _log('문서 분석 시작 요청 tripId=$tripId documentId=$documentId');

    final headers = <String, String>{};
    final accessToken = await _tokenStorage.readValid();
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final response = await http.post(
      Uri.parse('$_requestOrigin/api/v1/trips/$tripId/documents/$documentId/analysis'),
      headers: headers,
    );

    _log('문서 분석 시작 응답 statusCode=${response.statusCode}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      _log('문서 분석 시작 실패 body=${response.body}');
      throw TripException(response.statusCode, _errorMessage(response));
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    _logBody('문서 분석 시작 성공', json);
    return TripAnalysis.fromJson(json);
  }

  /// 문서 분석 상태와 결과를 조회한다. 분석 중에는 상태 확인을 위해 이 API로 폴링한다.
  Future<TripAnalysis> getAnalysis({
    required String tripId,
    required String documentId,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const TripException(0, '.env에 API_BASE_URL이 설정되어 있지 않습니다.');
    }

    _log('문서 분석 상태 조회 요청 tripId=$tripId documentId=$documentId');

    final headers = <String, String>{};
    final accessToken = await _tokenStorage.readValid();
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final response = await http.get(
      Uri.parse('$_requestOrigin/api/v1/trips/$tripId/documents/$documentId/analysis'),
      headers: headers,
    );

    _log('문서 분석 상태 조회 응답 statusCode=${response.statusCode}');

    if (response.statusCode != 200) {
      _log('문서 분석 상태 조회 실패 body=${response.body}');
      throw TripException(response.statusCode, _errorMessage(response));
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    _logBody('문서 분석 상태 조회 성공', json);
    return TripAnalysis.fromJson(json);
  }

  /// 여행에 업로드된 문서 목록을 조회한다. 증권/약관 documentId를 몰라도
  /// tripId만으로 여기서 찾을 수 있다.
  Future<List<TripDocument>> getDocuments({required String tripId}) async {
    if (_baseUrl.isEmpty) {
      throw const TripException(0, '.env에 API_BASE_URL이 설정되어 있지 않습니다.');
    }

    _log('여행 문서 목록 조회 요청 tripId=$tripId');

    final headers = <String, String>{};
    final accessToken = await _tokenStorage.readValid();
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final response = await http.get(
      Uri.parse('$_requestOrigin/api/v1/trips/$tripId/documents'),
      headers: headers,
    );

    _log('여행 문서 목록 조회 응답 statusCode=${response.statusCode}');

    if (response.statusCode != 200) {
      _log('여행 문서 목록 조회 실패 body=${response.body}');
      throw TripException(response.statusCode, _errorMessage(response));
    }

    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    _logBody('여행 문서 목록 조회 성공', list);
    return list
        .map((e) => TripDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 보장 내역을 조회한다. status가 COMPLETED가 아니면 coverages/selectedConcerns는
  /// 빈 목록으로 온다.
  Future<CoverageResult> getCoverages({
    required String tripId,
    required String documentId,
  }) async {
    if (_baseUrl.isEmpty) {
      throw const TripException(0, '.env에 API_BASE_URL이 설정되어 있지 않습니다.');
    }

    _log('보장 내역 조회 요청 tripId=$tripId documentId=$documentId');

    final headers = <String, String>{};
    final accessToken = await _tokenStorage.readValid();
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final response = await http.get(
      Uri.parse(
        '$_requestOrigin/api/v1/trips/$tripId/documents/$documentId/analysis/coverages',
      ),
      headers: headers,
    );

    _log('보장 내역 조회 응답 statusCode=${response.statusCode}');

    if (response.statusCode != 200) {
      _log('보장 내역 조회 실패 body=${response.body}');
      throw TripException(response.statusCode, _errorMessage(response));
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    _logBody('보장 내역 조회 성공', json);
    return CoverageResult.fromJson(json);
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
      Uri.parse('$_requestOrigin/api/v1/trips'),
      headers: headers,
    );

    _log('여행 세션 목록 조회 응답 statusCode=${response.statusCode}');

    if (response.statusCode != 200) {
      _log('여행 세션 목록 조회 실패 body=${response.body}');
      throw TripException(response.statusCode, _errorMessage(response));
    }

    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    _logBody('여행 세션 목록 조회 성공', list);
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
