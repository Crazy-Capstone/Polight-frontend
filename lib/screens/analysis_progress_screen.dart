import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../core/models/trip_analysis.dart';
import '../core/models/trip_document.dart';
import '../core/models/trip_session.dart';
import '../core/services/trip_service.dart';

/// 증권 분석이 진행되는 동안 보여주는 화면.
/// 서버는 진행률(%)을 주지 않으므로, 완료될 때까지 서서히 올라가다가
/// 실제로 COMPLETED가 되면 100%로 마무리하는 방식으로 대신한다.
class AnalysisProgressScreen extends StatefulWidget {
  final TripSession trip;
  final TripDocument document;
  final TripAnalysis initialAnalysis;

  const AnalysisProgressScreen({
    super.key,
    required this.trip,
    required this.document,
    required this.initialAnalysis,
  });

  @override
  State<AnalysisProgressScreen> createState() =>
      _AnalysisProgressScreenState();
}

class _AnalysisProgressScreenState extends State<AnalysisProgressScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _hints = [
    '보험 증권을 꼼꼼히 읽고 있어요',
    '보장 항목을 하나씩 정리하고 있어요',
    '중요한 조건을 놓치지 않는지 확인하고 있어요',
  ];

  static const Duration _pollInterval = Duration(seconds: 3);
  static const Duration _hintInterval = Duration(milliseconds: 2600);

  final TripService _tripService = TripService();
  late final AnimationController _progressController;

  Timer? _pollTimer;
  Timer? _hintTimer;
  String _status = 'PROCESSING';
  String? _failureReason;
  int _hintIndex = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..addListener(() => setState(() {}));

    _startHintCarousel();
    _handleStatus(
      widget.initialAnalysis.status,
      failureReason: widget.initialAnalysis.failureReason,
    );
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _hintTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _startHintCarousel() {
    _hintTimer = Timer.periodic(_hintInterval, (_) {
      if (!mounted) return;
      setState(() => _hintIndex = (_hintIndex + 1) % _hints.length);
    });
  }

  Future<void> _poll() async {
    if (_finished) return;
    try {
      final analysis = await _tripService.getAnalysis(
        tripId: widget.trip.id,
        documentId: widget.document.id,
      );
      developer.log(
        '분석 상태 폴링 성공 status=${analysis.status} failureReason=${analysis.failureReason}',
        name: 'AnalysisProgressScreen',
      );
      if (!mounted) return;
      _handleStatus(analysis.status, failureReason: analysis.failureReason);
    } catch (e, stackTrace) {
      // 일시적인 네트워크 오류는 다음 폴링에서 다시 시도한다.
      developer.log(
        '분석 상태 폴링 실패',
        name: 'AnalysisProgressScreen',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _handleStatus(String status, {String? failureReason}) {
    if (_finished) return;

    setState(() {
      _status = status;
      _failureReason = failureReason;
    });

    switch (status) {
      case 'COMPLETED':
        _finish();
        break;
      case 'FAILED':
        _pollTimer?.cancel();
        _hintTimer?.cancel();
        _progressController.stop();
        break;
      default:
        if (!_progressController.isAnimating &&
            _progressController.value < 0.9) {
          _progressController.animateTo(0.9, curve: Curves.easeOutCubic);
        }
    }
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _pollTimer?.cancel();
    _hintTimer?.cancel();

    await _progressController.animateTo(
      1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // 하단 GNB가 있는 탭 화면으로 돌아가야 하므로, 이 위로 쌓인 화면을 모두
    // 걷어내고 '보장내역' 탭으로 전환한다 (push 대신 탭 전환).
    Navigator.of(context).popUntil((route) => route.isFirst);
    showCoverageTabForTrip(trip: widget.trip, document: widget.document);
  }

  void _retry() {
    setState(() {
      _finished = false;
      _status = 'PROCESSING';
      _failureReason = null;
    });
    _progressController
      ..reset()
      ..animateTo(0.9,
          duration: const Duration(seconds: 45), curve: Curves.easeOutCubic);
    _startHintCarousel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  int get _progressPercent => (_progressController.value * 100).round();

  @override
  Widget build(BuildContext context) {
    final isFailed = _status == 'FAILED';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF002757), Color(0xFF0888F6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildGlow(
                      size: 320,
                      color: const Color(0xFF004D9D),
                      opacity: 0.35,
                      blurSigma: 40,
                    ),
                    _buildGlow(
                      size: 190,
                      color: const Color(0xFF0888F6),
                      opacity: 0.3,
                      blurSigma: 30,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildRing(),
                        const SizedBox(height: 34),
                        _buildFilePill(),
                        const SizedBox(height: 14),
                        isFailed ? _buildFailedContent() : _buildDotsAndHint(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '증권 분석 중',
                style: GoogleFonts.notoSansKr(
                  fontSize: 18.72,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '잠시만 기다려 주세요',
                style: GoogleFonts.notoSansKr(
                  fontSize: 11.44,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9EBEFE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlow({
    required double size,
    required Color color,
    required double opacity,
    required double blurSigma,
  }) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(opacity),
          ),
        ),
      ),
    );
  }

  Widget _buildRing() {
    const double size = 210;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _RingPainter(progress: _progressController.value),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🤖', style: TextStyle(fontSize: 37.44)),
              const SizedBox(height: 4),
              Text(
                '$_progressPercent%',
                style: GoogleFonts.notoSansKr(
                  fontSize: 22.88,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '분석 중',
                style: GoogleFonts.notoSansKr(
                  fontSize: 12.48,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9EBEFE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilePill() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📄', style: TextStyle(fontSize: 16.64)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.document.originalFilename,
              style: GoogleFonts.notoSansKr(
                fontSize: 12.48,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF002858),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotsAndHint() {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_hints.length, (i) {
            final active = i == _hintIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 8 : 6,
              height: active ? 8 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? const Color(0xFF69A3FD)
                    : const Color(0xFF9EBEFE),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _hints[_hintIndex],
          style: GoogleFonts.notoSansKr(
            fontSize: 13.52,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFailedContent() {
    return Column(
      children: [
        Text(
          _failureReason ?? '분석 중 문제가 발생했어요',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansKr(
            fontSize: 13.52,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _retry,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: Text(
            '다시 시도',
            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  static const double _radius = 81;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    void strokeCircle(double radius, Color color, double strokeWidth) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }

    strokeCircle(100.5, Colors.white.withOpacity(0.03), 1);
    strokeCircle(88.5, Colors.white.withOpacity(0.04), 1);
    strokeCircle(_radius, Colors.white.withOpacity(0.07), 10);

    final sweep = progress.clamp(0.0, 1.0) * 2 * math.pi;
    if (sweep <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: _radius);
    final arcPaint = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFF9EBEFE), Color(0xFF0888F6)],
        startAngle: 0,
        endAngle: 2 * math.pi,
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweep, false, arcPaint);

    final handleAngle = -math.pi / 2 + sweep;
    final handleCenter = Offset(
      center.dx + _radius * math.cos(handleAngle),
      center.dy + _radius * math.sin(handleAngle),
    );
    canvas.drawCircle(
      handleCenter,
      14,
      Paint()
        ..color = const Color(0xFF69A3FD).withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(handleCenter, 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
