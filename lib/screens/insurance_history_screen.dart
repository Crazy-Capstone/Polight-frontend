import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/models/trip_session.dart';
import '../core/services/trip_service.dart';
import '../widgets/trip_select_sheet.dart';
import 'coverage_screen.dart';

// ── 데이터 모델 ───────────────────────────────────────────────
/// GET /api/v1/trips 응답 한 건을 화면에 쓸 형태로 감싼다.
class _HistoryEntry {
  final TripSession session;
  final Trip trip;

  _HistoryEntry(this.session) : trip = Trip.fromSession(session);

  String get durationLabel =>
      '${session.endDate.difference(session.startDate).inDays + 1}일';

  int get year => session.startDate.year;
}

// ── 화면 ─────────────────────────────────────────────────────
class InsuranceHistoryScreen extends StatefulWidget {
  const InsuranceHistoryScreen({super.key});

  @override
  State<InsuranceHistoryScreen> createState() => _InsuranceHistoryScreenState();
}

class _InsuranceHistoryScreenState extends State<InsuranceHistoryScreen> {
  final TripService _tripService = TripService();

  /// null이면 아직 로딩 중.
  List<_HistoryEntry>? _entries;
  String? _error;
  String _selectedFilter = '전체';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final sessions = await _tripService.listTrips();
      if (!mounted) return;

      final entries = sessions.map(_HistoryEntry.new).where((e) => e.trip.isExpired).toList()
        ..sort((a, b) => b.session.endDate.compareTo(a.session.endDate));

      setState(() => _entries = entries);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is TripException ? e.message : '보험 기록을 불러오지 못했어요';
      });
    }
  }

  List<String> get _filters {
    final years = (_entries ?? const <_HistoryEntry>[])
        .map((e) => e.year.toString())
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return ['전체', ...years];
  }

  List<_HistoryEntry> get _visibleItems {
    final entries = _entries ?? const <_HistoryEntry>[];
    if (_selectedFilter == '전체') return entries;
    return entries.where((e) => e.year.toString() == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    final items = _visibleItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 11, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                if (_error != null)
                  _buildMessageState(_error!)
                else if (entries == null)
                  _buildLoadingState()
                else ...[
                  _buildYearFilter(),
                  const SizedBox(height: 14),
                  _buildCountRow(items.length),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    _buildMessageState('$_selectedFilter년 보험 기록이 없습니다')
                  else
                    for (int i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10.5),
                      _HistoryCard(
                        item: items[i],
                        // 최근 건을 파란 테두리로 강조
                        isHighlighted: i == 0,
                      ),
                    ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 헤더 (뒤로가기 + 제목 + 부제목) ──────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 42.2,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF001635),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '이전 보험 내역',
                style: GoogleFonts.notoSansKr(
                  fontSize: 20,
                  height: 1.27,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF001635),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '만료된 보험 기록 전체 조회',
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF5B7BA6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 연도 필터 칩 ─────────────────────────────────────────────────────────
  Widget _buildYearFilter() {
    return Row(
      children: [
        for (final filter in _filters) ...[
          if (filter != _filters.first) const SizedBox(width: 8),
          _buildFilterChip(filter),
        ],
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        // '전체'는 56, 연도는 60 (디자인 고정 폭)
        width: label == '전체' ? 56 : 60,
        height: 33.7,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0868DD) : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFFE2EAF5)),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF5B7BA6),
          ),
        ),
      ),
    );
  }

  // ─── 건수 + 정렬 ──────────────────────────────────────────────────────────
  Widget _buildCountRow(int count) {
    return Row(
      children: [
        Text(
          '총 $count건',
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF001635),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '· 최근순',
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8FA6C2),
          ),
        ),
      ],
    );
  }

  // ─── 로딩 중 ──────────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: CircularProgressIndicator(color: Color(0xFF0868DD)),
      ),
    );
  }

  // ─── 빈 상태 · 에러 상태 (해당 연도 기록 없음 / 조회 실패) ─────────────────
  Widget _buildMessageState(String message) {
    return Container(
      width: double.infinity,
      height: 84.36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.notoSansKr(
          fontSize: 12.5,
          height: 1.27,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF9FB4CE),
        ),
      ),
    );
  }
}

// ── 보험 내역 카드 ────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final _HistoryEntry item;
  final bool isHighlighted;

  const _HistoryCard({required this.item, required this.isHighlighted});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 해당 여행의 보장 내역으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CoverageScreen(initialTrip: item.trip),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          // 강조되지 않은 카드도 동일한 테두리 두께를 유지해 내용 위치를 맞춘다
          border: Border.all(
            color: isHighlighted ? const Color(0xFFBBD8FB) : Colors.white,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15.5, 10.7, 16.5, 14.1),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.session.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 15,
                        height: 1.27,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF001635),
                      ),
                    ),
                    const SizedBox(height: 3.7),
                    Text(
                      '${item.trip.dateRange} · ${item.durationLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12.5,
                        height: 1.27,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF5B7BA6),
                      ),
                    ),
                    const SizedBox(height: 3.2),
                    Text(
                      '만료',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11.5,
                        height: 1.29,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF9FB4CE),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFFB4C4D8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
