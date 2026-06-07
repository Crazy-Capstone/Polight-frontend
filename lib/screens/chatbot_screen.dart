import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _AppBar(),
      body: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEF2FF)),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              children: [
                _DateChip(label: '오늘 오후 2:14'),
                const SizedBox(height: 16),
                _BotMessage(
                  text: '안녕하세요, 류지님! ⭐\n일본 여행 중이시군요.\n무엇을 도와드릴까요?',
                  time: '오후 2:14',
                ),
                const SizedBox(height: 12),
                _UserMessage(
                  text: '가까운 병원을\n알고 싶어요',
                  time: '오후 2:14',
                ),
                const SizedBox(height: 12),
                _BotMessageWithCards(
                  text: '현재 위치 기준 병원이에요 🏥',
                  time: '오후 2:15',
                  hospitals: const [
                    _HospitalData(
                      name: '도쿄 세이루카이 국제병원',
                      description: '한국어 통역 가능 · 1.2km',
                    ),
                    _HospitalData(
                      name: '도쿄 글로벌 클리닉',
                      description: '한국어 통역 가능 · 2.8km',
                    ),
                  ],
                ),
              ],
            ),
          ),
          _QuickReplyBar(),
          _InputBar(controller: _inputController),
        ],
      ),
    );
  }
}

// ── 앱바 ─────────────────────────────────────────────────────
class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 40,
      leading: const Padding(
        padding: EdgeInsets.only(left: 12),
        child: Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF1A2B4A)),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1D3E8F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🐰', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PoPo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F1C3F),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '지금 응답 가능',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Icon(Icons.more_horiz, color: Color(0xFF6B7280), size: 24),
        ),
      ],
    );
  }
}

// ── 날짜 구분선 ───────────────────────────────────────────────
class _DateChip extends StatelessWidget {
  final String label;
  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5FB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── PoPo 아바타 ───────────────────────────────────────────────
class _BotAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF1D3E8F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text('🐰', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

// ── 봇 메시지 ─────────────────────────────────────────────────
class _BotMessage extends StatelessWidget {
  final String text;
  final String time;
  const _BotMessage({required this.text, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _BotAvatar(),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FF),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(color: const Color(0xFFE8EDFF), width: 1),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A2B4A),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          time,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFFB0BAD0),
          ),
        ),
      ],
    );
  }
}

// ── 유저 메시지 ───────────────────────────────────────────────
class _UserMessage extends StatelessWidget {
  final String text;
  final String time;
  const _UserMessage({required this.text, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          time,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFFB0BAD0),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0E2A6E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(0),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 병원 데이터 ───────────────────────────────────────────────
class _HospitalData {
  final String name;
  final String description;
  const _HospitalData({required this.name, required this.description});
}

// ── 병원 카드 ─────────────────────────────────────────────────
class _HospitalCard extends StatelessWidget {
  final _HospitalData data;
  const _HospitalCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EAF5), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('🏥', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F1C3F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFD0FF), width: 1),
            ),
            child: const Text(
              '제휴',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0066C3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 봇 메시지 + 카드 ──────────────────────────────────────────
class _BotMessageWithCards extends StatelessWidget {
  final String text;
  final String time;
  final List<_HospitalData> hospitals;
  const _BotMessageWithCards({
    required this.text,
    required this.time,
    required this.hospitals,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _BotAvatar(),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FF),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(color: const Color(0xFFE8EDFF), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A2B4A),
                        height: 1.5,
                      ),
                    ),
                    ...hospitals.map((h) => _HospitalCard(data: h)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          time,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFFB0BAD0),
          ),
        ),
      ],
    );
  }
}

// ── 빠른 답변 칩 바 ───────────────────────────────────────────
class _QuickReplyBar extends StatelessWidget {
  static const List<String> _chips = [
    '🏥 병원 찾기',
    '📋 증권 확인',
    '💰 보장 한도',
    '💬 통역 지원',
    '🚑 긴급 연락',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEF2FF), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _chips.map((chip) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBFD0FF), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B5BDB).withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    chip,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1D3E8F),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── 입력 바 ───────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  const _InputBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEF2FF), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFDDE5FF), width: 1),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A2B4A)),
                decoration: const InputDecoration(
                  hintText: '메시지를 입력하세요',
                  hintStyle: TextStyle(fontSize: 14, color: Color(0xFFB0BAD0)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFF0E2A6E),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}
