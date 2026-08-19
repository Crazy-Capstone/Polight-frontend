import 'package:flutter/material.dart';
import 'coverage_detail_screen.dart';
import '../core/services/trip_service.dart';
import '../widgets/trip_select_sheet.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      home: const CoverageScreen(),
    );
  }
}

// ── 데이터 모델 ──────────────────────────────────────────────
class CoverageItem {
  final String emoji;
  final String title;
  final String subtitle;
  final String limitLabel;
  final bool isCovered;
  final String insurer;
  final List<SummaryItem> summaryItems;
  final List<DetailItem> detailItems;

  const CoverageItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.limitLabel,
    this.isCovered = true,
    this.insurer = '삼성화재 여행자보험',
    this.summaryItems = const [],
    this.detailItems = const [],
  });
}

// ── 화면 ─────────────────────────────────────────────────────
class CoverageScreen extends StatefulWidget {
  /// 이전 보험 내역 등에서 특정 여행의 보장을 바로 열 때 지정한다.
  final Trip? initialTrip;

  const CoverageScreen({super.key, this.initialTrip});

  @override
  State<CoverageScreen> createState() => _CoverageScreenState();
}

class _CoverageScreenState extends State<CoverageScreen> {
  final TripService _tripService = TripService();

  Trip? _selectedTrip;
  String? _tripLoadError;

  @override
  void initState() {
    super.initState();
    final initialTrip = widget.initialTrip;
    if (initialTrip != null) {
      _selectedTrip = initialTrip;
    } else {
      _loadInitialTrip();
    }
  }

  Future<void> _loadInitialTrip() async {
    try {
      final sessions = await _tripService.listTrips();
      if (!mounted) return;
      setState(() {
        if (sessions.isEmpty) {
          _tripLoadError = '등록된 여행이 없어요';
        } else {
          _selectedTrip = Trip.fromSession(sessions.first);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tripLoadError = e is TripException ? e.message : '여행 정보를 불러오지 못했어요';
      });
    }
  }

  Future<void> _openTripSelect() async {
    final current = _selectedTrip;
    if (current == null) return;
    final picked = await showTripSelectSheet(context, selected: current);
    if (picked != null) setState(() => _selectedTrip = picked);
  }

  static const List<CoverageItem> _items = [
    CoverageItem(
      emoji: '🏥',
      title: '의료비',
      subtitle: '입원·통원·응급 치료',
      limitLabel: '최대 1억원',
      insurer: '삼성화재 여행자보험',
      summaryItems: [
        SummaryItem(label: '입원', value: '최대 1억원'),
        SummaryItem(label: '통원', value: '회당 30만원'),
        SummaryItem(label: '응급', value: '무제한'),
      ],
      detailItems: [
        DetailItem(title: '외래 진료비', subtitle: '의사 진료, 검사, 처방 포함', isCovered: true),
        DetailItem(title: '입원 치료비', subtitle: '병실료, 수술비, 간호비 포함', isCovered: true),
        DetailItem(title: '응급 처치', subtitle: '응급실 내원 시 즉시 적용', isCovered: true),
        DetailItem(title: '처방약 비용', subtitle: '처방전 발급 약품 한정', isCovered: true),
        DetailItem(title: '앰뷸런스 이용', subtitle: '현지 응급 이송 비용', isCovered: true),
        DetailItem(title: '미용·성형 수술', subtitle: '보장 제외', isCovered: false),
        DetailItem(title: '기존 질환 치료', subtitle: '여행 전 진단된 질환 제외', isCovered: false),
      ],
    ),
    CoverageItem(
      emoji: '✈️',
      title: '항공 지연',
      subtitle: '3시간 이상 지연',
      limitLabel: '최대 30만원',
      insurer: '삼성화재 여행자보험',
      summaryItems: [
        SummaryItem(label: '지연', value: '최대 30만원'),
        SummaryItem(label: '결항', value: '최대 50만원'),
        SummaryItem(label: '대기', value: '3시간 이상'),
      ],
      detailItems: [
        DetailItem(title: '항공편 지연', subtitle: '3시간 이상 지연 시 적용', isCovered: true),
        DetailItem(title: '항공편 결항', subtitle: '비자발적 결항에 한함', isCovered: true),
        DetailItem(title: '자발적 취소', subtitle: '본인 사정에 의한 취소 제외', isCovered: false),
      ],
    ),
    CoverageItem(
      emoji: '🧳',
      title: '수하물',
      subtitle: '항공사 귀책 한정',
      limitLabel: '최대 50만원',
      insurer: '삼성화재 여행자보험',
      summaryItems: [
        SummaryItem(label: '분실', value: '최대 50만원'),
        SummaryItem(label: '파손', value: '최대 30만원'),
        SummaryItem(label: '지연', value: '최대 10만원'),
      ],
      detailItems: [
        DetailItem(title: '수하물 분실', subtitle: '항공사 귀책 분실에 한함', isCovered: true),
        DetailItem(title: '수하물 파손', subtitle: '항공사 과실에 의한 파손', isCovered: true),
        DetailItem(title: '귀중품 분실', subtitle: '현금·유가증권 제외', isCovered: false),
      ],
    ),
    CoverageItem(
      emoji: '🚑',
      title: '긴급 이송',
      subtitle: '의료진 동반 후송',
      limitLabel: '한도 없음',
      insurer: '삼성화재 여행자보험',
      summaryItems: [
        SummaryItem(label: '이송비', value: '한도 없음'),
        SummaryItem(label: '동반', value: '의료진'),
        SummaryItem(label: '대상', value: '전 질환'),
      ],
      detailItems: [
        DetailItem(title: '항공 이송', subtitle: '의료진 동반 본국 후송', isCovered: true),
        DetailItem(title: '구급차 이용', subtitle: '현지 응급 이송 비용', isCovered: true),
        DetailItem(title: '비응급 이송', subtitle: '의료상 필요 없는 이송 제외', isCovered: false),
      ],
    ),
    CoverageItem(
      emoji: '🦷',
      title: '치과 응급',
      subtitle: '급성 치통·외상',
      limitLabel: '최대 50만원',
      insurer: '삼성화재 여행자보험',
      summaryItems: [
        SummaryItem(label: '응급', value: '최대 50만원'),
        SummaryItem(label: '외상', value: '포함'),
        SummaryItem(label: '치통', value: '급성 한정'),
      ],
      detailItems: [
        DetailItem(title: '급성 치통', subtitle: '여행 중 발생한 급성 치통', isCovered: true),
        DetailItem(title: '치아 외상', subtitle: '사고에 의한 치아 파손', isCovered: true),
        DetailItem(title: '교정·미용', subtitle: '교정 및 미용 목적 치료 제외', isCovered: false),
      ],
    ),
    CoverageItem(
      emoji: '⚖️',
      title: '배상 책임',
      subtitle: '제3자 피해 보상',
      limitLabel: '최대 1억원',
      insurer: '삼성화재 여행자보험',
      summaryItems: [
        SummaryItem(label: '대인', value: '최대 1억원'),
        SummaryItem(label: '대물', value: '최대 500만원'),
        SummaryItem(label: '공제', value: '1만원'),
      ],
      detailItems: [
        DetailItem(title: '대인 배상', subtitle: '제3자 신체 피해 보상', isCovered: true),
        DetailItem(title: '대물 배상', subtitle: '제3자 재물 피해 보상', isCovered: true),
        DetailItem(title: '고의 사고', subtitle: '고의로 인한 사고 제외', isCovered: false),
        DetailItem(title: '가족 간 사고', subtitle: '피보험자 가족 간 사고 제외', isCovered: false),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedTrip = _selectedTrip;
    if (selectedTrip == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        body: SafeArea(
          child: Center(
            child: _tripLoadError != null
                ? Text(
                    _tripLoadError!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF5B7BA6),
                    ),
                  )
                : const CircularProgressIndicator(color: Color(0xFF0888F6)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── 앱바 ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    // push 로 열렸을 때만 뒤로가기를 둔다 (탭으로 볼 때는 불필요)
                    if (Navigator.canPop(context)) ...[
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Color(0xFF001635),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    const Expanded(
                      child: Text(
                        '보장 내역',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20.8,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF001635),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _TripBadge(
                      trip: selectedTrip,
                      onTap: _openTripSelect,
                    ),
                  ],
                ),
              ),
            ),

            // ── 구분선 ──
            SliverToBoxAdapter(
              child: Container(
                height: 1,
                color: const Color(0xFFE2E9FF),
              ),
            ),

            // ── 여행 기간 배너 ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _TripDateBanner(trip: selectedTrip),
              ),
            ),

            // ── 보장 카드 그리드 ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _CoverageCard(item: _items[index]),
                  childCount: _items.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 150,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 여행 뱃지 (여행 선택 시트를 여는 드롭다운) ──────────────────
class _TripBadge extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const _TripBadge({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFB9D6FB), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trip.flag.isNotEmpty) ...[
              Text(trip.flag, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
            ],
            Text(
              trip.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0868DD),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Color(0xFF0868DD),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 여행 기간 배너 ─────────────────────────────────────────────
class _TripDateBanner extends StatelessWidget {
  final Trip trip;

  const _TripDateBanner({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E9FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: trip.isExpired
                  ? const Color(0xFFB4C4D8)
                  : const Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          // 기간이 길어도 배너가 넘치지 않게 남은 폭을 모두 쓴다
          Expanded(
            child: Text(
              trip.dateRange,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.48,
                fontWeight: FontWeight.w400,
                color: Color(0xFF001635),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            // 만료된 여행은 남은 일수 대신 상태를 보여준다
            trip.isExpired ? '만료' : 'D-7 남음',
            style: TextStyle(
              fontSize: 12.48,
              fontWeight: FontWeight.w700,
              color: trip.isExpired
                  ? const Color(0xFF9FB4CE)
                  : const Color(0xFF0066C3),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 보장 카드 ─────────────────────────────────────────────────
class _CoverageCard extends StatelessWidget {
  final CoverageItem item;

  const _CoverageCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 카드 본체
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDDE3F0), width: 1.2),
              ),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 아이콘 + 한도 뱃지
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF1FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            item.emoji,
                            style: const TextStyle(fontSize: 20.8),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF1FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFCEDDFE),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          item.limitLabel,
                          style: const TextStyle(
                            fontSize: 9.36,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF004D9D),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 제목
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13.52,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF001635),
                    ),
                  ),

                  // 부제목
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 11.44,
                      color: Color(0xFF4A6080),
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  // 구분선
                  Container(
                    height: 1,
                    color: const Color(0xFFF0F4FF),
                  ),

                  // 하단 보장 상태 + 상세보기
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: item.isCovered
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF9BAEC8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.isCovered ? '보장 중' : '미보장',
                            style: TextStyle(
                              fontSize: 10.4,
                              fontWeight: FontWeight.w400,
                              color: item.isCovered
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF9BAEC8),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CoverageDetailScreen(
                                emoji: item.emoji,
                                coverageTitle: item.title,
                                insurer: item.insurer,
                                maxLimit: item.limitLabel,
                                summaryItems: item.summaryItems,
                                detailItems: item.detailItems,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          '상세보기 ›',
                          style: TextStyle(
                            fontSize: 10.4,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF0888F6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 상단 파란 강조선
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                color: const Color(0xFF0888F6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}