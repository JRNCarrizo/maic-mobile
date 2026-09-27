import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/maic_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/ids/ids.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/auth/user_session.dart';
import '../../connection/application/connection_controller.dart';

class SessionViewState {
  const SessionViewState({
    this.busy = false,
    this.message,
    this.lastHeartbeatUtc,
    this.heartbeatOk = true,
  });

  final bool busy;
  final String? message;
  final DateTime? lastHeartbeatUtc;
  final bool heartbeatOk;
}

class SessionController extends Notifier<SessionViewState> {
  Timer? _heartbeat;

  @override
  SessionViewState build() {
    ref.onDispose(_stopHeartbeat);
    return const SessionViewState();
  }

  UserSession? get session => ref.read(sessionStoreProvider).session;

  Future<bool> login(String username, String password) async {
    final user = username.trim();
    if (user.isEmpty || password.isEmpty) {
      state = const SessionViewState(
        message: 'Ingresá usuario y contraseña.',
      );
      return false;
    }

    final endpoint = ref.read(connectionControllerProvider).endpoint ??
        ref.read(localSettingsProvider).read();
    if (endpoint == null) {
      state = const SessionViewState(
        message: 'Primero configurá el servidor MAIC.',
      );
      return false;
    }

    state = const SessionViewState(busy: true);
    try {
      final machineName = Ids.machineName(
        ref.read(localSettingsProvider).installationId(),
      );
      final result = await ref.read(authPortProvider).login(
        endpoint: endpoint,
        username: user,
        password: password,
        machineName: machineName,
      );
      ref.read(sessionStoreProvider).replace(result.session);
      _startHeartbeat();
      await ref.read(realtimePortProvider).connect(
        endpoint: endpoint,
        sessionId: result.session.sessionId,
        onSessionClosed: handleSessionClosed,
      );
      state = SessionViewState(
        lastHeartbeatUtc: DateTime.now().toUtc(),
        message: result.licenseStatusText,
      );
      return true;
    } on AppFailure catch (failure) {
      state = SessionViewState(message: failure.userMessage);
      return false;
    } catch (_) {
      state = const SessionViewState(
        message: 'No se pudo iniciar sesión.',
      );
      return false;
    }
  }

  void handleSessionClosed() {
    AppLogger.info('Sesión cerrada por el servidor');
    _stopHeartbeat();
    unawaited(ref.read(realtimePortProvider).disconnect());
    ref.read(sessionStoreProvider).clear();
    state = const SessionViewState(
      message: 'La sesión fue cerrada por el servidor.',
    );
  }

  Future<void> logout() async {
    final current = ref.read(sessionStoreProvider).session;
    final endpoint = ref.read(localSettingsProvider).read();
    _stopHeartbeat();
    await ref.read(realtimePortProvider).disconnect();
    if (current != null && endpoint != null) {
      await ref.read(authPortProvider).release(endpoint, current.sessionId);
    }
    ref.read(sessionStoreProvider).clear();
    state = const SessionViewState();
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeat = Timer.periodic(MaicDefaults.heartbeatInterval, (_) {
      unawaited(_beat());
    });
  }

  Future<void> _beat() async {
    final current = ref.read(sessionStoreProvider).session;
    final endpoint = ref.read(localSettingsProvider).read();
    if (current == null || endpoint == null) return;
    try {
      await ref.read(authPortProvider).heartbeat(endpoint, current.sessionId);
      state = SessionViewState(
        lastHeartbeatUtc: DateTime.now().toUtc(),
        heartbeatOk: true,
      );
    } on AppFailure catch (failure) {
      if (failure.kind == FailureKind.unauthorized) {
        AppLogger.warn('Heartbeat: sesión inválida, se cierra local.');
        _stopHeartbeat();
        ref.read(sessionStoreProvider).clear();
        state = SessionViewState(message: failure.userMessage);
        return;
      }
      AppLogger.warn('Heartbeat transitorio: ${failure.kind}');
      state = SessionViewState(
        lastHeartbeatUtc: state.lastHeartbeatUtc,
        heartbeatOk: false,
        message: 'Sin red. La sesión se mantiene.',
      );
    }
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionViewState>(
      SessionController.new,
    );
