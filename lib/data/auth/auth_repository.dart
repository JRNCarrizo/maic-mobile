import '../../core/constants/maic_constants.dart';
import '../../core/endpoint/server_endpoint.dart';
import '../../core/errors/app_failure.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/auth/user_session.dart';
import '../../domain/ports/auth_port.dart';
import '../api/dio_maic_client.dart';
import '../storage/local_settings.dart';

class AuthRepository implements AuthPort {
  AuthRepository(this._client, this._settings);

  final DioMaicClient _client;
  final LocalSettings _settings;

  @override
  Future<LoginResult> login({
    required ServerEndpoint endpoint,
    required String username,
    required String password,
    required String machineName,
  }) async {
    if (_settings.readDataSource() == DataSourceKind.mock) {
      return _mockLogin(username);
    }

    final response = await _client.post<Map<String, dynamic>>(
      endpoint,
      MaicPaths.login,
      withSession: false,
      body: {
        'username': username,
        'password': password,
        'machineName': machineName,
        'domain': '',
        'useIntegratedAuthentication': false,
      },
      parseData: (raw) =>
          raw is Map<String, dynamic> ? raw : <String, dynamic>{},
    );

    if (!response.result) {
      throw AppFailure(
        kind: FailureKind.unauthorized,
        userMessage: response.error?.message ?? 'No se pudo iniciar sesión.',
        code: response.error?.code,
      );
    }

    final data = response.data;
    if (data == null || data['success'] != true || data['session'] is! Map) {
      throw const AppFailure(
        kind: FailureKind.unauthorized,
        userMessage: 'El servidor no devolvió una sesión válida.',
      );
    }

    final session = UserSession.fromJson(
      data['session'] as Map<String, dynamic>,
    );
    if (session.sessionId.isEmpty) {
      throw const AppFailure(
        kind: FailureKind.unauthorized,
        userMessage: 'El servidor no devolvió una sesión válida.',
      );
    }

    AppLogger.info('Login OK usuario=${session.loginName} rol=${session.role}');
    return LoginResult(
      session: session,
      licenseStatusText: data['licenseStatusText'] as String? ?? 'OK',
    );
  }

  @override
  Future<void> heartbeat(ServerEndpoint endpoint, String sessionId) async {
    if (_settings.readDataSource() == DataSourceKind.mock) return;
    final response = await _client.post<void>(
      endpoint,
      MaicPaths.heartbeat,
      parseData: null,
    );
    if (!response.result) {
      throw AppFailure(
        kind: FailureKind.unauthorized,
        userMessage: response.error?.message ?? 'La sesión ya no es válida.',
        code: response.error?.code,
      );
    }
  }

  @override
  Future<void> release(ServerEndpoint endpoint, String sessionId) async {
    if (_settings.readDataSource() == DataSourceKind.mock) return;
    try {
      await _client.post<void>(endpoint, MaicPaths.release, parseData: null);
    } catch (error) {
      AppLogger.warn('Release best-effort falló: ${error.runtimeType}');
    }
  }

  LoginResult _mockLogin(String username) {
    if (username.trim().isEmpty) {
      throw const AppFailure(
        kind: FailureKind.validation,
        userMessage: 'Ingresá usuario y contraseña.',
      );
    }
    AppLogger.info('Login mock usuario=${username.trim()}');
    final now = DateTime.now().toUtc();
    return LoginResult(
      session: UserSession(
        sessionId: 'S-MOCK-NOT-A-REAL-SESSION',
        displayName: username.trim(),
        loginName: username.trim(),
        role: 1,
        permissions: const ['viewer.read'],
        issuedAtUtc: now,
        expiresAtUtc: now.add(const Duration(hours: 8)),
      ),
      licenseStatusText: 'OK (demo)',
    );
  }
}
