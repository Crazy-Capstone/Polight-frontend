/// POST /api/v1/trips 응답의 document 파트, GET /api/v1/trips/{tripId}/documents 항목.
/// 이 id를 trip.id와 함께 분석 시작 API에 넘긴다.
///
/// 백엔드가 값이 없는 필드를 응답에서 생략하는 경우가 있어(documentKind 등)
/// 필수로 두면 파싱이 통째로 실패한다. 화면 표시에 꼭 필요한 id/tripId만
/// 필수로 두고 나머지는 없어도 넘어가도록 한다.
class TripDocument {
  final String id;
  final String tripId;
  final String originalFilename;
  final String contentType;
  final int fileSize;

  /// CERTIFICATE(증권) 또는 TERMS(약관). 백엔드가 생략하면 null.
  final String? documentKind;

  /// UPLOADED / PROCESSING / COMPLETED / FAILED. 생략되면 null.
  final String? parseStatus;

  final DateTime? uploadedAt;

  const TripDocument({
    required this.id,
    required this.tripId,
    this.originalFilename = '',
    this.contentType = '',
    this.fileSize = 0,
    this.documentKind,
    this.parseStatus,
    this.uploadedAt,
  });

  /// 증권 문서인지. documentKind가 없으면 파일명으로라도 추측한다.
  bool get isCertificate {
    if (documentKind != null) return documentKind == 'CERTIFICATE';
    return !originalFilename.contains('약관');
  }

  factory TripDocument.fromJson(Map<String, dynamic> json) {
    final uploadedAtRaw = json['uploadedAt'] as String?;
    return TripDocument(
      id: json['id'] as String,
      tripId: json['tripId'] as String? ?? '',
      originalFilename: json['originalFilename'] as String? ?? '',
      contentType: json['contentType'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      documentKind: json['documentKind'] as String?,
      parseStatus: json['parseStatus'] as String?,
      uploadedAt:
          uploadedAtRaw == null ? null : DateTime.tryParse(uploadedAtRaw),
    );
  }
}
