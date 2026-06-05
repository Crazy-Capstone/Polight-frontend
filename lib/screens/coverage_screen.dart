import 'package:flutter/material.dart';

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

  const CoverageItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.limitLabel,
    this.isCovered = true,
  });
}

// ── 화면 ─────────────────────────────────────────────────────
class CoverageScreen extends StatelessWidget {
  const CoverageScreen({super.key});

  static const List<CoverageItem> _items = [
    CoverageItem(
      emoji: '🏥',
      title: '의료비',
      subtitle: '입원·통원·응급 치료',
      limitLabel: '최대 1억원',
    ),
    CoverageItem(
      emoji: '✈️',
      title: '항공 지연',
      subtitle: '3시간 이상 지연',
      limitLabel: '최대 30만원',
    ),
    CoverageItem(
      emoji: '🧳',
      title: '수하물',
      subtitle: '항공사 귀책 한정',
      limitLabel: '최대 50만원',
    ),
    CoverageItem(
      emoji: '🚑',
      title: '긴급 이송',
      subtitle: '의료진 동반 후송',
      limitLabel: '한도 없음',
    ),
    CoverageItem(
      emoji: '🦷',
      title: '치과 응급',
      subtitle: '급성 치통·외상',
      limitLabel: '최대 50만원',
    ),
    CoverageItem(
      emoji: '⚖️',
      title: '배상 책임',
      subtitle: '제3자 피해 보상',
      limitLabel: '최대 1억원',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '보장 내역',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF001635),
                      ),
                    ),
                    _TripBadge(),
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
                child: _TripDateBanner(),
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

// ── 여행 뱃지 ─────────────────────────────────────────────────
class _TripBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFEBF1FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCEDDFE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🇯🇵', style: TextStyle(fontSize: 16)),
          SizedBox(width: 2),
          Text(
            '일본 여행',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF004D9D),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 여행 기간 배너 ─────────────────────────────────────────────
class _TripDateBanner extends StatelessWidget {
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
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          const Text(
            '2025. 04. 08 — 04. 18',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF001635),
            ),
          ),
          const Spacer(),
            const Text(
            'D-7 남음',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0066C3),
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
                            style: const TextStyle(fontSize: 20),
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
                            fontSize: 9,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF001635),
                    ),
                  ),

                  // 부제목
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
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
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: item.isCovered
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF9BAEC8),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          '상세보기 ›',
                          style: TextStyle(
                            fontSize: 10,
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