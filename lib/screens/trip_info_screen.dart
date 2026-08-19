import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/services/trip_service.dart';
import 'concern_selection_screen.dart';

/// 증권 업로드(1단계)와 걱정 선택(3단계) 사이의 여행 정보 입력 화면.
class TripInfoScreen extends StatefulWidget {
  /// 1단계에서 선택한 보험 증권 PDF. 여행 세션 생성 요청에 함께 실려 간다.
  final PlatformFile file;

  const TripInfoScreen({super.key, required this.file});

  @override
  State<TripInfoScreen> createState() => _TripInfoScreenState();
}

class _TripInfoScreenState extends State<TripInfoScreen> {
  static const int _nameMaxLength = 20;

  /// 일반 여행자보험이 보장하는 최대 여행 일수. 이보다 길면 분석 대상이 아니다.
  static const int _maxTripDays = 90;

  static const Duration _selectionDuration = Duration(milliseconds: 180);
  static const List<String> _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

  final TextEditingController _nameController = TextEditingController();
  final TripService _tripService = TripService();

  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _focusedMonth;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // 첫 탭이 곧 출발일 선택이 되도록 비어 있는 상태에서 시작한다.
    final today = _dateOnly(DateTime.now());
    _focusedMonth = DateTime(today.year, today.month);

    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 선택 완료 여부. 출발일과 도착일이 모두 있어야 다음 단계로 갈 수 있다.
  bool get _isRangeComplete => _startDate != null && _endDate != null;

  bool get _canProceed =>
      _isRangeComplete &&
      !_isOverMaxDays &&
      !_isSubmitting &&
      _nameController.text.trim().isNotEmpty;

  int get _nights =>
      _isRangeComplete ? _endDate!.difference(_startDate!).inDays : 0;

  /// 출발일과 도착일을 모두 포함한 총 여행 일수.
  int get _totalDays => _isRangeComplete ? _nights + 1 : 0;

  /// 90일을 넘는 일정은 일반 여행자보험 분석 대상이 아니다.
  bool get _isOverMaxDays => _isRangeComplete && _totalDays > _maxTripDays;

  /// 날짜 탭 흐름
  /// 1) 첫 탭 → 출발일 지정
  /// 2) 다른 날짜 탭 → 도착일 지정 (앞 날짜를 골랐으면 순서를 자동으로 맞춘다)
  /// 3) 한 번 더 탭 → 선택 취소
  void _onDayTap(DateTime day) {
    setState(() {
      if (_isRangeComplete) {
        _startDate = null;
        _endDate = null;
      } else if (_startDate == null) {
        _startDate = day;
      } else if (_isSameDay(day, _startDate!)) {
        _startDate = null;
      } else if (day.isBefore(_startDate!)) {
        _endDate = _startDate;
        _startDate = day;
      } else {
        _endDate = day;
      }
    });
  }

  void _resetDates() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  void _moveMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      final trip = await _tripService.createTrip(
        name: _nameController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        file: widget.file,
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConcernSelectionScreen(trip: trip),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is TripException ? e.message : '여행 정보를 저장하는 중 오류가 발생했어요',
            style: GoogleFonts.notoSansKr(),
          ),
          backgroundColor: const Color(0xFF001635),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildStepIndicator(),
                    const SizedBox(height: 22),
                    _buildSectionTitle(
                      '여행 이름',
                      '나중에 찾기 쉽게 이름을 지어주세요',
                    ),
                    const SizedBox(height: 10),
                    _buildNameField(),
                    const SizedBox(height: 22),
                    _buildSectionTitle(
                      '여행 날짜',
                      '보험 기간과 맞는지 확인해 드려요',
                    ),
                    const SizedBox(height: 10),
                    _buildDateSummaryCards(),
                    if (_isOverMaxDays) _buildOverLimitNotice(),
                    const SizedBox(height: 12),
                    _buildCalendar(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: Color(0xFF001635),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '여행 정보 입력',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 18.72,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF001635),
                      ),
                    ),
                    Text(
                      '언제, 어디로 떠나시나요?',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11.44,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF4A6080),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E9FF)),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TripStepCircle(
          number: 1,
          label: 'PDF 업로드',
          state: _TripStepState.completed,
        ),
        _TripStepLine(),
        _TripStepCircle(
          number: 2,
          label: '여행 정보',
          state: _TripStepState.active,
        ),
        _TripStepLine(),
        _TripStepCircle(
          number: 3,
          label: '걱정 선택',
          state: _TripStepState.inactive,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String hint) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSansKr(
            fontSize: 14.56,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF001635),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            hint,
            style: GoogleFonts.notoSansKr(
              fontSize: 12.48,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8FA6C2),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    final hasText = _nameController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasText ? const Color(0xFF0066C3) : const Color(0xFFE2E9FF),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              maxLength: _nameMaxLength,
              cursorColor: const Color(0xFF0066C3),
              style: GoogleFonts.notoSansKr(
                fontSize: 16.64,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF001635),
              ),
              decoration: InputDecoration(
                hintText: '도쿄 벚꽃 여행',
                hintStyle: GoogleFonts.notoSansKr(
                  fontSize: 16.64,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB4C4D8),
                ),
                border: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 17),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_nameController.text.characters.length}/$_nameMaxLength',
            style: GoogleFonts.notoSansKr(
              fontSize: 12.48,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFB4C4D8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildDateCard('출발일', _startDate)),
        const SizedBox(width: 10),
        Expanded(child: _buildDateCard('도착일', _endDate)),
      ],
    );
  }

  /// 90일을 넘게 고르면 분석이 불가능하다는 것을 알리고 다시 고르도록 안내한다.
  Widget _buildOverLimitNotice() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF6C9CC), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline,
              size: 18,
              color: Color(0xFFE0555C),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_maxTripDays일이 넘는 일정이에요',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13.52,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC0343C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '일반 여행자보험은 $_maxTripDays일 이내 일정만 분석할 수 있어요.\n'
                  '지금 선택한 일정은 총 $_totalDays일이에요. 날짜를 다시 선택해 주세요.',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12.48,
                    fontWeight: FontWeight.w400,
                    height: 1.45,
                    color: const Color(0xFF8A4045),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _resetDates,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0555C),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '날짜 다시 선택',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12.48,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(String label, DateTime? date) {
    final borderColor = _isOverMaxDays
        ? const Color(0xFFF6C9CC)
        : date != null
            ? const Color(0xFFCFE0F5)
            : const Color(0xFFE2E9FF);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansKr(
              fontSize: 11.96,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8FA6C2),
            ),
          ),
          const SizedBox(height: 6),
          if (date == null)
            Text(
              '선택해 주세요',
              style: GoogleFonts.notoSansKr(
                fontSize: 14.56,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFB4C4D8),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${date.month}월 ${date.day}일',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 16.64,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF001635),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _weekdayLabels[date.weekday % 7],
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13.52,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5B7BA6),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    // 날짜 셀의 잉크 효과가 보이도록 카드 자체를 Material로 만든다.
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E9FF), width: 1),
        ),
        child: Column(
          children: [
            _buildCalendarHeader(),
            const SizedBox(height: 14),
            _buildWeekdayHeader(),
            const SizedBox(height: 6),
            _buildDayGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CalendarArrow(
          icon: Icons.chevron_left,
          onTap: () => _moveMonth(-1),
        ),
        Text(
          '${_focusedMonth.year}년 ${_focusedMonth.month}월',
          style: GoogleFonts.notoSansKr(
            fontSize: 15.08,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF001635),
          ),
        ),
        _CalendarArrow(
          icon: Icons.chevron_right,
          onTap: () => _moveMonth(1),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    return Row(
      children: List.generate(7, (i) {
        return Expanded(
          child: Center(
            child: Text(
              _weekdayLabels[i],
              style: GoogleFonts.notoSansKr(
                fontSize: 11.44,
                fontWeight: FontWeight.w700,
                color: _weekdayColor(i, isHeader: true),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// 일요일은 빨강, 토요일은 파랑, 나머지는 기본색.
  Color _weekdayColor(int weekdayIndex, {required bool isHeader}) {
    if (weekdayIndex == 0) return const Color(0xFFE0555C);
    if (weekdayIndex == 6) return const Color(0xFF5B8CD8);
    return isHeader ? const Color(0xFF8FA6C2) : const Color(0xFF3B5878);
  }

  Widget _buildDayGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    // Dart의 weekday는 월=1 ~ 일=7이라, 일요일 시작 그리드에 맞게 보정한다.
    final leadingBlanks = firstDay.weekday % 7;
    final totalCells = leadingBlanks + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rowCount, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final dayNumber = cellIndex - leadingBlanks + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const Expanded(child: SizedBox(height: 40));
            }
            return Expanded(
              child: _buildDayCell(
                DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber),
                col,
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildDayCell(DateTime day, int weekdayIndex) {
    final isPast = day.isBefore(_dateOnly(DateTime.now()));
    final isStart = _startDate != null && _isSameDay(day, _startDate!);
    final isEnd = _endDate != null && _isSameDay(day, _endDate!);
    final isEndpoint = isStart || isEnd;
    final inRange = _isRangeComplete &&
        !day.isBefore(_startDate!) &&
        !day.isAfter(_endDate!);

    final Color textColor;
    if (isEndpoint) {
      textColor = Colors.white;
    } else if (inRange) {
      textColor = const Color(0xFF0066C3);
    } else if (isPast) {
      textColor = const Color(0xFFB4C4D8);
    } else {
      textColor = _weekdayColor(weekdayIndex, isHeader: false);
    }

    return InkResponse(
      onTap: () => _onDayTap(day),
      radius: 22,
      customBorder: const CircleBorder(),
      highlightColor: const Color(0x140066C3),
      splashColor: const Color(0x1F0066C3),
      child: SizedBox(
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: _selectionDuration,
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: inRange
                      ? const Color(0xFFEBF3FF)
                      : const Color(0x00EBF3FF),
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(isStart || !inRange ? 16 : 0),
                    right: Radius.circular(isEnd || !inRange ? 16 : 0),
                  ),
                ),
              ),
            ),
            AnimatedScale(
              scale: isEndpoint ? 1 : 0,
              duration: _selectionDuration,
              curve: Curves.easeOutBack,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF0066C3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            AnimatedDefaultTextStyle(
              duration: _selectionDuration,
              curve: Curves.easeOut,
              style: GoogleFonts.notoSansKr(
                fontSize: 13.52,
                fontWeight: (isEndpoint || inRange)
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: textColor,
              ),
              child: Text('${day.day}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E9FF)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  '여행 기간',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13.52,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5B7BA6),
                  ),
                ),
                const Spacer(),
                Text(
                  _isOverMaxDays
                      ? '$_totalDays일 · $_maxTripDays일 초과'
                      : _isRangeComplete
                          ? '$_nights박 ${_nights + 1}일'
                          : '날짜를 선택해 주세요',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14.56,
                    fontWeight: FontWeight.w700,
                    color: _isOverMaxDays
                        ? const Color(0xFFE0555C)
                        : _isRangeComplete
                            ? const Color(0xFF001635)
                            : const Color(0xFF8FA6C2),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _canProceed ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066C3),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD0DCF0),
                  disabledForegroundColor: const Color(0xFF8BA3CC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        '다음',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 15.6,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CalendarArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36,
        height: 28,
        child: Icon(icon, size: 22, color: const Color(0xFF5B7BA6)),
      ),
    );
  }
}

enum _TripStepState { completed, active, inactive }

class _TripStepCircle extends StatelessWidget {
  final int number;
  final String label;
  final _TripStepState state;

  const _TripStepCircle({
    required this.number,
    required this.label,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = state == _TripStepState.completed;
    final isActive = state == _TripStepState.active;
    final isInactive = state == _TripStepState.inactive;

    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: (isCompleted || isActive)
                ? const Color(0xFF0066C3)
                : Colors.transparent,
            shape: BoxShape.circle,
            border: isInactive
                ? Border.all(color: const Color(0xFF8BA3CC), width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '$number',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12.48,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : const Color(0xFF8BA3CC),
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 10.4,
            fontWeight: FontWeight.w700,
            color: (isCompleted || isActive)
                ? const Color(0xFF0066C3)
                : const Color(0xFF8BA3CC),
          ),
        ),
      ],
    );
  }
}

class _TripStepLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 1,
      margin: const EdgeInsets.only(bottom: 20),
      color: const Color(0xFFD0DCF0),
    );
  }
}
