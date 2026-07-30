class Place {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String? phone;

  Place({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.phone,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] ?? '',
      name: json['displayName']?['text'] ?? '이름 없음',
      address: json['formattedAddress'] ?? '',
      lat: (json['location']?['latitude'] ?? 0).toDouble(),
      lng: (json['location']?['longitude'] ?? 0).toDouble(),
      phone: json['nationalPhoneNumber'],
    );
  }
}