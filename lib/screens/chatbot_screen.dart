import 'dart:math';
import 'package:flutter/material.dart';
import '../core/models/chat_message.dart';
import '../core/models/hospital_result.dart';
import '../core/services/hospital_service.dart';
import '../widgets/hospital_card.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final HospitalService _hospitalService = HospitalService();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  static const _hospitalKeywords = [
    '병원', '응급실', '의원', '클리닉', '주변 병원', '가까운 병원', '병원 찾기',
    '주변 병원을 보여줘', '병원 보여줘', '병원 알려줘',
  ];
  static const _negationWords = ['싫어', '말고', '아니'];

  static const _flightDelayKeywords = ['지연', '연착'];
  static const _compensationKeywords = ['보상', '환급', '받을 수 있', '돼', '될까', '되나'];

  bool _isFlightDelayIntent(String text) {
    final hasDelay = _flightDelayKeywords.any((w) => text.contains(w));
    final hasCompensation = _compensationKeywords.any((w) => text.contains(w));
    return hasDelay && hasCompensation;
  }

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage.bot('안녕하세요, 류지님! ⭐\n일본 여행 중이시군요.\n무엇을 도와드릴까요?'),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  bool _isHospitalIntent(String text) {
    if (_negationWords.any((w) => text.contains(w))) return false;
    return _hospitalKeywords.any((w) => text.contains(w));
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() => _messages.add(ChatMessage.user(trimmed)));
    _scrollToBottom();

    if (_isHospitalIntent(trimmed)) {
      await _handleHospitalSearch();
    } else if (_isFlightDelayIntent(trimmed)) {
      await _handleFlightDelayCompensation();
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage.bot(
            '죄송해요, 현재는 병원 찾기 기능만 지원하고 있어요.\n하단의 "🏥 병원 찾기"를 눌러보세요!',
          ),
        );
      });
      _scrollToBottom();
    }
  }

  Future<void> _handleFlightDelayCompensation() async {
    setState(() {
      _isLoading = true;
      _messages.add(ChatMessage.loading());
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _messages.removeLast();
      _isLoading = false;
      _messages.add(ChatMessage.bot(
        '아쉽게도 2시간 지연은 보상 대상이 아니에요 😢\n\n'
        '✈️ 항공 지연 보상 기준\n'
        '• 3시간 이상 ~ 5시간 미만: 최대 10만원\n'
        '• 5시간 이상 ~ 7시간 미만: 최대 20만원\n'
        '• 7시간 이상: 최대 30만원\n\n'
        '지연이 3시간을 넘기면 항공사에서 발급하는 '
        '지연 확인서를 꼭 챙겨두세요!\n'
        '귀국 후 보험사에 청구하시면 돼요 😊',
      ));
    });
    _scrollToBottom();
  }

  Future<void> _handleHospitalSearch() async {
    setState(() {
      _isLoading = true;
      _messages.add(ChatMessage.loading());
    });
    _scrollToBottom();

    try {
      final hospitals = await _hospitalService.fetchNearbyHospitals(context);
      if (!mounted) return;

      setState(() {
        _messages.removeLast();
        _isLoading = false;
        if (hospitals.isEmpty) {
          _messages.add(
            ChatMessage.bot('주변 3km 내에 병원을 찾지 못했어요.\n다시 시도하거나 검색 범위를 넓혀보세요.'),
          );
        } else {
          _messages.add(
            ChatMessage.bot('현재 위치 기준 병원이에요 🏥', hospitals: hospitals),
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _isLoading = false;
        _messages.add(
          ChatMessage.bot('병원 정보를 불러오는 중 오류가 발생했어요.\n잠시 후 다시 시도해 주세요.'),
        );
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMessageWidget(_messages[index]),
              ),
            ),
          ),
          _QuickReplyBar(onChipTap: _sendMessage),
          _InputBar(
            controller: _inputController,
            onSend: () => _sendMessage(_inputController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageWidget(ChatMessage msg) {
    if (msg.contentType == MessageContentType.loading) {
      return const _LoadingMessage();
    }
    if (msg.sender == MessageSender.user) {
      return _UserMessage(text: msg.text, time: msg.formattedTime);
    }
    if (msg.contentType == MessageContentType.hospitalCards) {
      return _BotMessageWithCards(
        text: msg.text,
        time: msg.formattedTime,
        hospitals: msg.hospitals,
      );
    }
    return _BotMessage(text: msg.text, time: msg.formattedTime);
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
              child: Text('🐰', style: TextStyle(fontSize: 20.8)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PoPo',
                style: TextStyle(
                  fontSize: 15.6,
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
                      fontSize: 11.44,
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

// ── PoPo 아바타 ───────────────────────────────────────────────
class _BotAvatar extends StatelessWidget {
  const _BotAvatar();

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
        child: Text('🐰', style: TextStyle(fontSize: 18.72)),
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
        const _BotAvatar(),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FF),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: const Color(0xFFE8EDFF), width: 1),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14.56,
                color: Color(0xFF1A2B4A),
                height: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          time,
          style: const TextStyle(fontSize: 10.4, color: Color(0xFFB0BAD0)),
        ),
      ],
    );
  }
}

// ── 봇 로딩 메시지 ────────────────────────────────────────────
class _LoadingMessage extends StatelessWidget {
  const _LoadingMessage();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _BotAvatar(),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FF),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(color: const Color(0xFFE8EDFF), width: 1),
          ),
          child: const _TypingDots(),
        ),
      ],
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final opacity = ((sin((t - i * 0.2) * 2 * 3.14159) + 1) / 2)
                .clamp(0.2, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D3E8F),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
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
          style: const TextStyle(fontSize: 10.4, color: Color(0xFFB0BAD0)),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0E2A6E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14.56,
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

// ── 봇 메시지 + 병원 카드 ─────────────────────────────────────
class _BotMessageWithCards extends StatelessWidget {
  final String text;
  final String time;
  final List<HospitalResult> hospitals;
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
        const _BotAvatar(),
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
                        fontSize: 14.56,
                        color: Color(0xFF1A2B4A),
                        height: 1.5,
                      ),
                    ),
                    ...hospitals.map((h) => HospitalCard(hospital: h)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          time,
          style: const TextStyle(fontSize: 10.4, color: Color(0xFFB0BAD0)),
        ),
      ],
    );
  }
}

// ── 빠른 답변 칩 바 ───────────────────────────────────────────
class _QuickReplyBar extends StatelessWidget {
  final void Function(String) onChipTap;
  const _QuickReplyBar({required this.onChipTap});

  static const _chips = [
    '🏥 주변 병원을 보여줘',
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
                onTap: () => onChipTap(chip),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFFBFD0FF), width: 1),
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
                      fontSize: 13.52,
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
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.onSend});

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
                style:
                    const TextStyle(fontSize: 14.56, color: Color(0xFF1A2B4A)),
                decoration: const InputDecoration(
                  hintText: '메시지를 입력하세요',
                  hintStyle:
                      TextStyle(fontSize: 14.56, color: Color(0xFFB0BAD0)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFF0E2A6E),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
