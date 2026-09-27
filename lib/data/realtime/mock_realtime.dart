import '../../core/endpoint/server_endpoint.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/ports/realtime_port.dart';

class MockRealtime implements RealtimePort {
  void Function()? _onSessionClosed;

  @override
  Future<void> connect({
    required ServerEndpoint endpoint,
    required String sessionId,
    required void Function() onSessionClosed,
  }) async {
    _onSessionClosed = onSessionClosed;
    AppLogger.info('Realtime mock listo (SessionClosed simulable).');
  }

  @override
  Future<void> disconnect() async {
    _onSessionClosed = null;
  }

  @override
  void simulateSessionClosed() {
    AppLogger.info('SessionClosed mock');
    _onSessionClosed?.call();
  }
}
