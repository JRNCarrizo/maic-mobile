import 'package:signalr_netcore/signalr_client.dart';

import '../../core/constants/maic_constants.dart';
import '../../core/endpoint/server_endpoint.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/ports/realtime_port.dart';

class SignalRRealtime implements RealtimePort {
  HubConnection? _hub;
  void Function()? _onSessionClosed;

  @override
  Future<void> connect({
    required ServerEndpoint endpoint,
    required String sessionId,
    required void Function() onSessionClosed,
  }) async {
    await disconnect();
    _onSessionClosed = onSessionClosed;
    final url = endpoint.baseUri.replace(
      path: MaicPaths.platformHub,
      queryParameters: {'sessionId': sessionId},
    );
    final hub = HubConnectionBuilder()
        .withUrl(url.toString())
        .withAutomaticReconnect()
        .build();
    hub.on('SessionClosed', (arguments) {
      AppLogger.info('SessionClosed');
      _onSessionClosed?.call();
    });
    _hub = hub;
    try {
      await hub.start();
      AppLogger.info('Realtime conectado');
    } catch (error) {
      AppLogger.warn('Realtime no disponible: ${error.runtimeType}');
    }
  }

  @override
  Future<void> disconnect() async {
    final hub = _hub;
    _hub = null;
    _onSessionClosed = null;
    if (hub == null) return;
    try {
      await hub.stop();
    } catch (error) {
      AppLogger.warn('Realtime stop: ${error.runtimeType}');
    }
  }

  @override
  void simulateSessionClosed() {
    _onSessionClosed?.call();
  }
}
