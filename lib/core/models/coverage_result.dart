/// GET /api/v1/trips/{tripId}/documents/{documentId}/analysis/coverages 응답.
class CoverageResult {
  final String analysisResultId;
  final String status;

  /// false면 아직 모든 담보를 확인하지 못한 상태라, covered:false인 걱정을
  /// "가입하지 않았다"로 단정할 수 없다.
  final bool coveragesComplete;
  final List<SelectedConcernResult> selectedConcerns;
  final List<Coverage> coverages;

  const CoverageResult({
    required this.analysisResultId,
    required this.status,
    required this.coveragesComplete,
    required this.selectedConcerns,
    required this.coverages,
  });

  factory CoverageResult.fromJson(Map<String, dynamic> json) {
    return CoverageResult(
      analysisResultId: json['analysisResultId'] as String,
      status: json['status'] as String,
      coveragesComplete: json['coveragesComplete'] as bool? ?? false,
      selectedConcerns: (json['selectedConcerns'] as List<dynamic>? ?? [])
          .map((e) => SelectedConcernResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      coverages: (json['coverages'] as List<dynamic>? ?? [])
          .map((e) => Coverage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SelectedConcernResult {
  final String code;
  final bool covered;

  const SelectedConcernResult({required this.code, required this.covered});

  factory SelectedConcernResult.fromJson(Map<String, dynamic> json) {
    return SelectedConcernResult(
      code: json['code'] as String,
      covered: json['covered'] as bool? ?? false,
    );
  }
}

class Coverage {
  final String id;
  final String title;
  final String? subtitle;
  final String? category;
  final String coverageStatus;
  final bool isCovered;
  final String? limitLabel;
  final num? limitAmount;
  final String? limitCurrency;
  final String? conditions;
  final List<String> matchedConcerns;
  final List<CoverageDetailItem> detailItems;
  final List<CoverageSubLimit> subLimits;
  final List<CoverageRequiredDocument> requiredDocuments;
  final List<CoverageExclusion> exclusions;

  const Coverage({
    required this.id,
    required this.title,
    this.subtitle,
    this.category,
    required this.coverageStatus,
    required this.isCovered,
    this.limitLabel,
    this.limitAmount,
    this.limitCurrency,
    this.conditions,
    this.matchedConcerns = const [],
    this.detailItems = const [],
    this.subLimits = const [],
    this.requiredDocuments = const [],
    this.exclusions = const [],
  });

  factory Coverage.fromJson(Map<String, dynamic> json) {
    return Coverage(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      category: json['category'] as String?,
      coverageStatus: json['coverageStatus'] as String,
      isCovered: json['isCovered'] as bool? ?? false,
      limitLabel: json['limitLabel'] as String?,
      limitAmount: json['limitAmount'] as num?,
      limitCurrency: json['limitCurrency'] as String?,
      conditions: json['conditions'] as String?,
      matchedConcerns:
          (json['matchedConcerns'] as List<dynamic>? ?? []).cast<String>(),
      detailItems: (json['detailItems'] as List<dynamic>? ?? [])
          .map((e) => CoverageDetailItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subLimits: (json['subLimits'] as List<dynamic>? ?? [])
          .map((e) => CoverageSubLimit.fromJson(e as Map<String, dynamic>))
          .toList(),
      requiredDocuments: (json['requiredDocuments'] as List<dynamic>? ?? [])
          .map((e) =>
              CoverageRequiredDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
      exclusions: (json['exclusions'] as List<dynamic>? ?? [])
          .map((e) => CoverageExclusion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CoverageDetailItem {
  final String title;
  final String? subtitle;
  final bool isCovered;

  const CoverageDetailItem({
    required this.title,
    this.subtitle,
    required this.isCovered,
  });

  factory CoverageDetailItem.fromJson(Map<String, dynamic> json) {
    return CoverageDetailItem(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      isCovered: json['isCovered'] as bool? ?? false,
    );
  }
}

class CoverageSubLimit {
  final String label;
  final String value;
  final String? description;
  final num? limitAmount;
  final String? limitCurrency;

  const CoverageSubLimit({
    required this.label,
    required this.value,
    this.description,
    this.limitAmount,
    this.limitCurrency,
  });

  factory CoverageSubLimit.fromJson(Map<String, dynamic> json) {
    return CoverageSubLimit(
      label: json['label'] as String,
      value: json['value'] as String,
      description: json['description'] as String?,
      limitAmount: json['limitAmount'] as num?,
      limitCurrency: json['limitCurrency'] as String?,
    );
  }
}

class CoverageRequiredDocument {
  final String documentName;
  final bool isMandatory;

  const CoverageRequiredDocument({
    required this.documentName,
    required this.isMandatory,
  });

  factory CoverageRequiredDocument.fromJson(Map<String, dynamic> json) {
    return CoverageRequiredDocument(
      documentName: json['documentName'] as String,
      isMandatory: json['isMandatory'] as bool? ?? false,
    );
  }
}

class CoverageExclusion {
  final String title;
  final String? description;
  final String? sourceText;
  final String? severity;

  const CoverageExclusion({
    required this.title,
    this.description,
    this.sourceText,
    this.severity,
  });

  factory CoverageExclusion.fromJson(Map<String, dynamic> json) {
    return CoverageExclusion(
      title: json['title'] as String,
      description: json['description'] as String?,
      sourceText: json['sourceText'] as String?,
      severity: json['severity'] as String?,
    );
  }
}
