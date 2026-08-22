import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_log.dart';
import '../core/inline_markdown.dart';
import '../core/models/chat_answer.dart';
import '../core/models/chat_message.dart';
import '../core/models/place_category.dart';
import '../core/models/place_result.dart';
import '../core/services/chat_service.dart';
import '../core/services/place_service.dart';
import '../core/services/token_storage.dart';
import '../core/services/trip_service.dart';
import '../widgets/place_card.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  static const String _logName = 'ChatbotScreen';

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final PlaceService _placeService = PlaceService();
  final ChatService _chatService = ChatService();
  final TripService _tripService = TripService();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  /// 질문을 보낼 여행. 대화 세션은 여행당 하나라 이 id가 곧 대화방이다.
  String? _tripId;
  String? _tripName;

  static const _negationWords = ['싫어', '말고', '아니'];

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage.bot(_greeting('회원')));
    _loadNickname();
    _loadTripAndHistory();
  }

  String _greeting(String name) =>
      '안녕하세요, $name님! ⭐\n보험 약관에 대해 궁금한 걸 물어보세요.';

  Future<void> _loadNickname() async {
    try {
      final profile = await TokenStorage().readProfile();
      if (mounted && profile.nickname != null && _messages.isNotEmpty) {
        setState(() {
          _messages[0] = ChatMessage.bot(_greeting(profile.nickname!));
        });
      }
    } catch (_) {
      // 저장된 닉네임이 없거나 조회에 실패하면 기본 인사말을 그대로 쓴다
    }
  }

  /// 가장 최근 여행을 대화 대상으로 잡고, 서버에 저장된 지난 대화를 불러온다.
  Future<void> _loadTripAndHistory() async {
    try {
      final sessions = await _tripService.listTrips();
      if (!mounted || sessions.isEmpty) {
        if (sessions.isEmpty) appLog(_logName, '등록된 여행이 없어 챗봇 질문 불가');
        return;
      }

      final trip = sessions.first;
      setState(() {
        _tripId = trip.id;
        _tripName = trip.name;
      });

      final history = await _chatService.getHistory(tripId: trip.id);
      if (!mounted || history.messages.isEmpty) return;

      setState(() {
        for (final m in history.messages) {
          if (m.content.isEmpty) continue;
          _messages.add(
            m.isUser
                ? ChatMessage.user(m.content, at: m.createdAt)
                : ChatMessage.bot(m.content, at: m.createdAt),
          );
        }
      });
      _scrollToBottom();
    } catch (e) {
      appLog(_logName, '여행/대화 이력 불러오기 실패: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  /// 문장에서 찾아야 할 장소 종류를 골라낸다. 해당 없으면 null.
  PlaceCategory? _detectPlaceCategory(String text) {
    if (_negationWords.any((w) => text.contains(w))) return null;
    for (final category in PlaceCategory.values) {
      if (category.keywords.any((w) => text.contains(w))) return category;
    }
    return null;
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() => _messages.add(ChatMessage.user(trimmed)));
    _scrollToBottom();

    // 주변 장소 찾기는 위치 기반이라 앱에서 직접 처리하고,
    // 그 외 질문은 약관을 근거로 답하는 챗봇 API에 넘긴다.
    final category = _detectPlaceCategory(trimmed);
    if (category != null) {
      await _handlePlaceSearch(category);
    } else {
      await _askChatbot(trimmed);
    }
  }

  /// 약관 기반 답변을 백엔드 AI에 요청한다.
  /// 502(AI 서버 무응답)여도 질문은 서버에 저장되어 있으므로 화면에서 지우지 않는다.
  Future<void> _askChatbot(String question) async {
    final tripId = _tripId;
    if (tripId == null) {
      setState(() {
        _messages.add(ChatMessage.bot(
          '아직 등록된 여행이 없어요.\n증권을 먼저 업로드하면 약관을 바탕으로 답변해 드릴 수 있어요.',
        ));
      });
      _scrollToBottom();
      return;
    }

    setState(() {
      _isLoading = true;
      _messages.add(ChatMessage.loading());
    });
    _scrollToBottom();

    try {
      final answer = await _chatService.ask(tripId: tripId, question: question);
      if (!mounted) return;
      setState(() {
        _messages.removeLast(); // 로딩 표시 제거
        _isLoading = false;
        _messages.add(ChatMessage.bot(_answerText(answer)));
      });
    } catch (e) {
      appLog(_logName, '질문 실패: $e');
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _isLoading = false;
        _messages.add(ChatMessage.bot(
          e is ChatException ? e.message : '답변을 받지 못했어요. 잠시 후 다시 시도해 주세요.',
        ));
      });
    }
    _scrollToBottom();
  }

  /// 답변 본문에 근거 조항을 덧붙인다. 근거가 없으면 본문만 보여준다.
  String _answerText(ChatAnswer answer) {
    final labels = answer.sources
        .map((s) => s.label)
        .whereType<String>()
        .toSet()
        .take(3)
        .toList();
    if (labels.isEmpty) return answer.answer;
    return '${answer.answer}\n\n📄 근거: ${labels.join(', ')}';
  }

  Future<void> _handlePlaceSearch(PlaceCategory category) async {
    setState(() {
      _isLoading = true;
      _messages.add(ChatMessage.loading());
    });
    _scrollToBottom();

    try {
      final places = await _placeService.fetchNearbyPlaces(context, category);
      if (!mounted) return;

      setState(() {
        _messages.removeLast();
        _isLoading = false;
        if (places.isEmpty) {
          _messages.add(
            ChatMessage.bot('주변 ${category.formattedRadius} 내에 ${category.label}을(를) '
                '찾지 못했어요.\n다시 시도하거나 검색 범위를 넓혀보세요.'),
          );
        } else {
          _messages.add(
            ChatMessage.bot(
              '현재 위치 기준 ${category.label}이에요 ${category.emoji}',
              places: places,
            ),
          );
        }
      });
    } catch (e) {
      appLog(_logName, '${category.label} 검색 중 예외 발생: $e');
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _isLoading = false;
        _messages.add(
          ChatMessage.bot('${category.label} 정보를 불러오는 중 오류가 발생했어요.\n'
              '잠시 후 다시 시도해 주세요.'),
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
      appBar: _AppBar(tripName: _tripName),
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
    if (msg.contentType == MessageContentType.placeCards) {
      return _BotMessageWithCards(
        text: msg.text,
        time: msg.formattedTime,
        places: msg.places,
      );
    }
    return _BotMessage(text: msg.text, time: msg.formattedTime);
  }
}

// ── 앱바 ─────────────────────────────────────────────────────
class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  /// 어느 여행의 약관을 근거로 답하는지 보여준다. 아직 못 불러왔으면 null.
  final String? tripName;

  const _AppBar({this.tripName});

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
                  Text(
                    tripName ?? '지금 응답 가능',
                    style: const TextStyle(
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
            // 챗봇 답변은 **강조** 같은 마크다운이 섞여 오므로 굵게 반영해서 그린다
            child: InlineMarkdownText(
              text: text,
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

// ── 봇 메시지 + 장소 카드 ─────────────────────────────────────
class _BotMessageWithCards extends StatelessWidget {
  final String text;
  final String time;
  final List<PlaceResult> places;
  const _BotMessageWithCards({
    required this.text,
    required this.time,
    required this.places,
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
                    InlineMarkdownText(
                      text: text,
                      style: const TextStyle(
                        fontSize: 12.48,
                        color: Color(0xFF001635),
                        height: 1.5,
                      ),
                    ),
                    ...places.map((p) => PlaceCard(place: p)),
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
    '🏥 주변 병원',
    '🚓 주변 경찰서',
    '🏛 주변 대사관',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEF2FF), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _chips.map((chip) {
          final isEmergency = chip.contains('🚑');
          return GestureDetector(
            onTap: () => onChipTap(chip),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isEmergency
                      ? const Color(0xFFFFCDD2)
                      : const Color(0xFFBFD0FF),
                  width: 1,
                ),
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
                style: TextStyle(
                  fontSize: 13.52,
                  fontWeight: FontWeight.w500,
                  color: isEmergency
                      ? const Color(0xFFC0392B)
                      : const Color(0xFF1D3E8F),
                ),
              ),
            ),
          );
        }).toList(),
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
        // 입력창이 여러 줄로 늘어나도 전송 버튼은 아래에 붙어 있게 한다
        crossAxisAlignment: CrossAxisAlignment.end,
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
                // 글이 길어지면 줄바꿈되며 최대 5줄까지 위아래로 늘어나고,
                // 그 이상은 입력창 안에서 스크롤된다.
                minLines: 1,
                maxLines: 5,
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
