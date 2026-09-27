import '../../core/errors/app_failure.dart';
import '../../domain/video/video_ticket.dart';

abstract final class RelayTicketParser {
  static VideoTicket parse(
    Map<String, String> data, {
    required int channel,
    required int subtype,
  }) {
    final url = data['relay.streamUrl'] ?? '';
    if (url.trim().isEmpty) {
      throw const AppFailure(
        kind: FailureKind.invalidResponse,
        userMessage: 'El servidor no entregó una URL de video.',
      );
    }

    return VideoTicket(
      streamUrl: url.trim(),
      leaseId: data['relay.leaseId'] ?? '',
      channel: int.tryParse(data['relay.channel'] ?? '') ?? channel,
      subtype: int.tryParse(data['relay.subtype'] ?? '') ?? subtype,
      transportMode: data['relay.transportMode'] ?? 'HttpMpegTs',
      expiresAtUtc: DateTime.tryParse(data['relay.expiresAtUtc'] ?? ''),
    );
  }
}
