import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── 데이터 모델 ───────────────────────────────────────────────
class SummaryItem {
  final String label;
  final String value;
  const SummaryItem({required this.label, required this.value});
}

class DetailItem {
  final String title;
  final String subtitle;
  final bool isCovered;
  const DetailItem({
    required this.title,
    required this.subtitle,
    required this.isCovered,
  });
}

// ── 화면 ─────────────────────────────────────────────────────
class CoverageDetailScreen extends StatelessWidget {
  final String emoji;
  final String coverageTitle;
  final String insurer;
  final String maxLimit;
  final List<SummaryItem> summaryItems;
  final List<DetailItem> detailItems;

  const CoverageDetailScreen({
    super.key,
    required this.emoji,
    required this.coverageTitle,
    required this.insurer,
    required this.maxLimit,
    required this.summaryItems,
    required this.detailItems,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _BlueHeader(
              emoji: emoji,
              coverageTitle: coverageTitle,
              insurer: insurer,
              maxLimit: maxLimit,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummarySection(items: summaryItems),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFE2E9FF)),
                    _DetailSection(items: detailItems),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 파란 헤더 영역 ────────────────────────────────────────────
class _BlueHeader extends StatelessWidget {
  final String emoji;
  final String coverageTitle;
  final String insurer;
  final String maxLimit;

  const _BlueHeader({
    required this.emoji,
    required this.coverageTitle,
    required this.insurer,
    required this.maxLimit,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.563, 0.9383],
          colors: [
            Color(0xFF004D9D),
            Color(0xFF0066C3),
            Color(0xFF0888F6),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 앱바 행
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '보장 상세',
                    style: TextStyle(
                      fontSize: 17.68,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    coverageTitle,
                    style: TextStyle(
                      fontSize: 12.48,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9EBEFE),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 보험 정보 카드
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24.96)),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coverageTitle,
                    style: const TextStyle(
                      fontSize: 18.72,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    insurer,
                    style: TextStyle(
                      fontSize: 12.48,
                      color: Color(0xFF9EBEFE),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 보장 한도 바
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF69A3FD),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '보장 한도',
                  style: TextStyle(
                    fontSize: 12.48,
                    color: Color(0xFF69A3FD),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                Text(
                  maxLimit,
                  style: const TextStyle(
                    fontSize: 14.56,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 요약 섹션 (카드 3개) ─────────────────────────────────────
class _SummarySection extends StatelessWidget {
  final List<SummaryItem> items;
  const _SummarySection({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        children: List.generate(items.length * 2 - 1, (i) {
          if (i.isOdd) return const SizedBox(width: 8);
          final item = items[i ~/ 2];
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E9FF), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 10.4,
                      color: Color(0xFF4A6080),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 12.48,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF001635),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF69A3FD),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── 보장 항목 섹션 ────────────────────────────────────────────
class _DetailSection extends StatelessWidget {
  final List<DetailItem> items;
  const _DetailSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '보장 항목',
            style: TextStyle(
              fontSize: 15.6,
              fontWeight: FontWeight.w700,
              color: Color(0xFF001635),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _DetailItemRow(item: item)),
        ],
      ),
    );
  }
}

class _DetailItemRow extends StatelessWidget {
  final DetailItem item;
  const _DetailItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 7, 14, 10),
      decoration: BoxDecoration(
        color: item.isCovered
            ? Colors.white
            : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isCovered
              ? const Color(0xFFE2E9FF)
              : const Color(0xFFFFCCCC),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.isCovered
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                item.isCovered ? '✔️' : '❌',
                style: const TextStyle(fontSize: 16.64),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13.52,
                    fontWeight: FontWeight.w700,
                    color: item.isCovered
                        ? const Color(0xFF001635)
                        : const Color(0xFFCC3333),
                  ),
                ),
                const SizedBox(height: 0),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 11.44,
                    fontWeight: FontWeight.w400,
                    color: item.isCovered
                        ? const Color(0xFF4A6080)
                        : const Color(0xFFCC9999),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
