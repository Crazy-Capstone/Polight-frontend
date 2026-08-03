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

  ChatMessage.bot(this.text, {this.places = const [], this.userLat, this.userLng})
      : sender = MessageSender.bot,
        contentType = places.isNotEmpty
            ? MessageContentType.placeCards
            : MessageContentType.text,
        timestamp = DateTime.now();

  ChatMessage.user(this.text)
      : sender = MessageSender.user,
        contentType = MessageContentType.text,
        places = const [],
        userLat = null,
        userLng = null,
        timestamp = DateTime.now();

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
