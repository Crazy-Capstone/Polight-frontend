/// POST /api/v1/trips 응답의 document 파트.
/// 이 id를 trip.id와 함께 분석 시작 API에 넘긴다.
class TripDocument {
  final String id;
  final String tripId;
  final String originalFilename;
  final String contentType;
  final int fileSize;
  final String documentKind;
  final String parseStatus;
  final DateTime uploadedAt;

  const TripDocument({
    required this.id,
    required this.tripId,
    required this.originalFilename,
    required this.contentType,
    required this.fileSize,
    required this.documentKind,
    required this.parseStatus,
    required this.uploadedAt,
  });

  factory TripDocument.fromJson(Map<String, dynamic> json) {
    return TripDocument(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      originalFilename: json['originalFilename'] as String,
      contentType: json['contentType'] as String,
      fileSize: json['fileSize'] as int,
      documentKind: json['documentKind'] as String,
      parseStatus: json['parseStatus'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }
}
