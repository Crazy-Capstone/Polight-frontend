import 'package:flutter/material.dart';
import 'coverage_detail_screen.dart';
import '../core/models/coverage_result.dart' as api;
import '../core/models/trip_document.dart';
import '../core/models/trip_session.dart';
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

  /// 분석이 막 끝난 여행/문서. 둘 다 있으면 실제 보장 내역 API로 그린다.
  final TripSession? trip;
  final TripDocument? document;

  const CoverageScreen({
    super.key,
    this.initialTrip,
    this.trip,
    this.document,
  });

  @override
  State<CoverageScreen> createState() => _CoverageScreenState();
}

class _CoverageScreenState extends State<CoverageScreen> {
  final TripService _tripService = TripService();

  Trip? _selectedTrip;
  String? _tripLoadError;

  api.CoverageResult? _coverageResult;
  bool _isLoadingCoverages = false;
  String? _coverageError;

  @override
  void initState() {
    super.initState();

    final trip = widget.trip;
    final initialTrip = widget.initialTrip;
    if (trip != null) {
      _selectedTrip = Trip.fromSession(trip);
      _loadCoverages(tripId: trip.id);
    } else if (initialTrip != null) {
      _selectedTrip = initialTrip;
      _loadCoverages(tripId: initialTrip.id);
    } else {
      _loadInitialTrip();
    }
  }

  /// tripId만으로 문서를 찾아 보장 내역을 불러온다. 분석이 막 끝난 직후라
  /// documentId를 이미 알고 있으면(widget.document) 문서 목록 조회를 건너뛴다.
  Future<void> _loadCoverages({required String tripId}) async {
    setState(() {
      _isLoadingCoverages = true;
      _coverageError = null;
      _coverageResult = null;
    });

    try {
      TripDocument document;
      if (widget.document != null && widget.trip?.id == tripId) {
        document = widget.document!;
      } else {
        final documents = await _tripService.getDocuments(tripId: tripId);
        if (documents.isEmpty) {
          throw const TripException(0, '이 여행에 업로드된 문서가 없어요');
        }
        document = documents.firstWhere(
          (d) => d.documentKind == 'CERTIFICATE',
          orElse: () => documents.first,
        );
      }

      final result = await _tripService.getCoverages(
        tripId: tripId,
        documentId: document.id,
      );
      if (!mounted) return;
      setState(() => _coverageResult = result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _coverageError =
            e is TripException ? e.message : '보장 내역을 불러오지 못했어요';
      });
    } finally {
      if (mounted) setState(() => _isLoadingCoverages = false);
    }
  }

  Future<void> _loadInitialTrip() async {
    try {
      final sessions = await _tripService.listTrips();
      if (!mounted) return;
      if (sessions.isEmpty) {
        setState(() => _tripLoadError = '등록된 여행이 없어요');
        return;
      }
      final trip = Trip.fromSession(sessions.first);
      setState(() => _selectedTrip = trip);
      _loadCoverages(tripId: trip.id);
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
    if (picked != null) {
      setState(() => _selectedTrip = picked);
      _loadCoverages(tripId: picked.id);
    }
  }

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

            if (_coverageResult != null && !_coverageResult!.coveragesComplete)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _CoveragesIncompleteNotice(),
                ),
              ),

            // ── 보장 카드 그리드 ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              sliver: _buildCoverageGridSliver(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverageGridSliver() {
    if (_coverageError != null) {
      return SliverToBoxAdapter(
        child: _CoverageStatusMessage(text: _coverageError!),
      );
    }

    final result = _coverageResult;
    if (result == null || _isLoadingCoverages) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF0888F6)),
          ),
        ),
      );
    }

    if (result.coverages.isEmpty) {
      return SliverToBoxAdapter(
        child: _CoverageStatusMessage(
          text: result.status == 'COMPLETED'
              ? '표시할 보장 내역이 없어요'
              : '아직 분석이 진행 중이라 보장 내역을 볼 수 없어요',
        ),
      );
    }

    final items = result.coverages.map(_coverageItemFrom).toList();
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _CoverageCard(item: items[index]),
        childCount: items.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 150,
      ),
    );
  }

  CoverageItem _coverageItemFrom(api.Coverage coverage) {
    return CoverageItem(
      emoji: _emojiForCoverage(coverage),
      title: coverage.title,
      subtitle: coverage.subtitle ?? coverage.category ?? '',
      limitLabel: _limitLabelFor(coverage),
      isCovered: coverage.isCovered,
      insurer: '분석된 보험 증권',
      summaryItems: _summaryItemsFor(coverage),
      detailItems: _detailItemsFor(coverage),
    );
  }

  String _emojiForCoverage(api.Coverage coverage) {
    final text = '${coverage.category ?? ''} ${coverage.title}';
    if (text.contains('치과')) return '🦷';
    if (text.contains('의료') || text.contains('질병') || text.contains('상해')) {
      return '🏥';
    }
    if (text.contains('항공') || text.contains('지연') || text.contains('결항')) {
      return '✈️';
    }
    if (text.contains('수하물') ||
        text.contains('휴대품') ||
        text.contains('도난') ||
        text.contains('분실')) {
      return '🧳';
    }
    if (text.contains('이송') || text.contains('구급')) return '🚑';
    if (text.contains('배상')) return '⚖️';
    if (text.contains('여권')) return '🛂';
    if (text.contains('중단') || text.contains('취소')) return '🚨';
    return '🛡️';
  }

  String _limitLabelFor(api.Coverage coverage) {
    final label = coverage.limitLabel;
    if (label != null && label.isNotEmpty) return label;

    final amount = coverage.limitAmount;
    if (amount != null) {
      final currency = coverage.limitCurrency ?? '원';
      return '최대 ${_formatAmount(amount)}$currency';
    }
    return '한도 확인 필요';
  }

  String _formatAmount(num amount) {
    final digits = amount.toInt().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  List<SummaryItem> _summaryItemsFor(api.Coverage coverage) {
    return coverage.subLimits
        .take(3)
        .map((s) => SummaryItem(label: s.label, value: s.value))
        .toList();
  }

  List<DetailItem> _detailItemsFor(api.Coverage coverage) {
    final items = coverage.detailItems
        .map((d) => DetailItem(
              title: d.title,
              subtitle: d.subtitle ?? '',
              isCovered: d.isCovered,
            ))
        .toList();
    items.addAll(coverage.exclusions.map((e) => DetailItem(
          title: e.title,
          subtitle: e.description ?? e.sourceText ?? '보장 제외',
          isCovered: false,
        )));
    return items;
  }
}

// ── 보장 정보가 아직 다 확인되지 않았다는 안내 ─────────────────
class _CoveragesIncompleteNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5DFA0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, size: 16, color: Color(0xFF9A7B1F)),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '아직 모든 담보를 확인하지 못했어요. 미보장으로 표시된 항목도\n'
              '실제로는 가입되어 있을 수 있어요.',
              style: TextStyle(
                fontSize: 11.44,
                fontWeight: FontWeight.w400,
                color: Color(0xFF7A5E12),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverageStatusMessage extends StatelessWidget {
  final String text;
  const _CoverageStatusMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF5B7BA6),
          ),
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