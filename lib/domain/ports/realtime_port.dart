import '../../core/endpoint/server_endpoint.dart';

abstract interface class RealtimePort {
  Future<void> connect({
    required ServerEndpoint endpoint,
    required String sessionId,
    required void Function() onSessionClosed,
  });

  Future<void> disconnect();

  /// Solo demo: dispara el mismo callback que SessionClosed.
  void simulateSessionClosed();
}
