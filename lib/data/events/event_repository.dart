import '../../core/constants/maic_constants.dart';
import '../../core/endpoint/server_endpoint.dart';
import '../../core/errors/app_failure.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/events/maic_event.dart';
import '../../domain/ports/event_port.dart';
import '../api/dio_maic_client.dart';
import '../storage/local_settings.dart';

class EventRepository implements EventPort {
  EventRepository(this._client, this._settings);

  final DioMaicClient _client;
  final LocalSettings _settings;

  @override
  Future<List<MaicEvent>> listEvents(
    ServerEndpoint endpoint, {
    int count = 100,
  }) async {
    if (_settings.readDataSource() == DataSourceKind.mock) {
      return _mockEvents();
    }
    final response = await _client.get<List<MaicEvent>>(
      endpoint,
      MaicPaths.events,
      query: {'count': '$count'},
      parseData: (raw) => _parseList(raw, MaicEvent.fromJson),
    );
    if (!response.result) {
      throw AppFailure(
        kind: FailureKind.functional,
        userMessage: response.error?.message ?? 'No se pudieron leer los eventos.',
        code: response.error?.code,
      );
    }
    AppLogger.info('Events: ${response.data?.length ?? 0}');
    return response.data ?? const [];
  }

  @override
  Future<List<MaicAlarm>> listAlarms(ServerEndpoint endpoint) async {
    if (_settings.readDataSource() == DataSourceKind.mock) {
      return List<MaicAlarm>.from(_mockAlarms);
    }
    final response = await _client.get<List<MaicAlarm>>(
      endpoint,
      MaicPaths.alarms,
      parseData: (raw) => _parseList(raw, MaicAlarm.fromJson),
    );
    if (!response.result) {
      throw AppFailure(
        kind: FailureKind.functional,
        userMessage: response.error?.message ?? 'No se pudieron leer las alarmas.',
        code: response.error?.code,
      );
    }
    AppLogger.info('Alarms: ${response.data?.length ?? 0}');
    return response.data ?? const [];
  }

  @override
  Future<void> ackAlarm(ServerEndpoint endpoint, String alarmId) async {
    if (_settings.readDataSource() == DataSourceKind.mock) {
      AppLogger.info('Alarm ack mock id=$alarmId');
      return;
    }
    final response = await _client.post<void>(
      endpoint,
      '${MaicPaths.alarms}/$alarmId/ack',
    );
    if (!response.result) {
      throw AppFailure(
        kind: FailureKind.functional,
        userMessage: response.error?.message ?? 'No se pudo reconocer la alarma.',
        code: response.error?.code,
      );
    }
    AppLogger.info('Alarm ack id=$alarmId');
  }

  List<T> _parseList<T>(
    Object? raw,
    T Function(Map<String, dynamic> json) parse,
  ) {
    if (raw is! List) return <T>[];
    return raw
        .whereType<Map>()
        .map((item) => parse(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<MaicEvent> _mockEvents() {
    final now = DateTime.now().toUtc();
    return [
      MaicEvent(
        id: 'evt-1',
        timestampUtc: now.subtract(const Duration(minutes: 3)),
        source: 'MAIC.Module.VideoRecorder',
        type: 'LineCrossing',
        severity: 'info',
        message: 'Cruce de línea detectado',
        unitId: '11111111-2222-3333-4444-555555555555',
      ),
      MaicEvent(
        id: 'evt-2',
        timestampUtc: now.subtract(const Duration(minutes: 20)),
        source: 'MAIC.Module.VideoRecorder',
        type: 'DeviceUnavailable',
        severity: 'warning',
        message: 'Taller quedó sin conexión',
        unitId: '99999999-0000-0000-0000-000000000000',
      ),
    ];
  }

  static final _mockAlarms = [
    MaicAlarm(
      id: 'alm-1',
      moduleId: 'MAIC.Module.VideoRecorder',
      unitId: '11111111-2222-3333-4444-555555555555',
      alarmType: 'LineCrossing',
      severity: 'warning',
      message: 'Cruce de línea en Entrada',
      state: 'active',
      raisedAtUtc: DateTime.now().toUtc().subtract(const Duration(minutes: 2)),
    ),
    MaicAlarm(
      id: 'alm-2',
      moduleId: 'MAIC.Module.VideoRecorder',
      alarmType: 'DeviceUnavailable',
      severity: 'info',
      message: 'Taller fue reconocido antes',
      state: 'acknowledged',
      raisedAtUtc: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      acknowledgedAtUtc: DateTime.now().toUtc().subtract(
        const Duration(minutes: 40),
      ),
      acknowledgedBy: 'operador',
    ),
  ];
}
