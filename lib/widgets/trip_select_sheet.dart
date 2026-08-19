import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/models/trip_session.dart';
import '../core/services/trip_service.dart';

// ── 데이터 모델 ───────────────────────────────────────────────
class Trip {
  final String name;
  final String dateRange;
  final bool isExpired;

  /// 여행지 국기 이모지. 없으면 뱃지에 표시하지 않는다.
  final String flag;

  const Trip({
    required this.name,
    required this.dateRange,
    this.isExpired = true,
    this.flag = '',
  });

  /// GET /api/v1/trips 응답 항목을 화면에 쓸 형태로 변환한다.
  /// 국기 이모지는 백엔드가 내려주지 않아 비워 둔다.
  factory Trip.fromSession(TripSession session) {
    return Trip(
      name: session.name,
      dateRange: _formatDateRange(session.startDate, session.endDate),
      isExpired: _isBeforeToday(session.endDate),
    );
  }
}

String _pad2(int n) => n.toString().padLeft(2, '0');

String _formatDateRange(DateTime start, DateTime end) {
  final startText = '${start.year}.${_pad2(start.month)}.${_pad2(start.day)}';
  final endText = start.year == end.year
      ? '${_pad2(end.month)}.${_pad2(end.day)}'
      : '${end.year}.${_pad2(end.month)}.${_pad2(end.day)}';
  return '$startText – $endText';
}

bool _isBeforeToday(DateTime date) {
  final today = DateTime.now();
  final dateOnly = DateTime(date.year, date.month, date.day);
  final todayOnly = DateTime(today.year, today.month, today.day);
  return dateOnly.isBefore(todayOnly);
}

/// 여행 선택 바텀시트를 띄우고, 사용자가 '이 여행으로 보기'를 누르면
/// 선택한 [Trip]을 돌려준다. 닫기·스크림 탭 시에는 null.
Future<Trip?> showTripSelectSheet(
  BuildContext context, {
  required Trip selected,
}) {
  return showModalBottomSheet<Trip>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // 디자인 스크림: #001028 45%
    barrierColor: const Color(0x73001028),
    builder: (_) => TripSelectSheet(selected: selected),
  );
}

// ── 바텀시트 ──────────────────────────────────────────────────
class TripSelectSheet extends StatefulWidget {
  final Trip selected;

  const TripSelectSheet({super.key, required this.selected});

  @override
  State<TripSelectSheet> createState() => _TripSelectSheetState();
}

class _TripSelectSheetState extends State<TripSelectSheet> {
  // 시트 높이 / 화면 높이 (디자인 493.49 / 856.23)
  static const double _heightFactor = 0.5764;

  final TripService _tripService = TripService();

  late Trip _selected = widget.selected;
  List<Trip>? _trips;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    try {
      final sessions = await _tripService.listTrips();
      if (!mounted) return;
      setState(() => _trips = sessions.map(Trip.fromSession).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is TripException ? e.message : '여행 목록을 불러오지 못했어요';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return SizedBox(
      height: MediaQuery.of(context).size.height * _heightFactor,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(29.5)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 14.8),
            // 드래그 핸들
            Container(
              width: 41,
              height: 5.3,
              decoration: BoxDecoration(
                color: const Color(0xFFD9E2EE),
                borderRadius: BorderRadius.circular(2.65),
              ),
            ),
            const SizedBox(height: 20),
            _buildTitleRow(),
            const SizedBox(height: 6.9),
            _buildSubtitle(),
            const SizedBox(height: 16.3),
            // 목록 — 마지막 항목이 버튼 아래로 살짝 걸쳐 스크롤됨을 알린다
            Expanded(child: _buildBody()),
            _buildConfirmButton(bottomInset),
          ],
        ),
      ),
    );
  }

  // ─── 제목 + 닫기 ──────────────────────────────────────────────────────────
  Widget _buildTitleRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            '여행 선택',
            style: GoogleFonts.notoSansKr(
              fontSize: 18,
              height: 1.23,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF001635),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              '닫기',
              style: GoogleFonts.notoSansKr(
                fontSize: 13.5,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8FA6C2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '다른 여행의 보장 내역으로 바꿔서 볼 수 있어요',
          style: GoogleFonts.notoSansKr(
            fontSize: 12.5,
            height: 1.27,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF5B7BA6),
          ),
        ),
      ),
    );
  }

  // ─── 목록 본문 (로딩 · 에러 · 빈 상태 · 목록) ──────────────────────────────
  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF5B7BA6),
            ),
          ),
        ),
      );
    }

    final trips = _trips;
    if (trips == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0888F6)),
      );
    }

    if (trips.isEmpty) {
      return Center(
        child: Text(
          '등록된 여행이 없어요',
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8FA6C2),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: trips.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8.4),
      itemBuilder: (_, i) {
        final trip = trips[i];
        return _TripRow(
          trip: trip,
          isSelected: trip.name == _selected.name,
          onTap: () => setState(() => _selected = trip),
        );
      },
    );
  }

  // ─── 확인 버튼 ────────────────────────────────────────────────────────────
  Widget _buildConfirmButton(double bottomInset) {
    return Padding(
      // 디자인 하단 여백 25.3 — 홈 인디케이터가 있으면 그만큼 확보한다
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset > 0 ? bottomInset : 25.3),
      child: GestureDetector(
        onTap: () => Navigator.pop(context, _selected),
        child: Container(
          height: 59,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1D9BFF), Color(0xFF0868DD)],
            ),
          ),
          child: Text(
            '이 여행으로 보기',
            style: GoogleFonts.notoSansKr(
              fontSize: 17,
              height: 1.24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ── 여행 항목 ─────────────────────────────────────────────────
class _TripRow extends StatelessWidget {
  final Trip trip;
  final bool isSelected;
  final VoidCallback onTap;

  const _TripRow({
    required this.trip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 71.7,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF2F8FF) : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isSelected ? const Color(0xFF0888F6) : const Color(0xFFEAF0F8),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        padding: const EdgeInsets.only(left: 24.5, right: 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 여행 이름 길이는 사용자 데이터라 한 줄로 줄여 표시한다
                  Text(
                    trip.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 14.5,
                      height: 1.24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF001635),
                    ),
                  ),
                  const SizedBox(height: 4.7),
                  Text(
                    trip.dateRange,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12,
                      height: 1.23,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF5B7BA6),
                    ),
                  ),
                ],
              ),
            ),
            _buildStatus(),
            const SizedBox(width: 8.7),
            _buildRadio(),
          ],
        ),
      ),
    );
  }

  // ─── 상태 표시 (점 + 라벨) ────────────────────────────────────────────────
  Widget _buildStatus() {
    // 만료 여행은 회색, 진행 중인 여행은 강조색을 쓴다
    final color =
        trip.isExpired ? const Color(0xFF9FB4CE) : const Color(0xFF0868DD);
    final dotColor =
        trip.isExpired ? const Color(0xFFB4C4D8) : const Color(0xFF22C55E);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6.7),
        Text(
          trip.isExpired ? '만료' : '진행 중',
          style: GoogleFonts.notoSansKr(
            fontSize: 11.5,
            height: 1.28,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─── 선택 표시 (라디오) ───────────────────────────────────────────────────
  Widget _buildRadio() {
    if (!isSelected) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFDCE7F7), width: 1.5),
        ),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFF0888F6),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.check_rounded, size: 15, color: Colors.white),
      ),
    );
  }
}
