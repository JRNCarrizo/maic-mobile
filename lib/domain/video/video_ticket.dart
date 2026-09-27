import '../../core/endpoint/server_endpoint.dart';
import 'stream_request.dart';

/// Ticket de relay. No se persiste ni se loguea completo.
class VideoTicket {
  const VideoTicket({
    required this.streamUrl,
    required this.leaseId,
    required this.channel,
    required this.subtype,
    this.transportMode = 'HttpMpegTs',
    this.expiresAtUtc,
  });

  final String streamUrl;
  final String leaseId;
  final int channel;
  final int subtype;
  final String transportMode;
  final DateTime? expiresAtUtc;
}

abstract interface class VideoTicketPort {
  Future<VideoTicket> open({
    required ServerEndpoint endpoint,
    required String unitId,
    required int channel,
    required int subtype,
  });

  Future<void> close({
    required ServerEndpoint endpoint,
    required String unitId,
    required String leaseId,
  });

  Future<List<StreamOpenResult>> openMany({
    required ServerEndpoint endpoint,
    required String unitId,
    required List<StreamRequest> streams,
  });
}
