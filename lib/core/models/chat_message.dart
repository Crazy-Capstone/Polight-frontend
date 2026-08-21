import 'place_result.dart';

enum MessageSender { bot, user }

enum MessageContentType { text, placeCards, loading }

class ChatMessage {
  final MessageSender sender;
  final MessageContentType contentType;
  final String text;
  final List<PlaceResult> places;
  final DateTime timestamp;

  final double? userLat;
  final double? userLng;

  /// 서버에서 불러온 지난 대화는 그때의 시각을 그대로 쓰도록 [at]을 넘긴다.
  ChatMessage.bot(
    this.text, {
    this.places = const [],
    this.userLat,
    this.userLng,
    DateTime? at,
  })  : sender = MessageSender.bot,
        contentType = places.isNotEmpty
            ? MessageContentType.placeCards
            : MessageContentType.text,
        timestamp = at ?? DateTime.now();

  ChatMessage.user(this.text, {DateTime? at})
      : sender = MessageSender.user,
        contentType = MessageContentType.text,
        places = const [],
        userLat = null,
        userLng = null,
        timestamp = at ?? DateTime.now();

  ChatMessage.loading()
      : sender = MessageSender.bot,
        contentType = MessageContentType.loading,
        text = '',
        places = const [],
        userLat = null,
        userLng = null,
        timestamp = DateTime.now();

  String get formattedTime {
    final h = timestamp.hour;
    final m = timestamp.minute.toString().padLeft(2, '0');
    final period = h < 12 ? '오전' : '오후';
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$period $hour:$m';
  }
}
