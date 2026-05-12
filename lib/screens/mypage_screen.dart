import 'package:flutter/material.dart';

class MypageScreen extends StatelessWidget {
  const MypageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmergencyBanner(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('현재 보험'),
                  const SizedBox(height: 10),
                  _buildCurrentInsuranceCard(),
                  const SizedBox(height: 10),
                  _buildPrevInsuranceCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('계정 관리'),
                  const SizedBox(height: 10),
                  _buildAccountCard(),
                  const SizedBox(height: 16),
                  _buildLogoutButton(),
                  const SizedBox(height: 12),
                  _buildWithdrawButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 상단 헤더 (파란 그라디언트) ─────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.55, 1.0],
          colors: [
            Color(0xFF003979),
            Color(0xFF004D9D),
            Color(0xFF0888F6),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6E8FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('🐰', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                '류지 님',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 통계 카드 3개
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  content: const Text('🇯🇵', style: TextStyle(fontSize: 20)),
                  label: '일본 · D-7',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  content: const Text(
                    '10',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  label: '이용 보험',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  content: const Text(
                    '33',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  label: '보장 항목',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required Widget content, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFE1EDF8), width: 1),
      ),
      child: Column(
        children: [
          content,
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 긴급 전화 배너 ───────────────────────────────────────────────────────
  Widget _buildEmergencyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCCCC)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFC0392B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('📞', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '긴급 전화',
                  style: TextStyle(
                    color: Color(0xFFC0392B),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '대사관 · 보험사 번호 바로 확인',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFC0392B), size: 22),
        ],
      ),
    );
  }

  // ─── 섹션 타이틀 ──────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ─── 현재 보험 카드 ───────────────────────────────────────────────────────
  Widget _buildCurrentInsuranceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E9FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF1FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('🇯🇵', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '일본 여행자 보험 (한화생명)',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '2025.04.08 – 04.18 · D-7',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  '활성',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF8BA3CC), size: 20),
        ],
      ),
    );
  }

  // ─── 이전 보험 내역 카드 ──────────────────────────────────────────────────
  Widget _buildPrevInsuranceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E9FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.folder_outlined, color: Color(0xFF8BA3CC), size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이전 보험 내역 보기',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '만료된 보험 기록 전체 조회',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF8BA3CC), size: 20),
        ],
      ),
    );
  }

  // ─── 계정 관리 카드 (3개 항목) ────────────────────────────────────────────
  Widget _buildAccountCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E9FF)),
      ),
      child: Column(
        children: [
          _buildAccountRow(
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF4A6080),
            title: '프로필 편집',
            subtitle: '이름, 연락처, 여권 정보',
            badge: null,
            isFirst: true,
          ),
          const Divider(height: 1, color: Color(0xFFF0F4FF), indent: 16, endIndent: 16),
          _buildAccountRow(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF4A6080),
            title: '증권 관리',
            subtitle: 'PDF 업로드 & 보장 분석',
            badge: 'NEW',
          ),
          const Divider(height: 1, color: Color(0xFFF0F4FF), indent: 16, endIndent: 16),
          _buildAccountRow(
            icon: Icons.notifications_outlined,
            iconColor: const Color(0xFF4A6080),
            title: '알림 설정',
            subtitle: '보험 만료, 갱신 알림',
            badge: null,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String? badge,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
              ],
            ),
          ),
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0888F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF8BA3CC), size: 20),
        ],
      ),
    );
  }

  // ─── 로그아웃 버튼 ────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E9FF)),
      ),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text(
          '로그아웃',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─── 회원 탈퇴 버튼 ───────────────────────────────────────────────────────
  Widget _buildWithdrawButton() {
    return Center(
      child: TextButton(
        onPressed: () {},
        child: const Text(
          '회원 탈퇴',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}