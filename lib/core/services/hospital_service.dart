import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/hospital_result.dart';

class HospitalService {
  static const String _nearbySearchUrl =
      'https://places.googleapis.com/v1/places:searchNearby';
  static const String _logName = 'HospitalService';

  static String get _apiKey => dotenv.env['PLACES_API_KEY'] ?? '';

  void _log(String message) => developer.log(message, name: _logName);

  Future<List<HospitalResult>> fetchNearbyHospitals(BuildContext context) async {
    _log('병원 검색 시작');

    final position = await _getCurrentPosition(context);
    if (position == null) {
      _log('결과 없음 사유: 위치를 가져오지 못함 (권한/서비스 문제) → 빈 목록 반환');
      return [];
    }

    _log('현재 위치: lat=${position.latitude}, lng=${position.longitude}, '
        '정확도=${position.accuracy}m');

    return _searchNearby(position.latitude, position.longitude);
  }

  Future<Position?> _getCurrentPosition(BuildContext context) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    _log('위치 서비스 활성화 여부: $serviceEnabled');
    if (!serviceEnabled) {
      _log('위치 서비스가 꺼져 있어 위치 조회를 중단합니다');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    _log('위치 권한(요청 전): $permission');

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      _log('위치 권한(요청 후): $permission');
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _log('위치 권한 거부됨 → 권한 안내 다이얼로그 표시');
      if (context.mounted) await _showPermissionDialog(context);
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e, s) {
      _log('현재 위치 조회 실패: $e');
      developer.log('현재 위치 조회 실패',
          name: _logName, error: e, stackTrace: s);
      return null;
    }
  }

  Future<void> _showPermissionDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '위치 권한 필요',
          style: TextStyle(
            fontSize: 16.64,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F1C3F),
          ),
        ),
        content: const Text(
          '주변 병원을 찾으려면 위치 권한이 필요해요.\n설정에서 위치 권한을 허용해 주세요.',
          style: TextStyle(
            fontSize: 14.56,
            color: Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              '취소',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Geolocator.openAppSettings();
            },
            child: const Text(
              '설정으로 이동',
              style: TextStyle(
                color: Color(0xFF0E2A6E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<HospitalResult>> _searchNearby(double lat, double lng) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      _log('결과 없음 사유: .env에 PLACES_API_KEY가 없습니다 → 호출 자체가 실패합니다');
    } else {
      _log('Places API 키 길이=${apiKey.length}, '
          'prefix=${apiKey.substring(0, apiKey.length < 6 ? apiKey.length : 6)}...');
    }

    _log('searchNearby 요청: center=($lat, $lng), radius=3000m, '
        'includedTypes=[hospital], maxResultCount=5');

    final response = await http.post(
      Uri.parse(_nearbySearchUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask':
            'places.displayName,places.formattedAddress,places.location,places.rating',
      },
      body: jsonEncode({
        'includedTypes': ['hospital'],
        'maxResultCount': 5,
        'rankPreference': 'DISTANCE',
        'locationRestriction': {
          'circle': {
            'center': {'latitude': lat, 'longitude': lng},
            'radius': 3000.0,
          },
        },
      }),
    );

    _log('searchNearby 응답 statusCode=${response.statusCode}');

    if (response.statusCode != 200) {
      _log('결과 없음 사유: API 호출 실패 (${response.statusCode})\n'
          'body=${response.body}');
      return [];
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final places = (data['places'] as List<dynamic>?) ?? [];

    if (places.isEmpty) {
      _log('결과 없음 사유: API는 정상(200)이지만 반경 3km 내 hospital이 실제로 0건입니다\n'
          'body=${response.body}');
    } else {
      _log('반경 3km 내 병원 ${places.length}건 조회됨 (상위 2건만 사용)');
    }

    return places.take(2).map((place) {
      final location = place['location'] as Map<String, dynamic>;
      final placeLat = (location['latitude'] as num).toDouble();
      final placeLng = (location['longitude'] as num).toDouble();

      return HospitalResult(
        name: (place['displayName']?['text'] as String?) ?? '이름 없음',
        address: (place['formattedAddress'] as String?) ?? '주소 없음',
        distanceMeters: _haversineDistance(lat, lng, placeLat, placeLng),
        rating: place['rating'] != null
            ? (place['rating'] as num).toDouble()
            : null,
        lat: placeLat,
        lng: placeLng,
      );
    }).toList();
  }

  double _haversineDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;
}
