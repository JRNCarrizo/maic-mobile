import '../../core/endpoint/server_endpoint.dart';
import '../auth/user_session.dart';

abstract interface class AuthPort {
  Future<LoginResult> login({
    required ServerEndpoint endpoint,
    required String username,
    required String password,
    required String machineName,
  });

  Future<void> heartbeat(ServerEndpoint endpoint, String sessionId);

  /// Best-effort. No debe fallar el logout local si la red no responde.
  Future<void> release(ServerEndpoint endpoint, String sessionId);
}
