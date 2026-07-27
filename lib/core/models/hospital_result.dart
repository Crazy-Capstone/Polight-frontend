class HospitalResult {
  final String name;
  final String address;
  final double distanceMeters;
  final double? rating;
  final double lat;
  final double lng;

  const HospitalResult({
    required this.name,
    required this.address,
    required this.distanceMeters,
    this.rating,
    required this.lat,
    required this.lng,
  });

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()}m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }

  String get googleMapsUrl =>
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
}
