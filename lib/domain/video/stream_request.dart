import 'video_ticket.dart';

class StreamRequest {
  const StreamRequest({
    required this.key,
    required this.channel,
    this.subtype = 1,
  });

  final String key;
  final int channel;
  final int subtype;

  Map<String, dynamic> toJson() => {
    'key': key,
    'channel': channel,
    'subtype': subtype,
  };
}

class StreamOpenResult {
  const StreamOpenResult({
    required this.key,
    required this.channel,
    required this.subtype,
    required this.success,
    this.ticket,
    this.userMessage,
  });

  final String key;
  final int channel;
  final int subtype;
  final bool success;
  final VideoTicket? ticket;
  final String? userMessage;
}
