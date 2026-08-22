import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../app_log.dart';

/// 지금 있는 곳을 화면에 쓸 형태로 담는다.
class CurrentPlace {
  /// 국기 이모지. 국가를 못 알아내면 🌐.
  final String flag;
  final String country;
  final String city;

  /// 위치를 못 가져왔을 때 보여줄 문구. 성공했으면 null.
  final String? error;

  const CurrentPlace({
    this.flag = '🌐',
    this.country = '',
    this.city = '',
    this.error,
  });

  const CurrentPlace.failed(String message)
    : flag = '🌐',
      country = '',
      city = '',
      error = message;

  bool get isResolved => error == null;

  /// "🇯🇵 일본 · 도쿄" 형태. 실패했으면 실패 문구.
  String get label {
    if (error != null) return error!;
    final where = [country, city].where((s) => s.isNotEmpty).join(' · ');
    return where.isEmpty ? flag : '$flag $where';
  }

  /// 나라 이름만. 국기를 따로 그리는 마이페이지 통계 카드에서 쓴다.
  String get countryLabel {
    if (error != null) return error!;
    return country.isEmpty ? '위치 확인 중' : country;
  }
}

/// 현재 위치를 국가·도시 이름으로 바꿔 준다.
/// 홈 화면과 마이페이지가 같은 결과를 쓰도록 여기서만 처리한다.
class CurrentPlaceService {
  static const String _logName = 'CurrentPlaceService';

  Future<CurrentPlace> fetch() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const CurrentPlace.failed('위치 서비스가 꺼져 있어요');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const CurrentPlace.failed('위치 권한이 없어요');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        return const CurrentPlace.failed('위치를 불러올 수 없어요');
      }

      final place = placemarks.first;
      final city = place.locality?.isNotEmpty == true
          ? place.locality!
          : (place.administrativeArea ?? '');
      return CurrentPlace(
        flag: codeToFlag(place.isoCountryCode ?? ''),
        country: place.country ?? '',
        city: city,
      );
    } catch (e) {
      appLog(_logName, '현재 위치 조회 실패: $e');
      return const CurrentPlace.failed('위치를 불러올 수 없어요');
    }
  }
}

/// ISO 국가 코드(KR, JP …)를 국기 이모지로 바꾼다. 알 수 없으면 🌐.
String codeToFlag(String code) {
  if (code.length != 2) return '🌐';
  return code
      .toUpperCase()
      .runes
      .map((r) => String.fromCharCode(r + 0x1F1A5))
      .join();
}
