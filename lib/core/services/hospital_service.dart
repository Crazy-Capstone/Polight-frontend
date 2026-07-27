import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/hospital_result.dart';

class HospitalService {
  static const String _nearbySearchUrl =
      'https://places.googleapis.com/v1/places:searchNearby';

  Future<List<HospitalResult>> fetchNearbyHospitals(BuildContext context) async {
    final position = await _getCurrentPosition(context);
    if (position == null) return [];
    return _searchNearby(position.latitude, position.longitude);
  }

  Future<Position?> _getCurrentPosition(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (context.mounted) await _showPermissionDialog(context);
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
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
    final response = await http.post(
      Uri.parse(_nearbySearchUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': AppConfig.googlePlacesApiKey,
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

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final places = (data['places'] as List<dynamic>?) ?? [];

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
