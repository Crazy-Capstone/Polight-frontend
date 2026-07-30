import 'hospital_result.dart';

enum MessageSender { bot, user }

enum MessageContentType { text, hospitalCards, loading }

class ChatMessage {
  final MessageSender sender;
  final MessageContentType contentType;
  final String text;
  final List<HospitalResult> hospitals;
  final DateTime timestamp;

  final double? userLat;
  final double? userLng;

  ChatMessage.bot(this.text, {this.hospitals = const [], this.userLat, this.userLng})
      : sender = MessageSender.bot,
        contentType = hospitals.isNotEmpty
            ? MessageContentType.hospitalCards
            : MessageContentType.text,
        timestamp = DateTime.now();

  ChatMessage.user(this.text)
      : sender = MessageSender.user,
        contentType = MessageContentType.text,
        hospitals = const [],
        userLat = null,
        userLng = null,
        timestamp = DateTime.now();

  ChatMessage.loading()
      : sender = MessageSender.bot,
        contentType = MessageContentType.loading,
        text = '',
        hospitals = const [],
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
