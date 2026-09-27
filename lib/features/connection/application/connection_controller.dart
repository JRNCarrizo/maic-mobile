import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/endpoint/server_endpoint.dart';
import '../../../core/errors/app_failure.dart';
import '../../../data/storage/local_settings.dart';
import '../../../domain/ports/health_port.dart';

class ConnectionViewState {
  const ConnectionViewState({
    required this.kind,
    this.endpoint,
    this.busy = false,
    this.message,
    this.ready = false,
  });

  final DataSourceKind kind;
  final ServerEndpoint? endpoint;
  final bool busy;
  final String? message;
  final bool ready;

  ConnectionViewState copyWith({
    DataSourceKind? kind,
    ServerEndpoint? endpoint,
    bool? busy,
    String? message,
    bool clearMessage = false,
    bool? ready,
  }) {
    return ConnectionViewState(
      kind: kind ?? this.kind,
      endpoint: endpoint ?? this.endpoint,
      busy: busy ?? this.busy,
      message: clearMessage ? null : (message ?? this.message),
      ready: ready ?? this.ready,
    );
  }
}

class ConnectionController extends Notifier<ConnectionViewState> {
  @override
  ConnectionViewState build() {
    final settings = ref.read(localSettingsProvider);
    return ConnectionViewState(
      kind: settings.readDataSource(),
      endpoint: settings.read(),
    );
  }

  Future<void> useMock() async {
    final settings = ref.read(localSettingsProvider);
    final endpoint = ServerEndpoint.parse('demo.maic.local');
    await settings.saveDataSource(DataSourceKind.mock);
    await settings.save(endpoint);
    state = ConnectionViewState(
      kind: DataSourceKind.mock,
      endpoint: endpoint,
      ready: true,
      message: 'Modo demo listo. Podés entrar sin servidor.',
    );
  }

  Future<bool> saveHost(String rawHost) async {
    try {
      final endpoint = ServerEndpoint.parse(rawHost);
      final settings = ref.read(localSettingsProvider);
      await settings.saveDataSource(DataSourceKind.remote);
      await settings.save(endpoint);
      await settings.rememberHost(endpoint);
      state = ConnectionViewState(
        kind: DataSourceKind.remote,
        endpoint: endpoint,
        message: 'Servidor guardado: ${endpoint.display}',
      );
      return true;
    } on AppFailure catch (failure) {
      state = state.copyWith(message: failure.userMessage);
      return false;
    } catch (_) {
      state = state.copyWith(message: 'No se pudo guardar el servidor.');
      return false;
    }
  }

  Future<bool> probe(String rawHost) async {
    state = state.copyWith(busy: true, clearMessage: true, ready: false);
    try {
      final endpoint = ServerEndpoint.parse(rawHost);
      final settings = ref.read(localSettingsProvider);
      final HealthReport report = await ref.read(healthPortProvider).probe(
        endpoint,
      );
      if (!report.available) {
        throw const AppFailure(
          kind: FailureKind.transport,
          userMessage: 'El servidor no respondió como MAIC.',
        );
      }
      await settings.saveDataSource(DataSourceKind.remote);
      await settings.save(endpoint);
      await settings.rememberHost(endpoint);
      state = ConnectionViewState(
        kind: DataSourceKind.remote,
        endpoint: endpoint,
        ready: true,
        message: report.detail,
      );
      return true;
    } on AppFailure catch (failure) {
      state = state.copyWith(busy: false, message: failure.userMessage);
      return false;
    } catch (_) {
      state = state.copyWith(
        busy: false,
        message: 'No se pudo comprobar el servidor.',
      );
      return false;
    }
  }
}

final connectionControllerProvider =
    NotifierProvider<ConnectionController, ConnectionViewState>(
      ConnectionController.new,
    );
