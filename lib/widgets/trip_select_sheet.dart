import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
}

// 여행 선택 목록. 진행 중인 여행이 맨 위에 온다.
const List<Trip> kTrips = [
  Trip(
    name: '일본 여행',
    dateRange: '2025.04.08 – 04.18',
    isExpired: false,
    flag: '🇯🇵',
  ),
  Trip(
    name: '베트남 다낭 가족여행',
    dateRange: '2025.01.11 – 01.17',
    flag: '🇻🇳',
  ),
  Trip(name: '파리 출장', dateRange: '2024.11.03 – 11.09', flag: '🇫🇷'),
  Trip(name: '태국 방콕 혼자 여행', dateRange: '2024.08.20 – 08.27', flag: '🇹🇭'),
];

/// 여행 선택 바텀시트를 띄우고, 사용자가 '이 여행으로 보기'를 누르면
/// 선택한 [Trip]을 돌려준다. 닫기·스크림 탭 시에는 null.
Future<Trip?> showTripSelectSheet(
  BuildContext context, {
  required Trip selected,
  List<Trip> trips = kTrips,
}) {
  return showModalBottomSheet<Trip>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // 디자인 스크림: #001028 45%
    barrierColor: const Color(0x73001028),
    builder: (_) => TripSelectSheet(selected: selected, trips: trips),
  );
}

// ── 바텀시트 ──────────────────────────────────────────────────
class TripSelectSheet extends StatefulWidget {
  final Trip selected;
  final List<Trip> trips;

  const TripSelectSheet({
    super.key,
    required this.selected,
    required this.trips,
  });

  @override
  State<TripSelectSheet> createState() => _TripSelectSheetState();
}

class _TripSelectSheetState extends State<TripSelectSheet> {
  // 시트 높이 / 화면 높이 (디자인 493.49 / 856.23)
  static const double _heightFactor = 0.5764;

  late Trip _selected = widget.selected;

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
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: widget.trips.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8.4),
                itemBuilder: (_, i) {
                  final trip = widget.trips[i];
                  return _TripRow(
                    trip: trip,
                    isSelected: trip.name == _selected.name,
                    onTap: () => setState(() => _selected = trip),
                  );
                },
              ),
            ),
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
