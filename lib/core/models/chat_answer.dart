// 챗봇 API(/api/v1/trips/{tripId}/chat/messages) 응답 모델.
// 대화 이력은 서버가 보관하므로 프론트는 화면 표시용으로만 들고 있는다.

/// 답변의 근거가 된 약관 원문 조각.
class ChatSource {
  final String? chunkId;
  final String? documentId;
  final String? sectionTitle;
  final String? clausePath;
  final int? pageStart;
  final int? pageEnd;
  final String? quote;

  const ChatSource({
    this.chunkId,
    this.documentId,
    this.sectionTitle,
    this.clausePath,
    this.pageStart,
    this.pageEnd,
    this.quote,
  });

  factory ChatSource.fromJson(Map<String, dynamic> json) {
    return ChatSource(
      chunkId: json['chunkId'] as String?,
      documentId: json['documentId'] as String?,
      sectionTitle: json['sectionTitle'] as String?,
      clausePath: json['clausePath'] as String?,
      pageStart: (json['pageStart'] as num?)?.toInt(),
      pageEnd: (json['pageEnd'] as num?)?.toInt(),
      quote: json['quote'] as String?,
    );
  }

  /// 화면에 근거를 짧게 보여줄 때 쓸 라벨. 없으면 null.
  String? get label {
    final path = clausePath;
    if (path != null && path.isNotEmpty) return path;
    final title = sectionTitle;
    if (title != null && title.isNotEmpty) return title;
    return null;
  }
}

/// POST 응답: 질문에 대한 답변.
class ChatAnswer {
  final String? sessionId;
  final String? messageId;
  final String answer;

  /// 현재 백엔드는 항상 TEXT를 준다. 다른 값이 오면 그냥 본문만 보여준다.
  final String? responseType;
  final List<ChatSource> sources;

  const ChatAnswer({
    this.sessionId,
    this.messageId,
    required this.answer,
    this.responseType,
    this.sources = const [],
  });

  factory ChatAnswer.fromJson(Map<String, dynamic> json) {
    return ChatAnswer(
      sessionId: json['sessionId'] as String?,
      messageId: json['messageId'] as String?,
      answer: json['answer'] as String? ?? '',
      responseType: json['responseType'] as String?,
      sources: (json['sources'] as List<dynamic>? ?? [])
          .map((e) => ChatSource.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// GET 응답의 개별 메시지.
class ChatHistoryMessage {
  final String? messageId;

  /// USER / ASSISTANT / SYSTEM
  final String sender;
  final String content;
  final String? responseType;
  final List<ChatSource> sources;
  final DateTime? createdAt;

  const ChatHistoryMessage({
    this.messageId,
    required this.sender,
    required this.content,
    this.responseType,
    this.sources = const [],
    this.createdAt,
  });

  bool get isUser => sender == 'USER';

  factory ChatHistoryMessage.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'] as String?;
    return ChatHistoryMessage(
      messageId: json['messageId'] as String?,
      sender: json['sender'] as String? ?? 'ASSISTANT',
      content: json['content'] as String? ?? '',
      responseType: json['responseType'] as String?,
      sources: (json['sources'] as List<dynamic>? ?? [])
          .map((e) => ChatSource.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw),
    );
  }
}

/// GET 응답: 이 여행의 대화 이력. 대화가 없으면 sessionId가 null이고 messages가 빈 목록.
class ChatHistory {
  final String? sessionId;
  final List<ChatHistoryMessage> messages;

  const ChatHistory({this.sessionId, this.messages = const []});

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    return ChatHistory(
      sessionId: json['sessionId'] as String?,
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((e) => ChatHistoryMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
