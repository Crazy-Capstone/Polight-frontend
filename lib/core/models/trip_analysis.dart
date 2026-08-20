/// POST /api/v1/trips/{tripId}/documents/{documentId}/analysis 응답.
class TripAnalysis {
  final String id;
  final String documentId;
  final String status;
  final String? summary;
  final String? failureReason;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const TripAnalysis({
    required this.id,
    required this.documentId,
    required this.status,
    this.summary,
    this.failureReason,
    this.startedAt,
    this.completedAt,
  });

  factory TripAnalysis.fromJson(Map<String, dynamic> json) {
    return TripAnalysis(
      id: json['id'] as String,
      documentId: json['documentId'] as String,
      status: json['status'] as String,
      summary: json['summary'] as String?,
      failureReason: json['failureReason'] as String?,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );
  }
}
