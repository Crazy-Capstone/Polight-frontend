import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NearbyService {
  static const _url = 'https://places.googleapis.com/v1/places:searchNearby';
  static String get _apiKey => dotenv.env['PLACES_API_KEY'] ?? '';

  Future<List<Place>> search({
    required double lat,
    required double lng,
    required List<String> types,
    double radius = 3000,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
          'places.id,places.displayName,places.formattedAddress,'
              'places.location,places.nationalPhoneNumber',
        },
        body: jsonEncode({
          'includedTypes': types,
          'maxResultCount': 15,
          'rankPreference': 'DISTANCE',
          'languageCode': 'ko',
          'locationRestriction': {
            'circle': {
              'center': {'latitude': lat, 'longitude': lng},
              'radius': radius,
            }
          },
        }),
      );

      if (res.statusCode != 200) {
        throw Exception('Places API ${res.statusCode}: ${res.body}');
      }

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return (data['places'] as List? ?? [])
          .map((e) => Place.fromJson(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}