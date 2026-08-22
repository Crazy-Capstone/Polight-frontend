/// 챗봇에서 찾아줄 수 있는 장소 종류.
///
/// [googleType]은 Google Places API (New) searchNearby의 includedTypes 값,
/// [textQuery]는 searchText의 검색어다. [textQuery]가 있으면 searchText를 쓴다.
enum PlaceCategory {
  hospital(
    googleType: 'hospital',
    label: '병원',
    emoji: '🏥',
    subtitle: '한국어 통역 가능',
    badge: '제휴',
    radiusMeters: 3000,
    keywords: [
      '병원 어디에 있어?',
    ],
  ),
  police(
    googleType: 'police',
    label: '경찰서',
    emoji: '🚓',
    subtitle: '24시간 신고 접수',
    badge: null,
    radiusMeters: 5000,
    keywords: [
      '경찰서 어디에 있어?'
    ],
  ),
  embassy(
    googleType: 'embassy',
    // embassy 타입으로 거리순 검색하면 다른 나라 대사관이 먼저 나오므로,
    // 우리 국민에게 실제로 필요한 재외공관을 검색어로 직접 찾는다.
    textQuery: '대한민국 대사관 영사관',
    label: '대사관',
    emoji: '🏛',
    subtitle: '영사 지원',
    badge: null,
    // 재외공관은 도시마다 한두 곳뿐이라 반경을 크게 잡는다.
    radiusMeters: 50000,
    keywords: [
      '대사관 어디에 있어?',
    ],
  );

  const PlaceCategory({
    required this.googleType,
    required this.label,
    required this.emoji,
    required this.subtitle,
    required this.badge,
    required this.radiusMeters,
    required this.keywords,
    this.textQuery,
  });

  final String googleType;

  /// null이 아니면 searchNearby 대신 searchText로 검색한다.
  final String? textQuery;
  final String label;
  final String emoji;

  /// 카드에서 거리 앞에 붙는 설명 문구.
  final String subtitle;

  /// 카드 우측 배지. null이면 배지를 표시하지 않는다.
  final String? badge;

  final double radiusMeters;
  final List<String> keywords;

  String get formattedRadius => radiusMeters < 1000
      ? '${radiusMeters.round()}m'
      : '${(radiusMeters / 1000).round()}km';
}
