import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/trip_select_sheet.dart';
import 'coverage_screen.dart';

// ── 데이터 모델 ───────────────────────────────────────────────
class PastInsuranceItem {
  final String tripTitle;
  final String dateRange;
  final String durationLabel;
  final String insurer;
  final String flag;
  final int year;

  const PastInsuranceItem({
    required this.tripTitle,
    required this.dateRange,
    required this.durationLabel,
    required this.insurer,
    required this.flag,
    required this.year,
  });

  /// 보장 내역 화면에 넘길 여행 정보.
  /// 진행 중인 여행으로 등록돼 있으면 그 정보를 그대로 쓴다
  /// (보장 내역 탭과 상태 표시가 어긋나지 않도록).
  Trip get asTrip => kTrips.firstWhere(
        (trip) => trip.name == tripTitle,
        orElse: () => Trip(name: tripTitle, dateRange: dateRange, flag: flag),
      );
}

// ── 화면 ─────────────────────────────────────────────────────
class InsuranceHistoryScreen extends StatefulWidget {
  const InsuranceHistoryScreen({super.key});

  @override
  State<InsuranceHistoryScreen> createState() => _InsuranceHistoryScreenState();
}

class _InsuranceHistoryScreenState extends State<InsuranceHistoryScreen> {
  // 최근순 정렬
  static const List<PastInsuranceItem> _items = [
    PastInsuranceItem(
      tripTitle: '일본 여행',
      dateRange: '2025.04.08 – 04.18',
      durationLabel: '10일',
      insurer: '한화생명',
      flag: '🇯🇵',
      year: 2025,
    ),
    PastInsuranceItem(
      tripTitle: '베트남 다낭 가족여행',
      dateRange: '2025.01.11 – 01.17',
      durationLabel: '6일',
      insurer: '삼성화재',
      flag: '🇻🇳',
      year: 2025,
    ),
    PastInsuranceItem(
      tripTitle: '파리 출장',
      dateRange: '2024.11.03 – 11.09',
      durationLabel: '6일',
      insurer: 'KB손해보험',
      flag: '🇫🇷',
      year: 2024,
    ),
    PastInsuranceItem(
      tripTitle: '태국 방콕 혼자 여행',
      dateRange: '2024.08.20 – 08.27',
      durationLabel: '7일',
      insurer: '현대해상',
      flag: '🇹🇭',
      year: 2024,
    ),
    PastInsuranceItem(
      tripTitle: '미국 서부 로드트립',
      dateRange: '2024.05.02 – 05.14',
      durationLabel: '12일',
      insurer: '한화생명',
      flag: '🇺🇸',
      year: 2024,
    ),
    PastInsuranceItem(
      tripTitle: '스페인 신혼여행',
      dateRange: '2024.02.09 – 02.19',
      durationLabel: '10일',
      insurer: '삼성화재',
      flag: '🇪🇸',
      year: 2024,
    ),
  ];

  static const List<String> _filters = ['전체', '2025', '2024', '2023'];

  String _selectedFilter = _filters.first;

  List<PastInsuranceItem> get _visibleItems {
    if (_selectedFilter == '전체') return _items;
    return _items
        .where((item) => item.year.toString() == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
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
                _buildYearFilter(),
                const SizedBox(height: 14),
                _buildCountRow(items.length),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  _buildEmptyState()
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

  // ─── 빈 상태 (해당 연도 기록 없음) ────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      height: 84.36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '$_selectedFilter년 보험 기록이 없습니다',
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
  final PastInsuranceItem item;
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
            builder: (_) => CoverageScreen(initialTrip: item.asTrip),
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
                      item.tripTitle,
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
                      '${item.dateRange} · ${item.durationLabel}',
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
                      '${item.insurer} · 만료',
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
