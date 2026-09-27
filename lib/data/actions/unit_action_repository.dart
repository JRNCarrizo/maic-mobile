import '../../core/constants/maic_constants.dart';
import '../../core/endpoint/server_endpoint.dart';
import '../../core/errors/app_failure.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/actions/execute_unit_action.dart';
import '../../domain/ports/unit_action_port.dart';
import '../api/dio_maic_client.dart';
import '../snapshot/demo_jpeg.dart';
import '../storage/local_settings.dart';

class UnitActionRepository implements UnitActionPort {
  UnitActionRepository(this._client, this._settings);

  final DioMaicClient _client;
  final LocalSettings _settings;

  @override
  Future<ExecuteUnitActionResult> execute({
    required ServerEndpoint endpoint,
    required ExecuteUnitActionRequest request,
  }) async {
    if (_settings.readDataSource() == DataSourceKind.mock) {
      return _mock(request);
    }

    final response = await _client.post<Map<String, dynamic>>(
      endpoint,
      MaicPaths.unitActions,
      body: request.toJson(),
      parseData: (raw) =>
          raw is Map<String, dynamic> ? raw : <String, dynamic>{},
    );

    if (!response.result) {
      throw AppFailure(
        kind: FailureKind.functional,
        userMessage: response.error?.message ?? 'No se pudo ejecutar la acción.',
        code: response.error?.code,
      );
    }

    final payload = response.data;
    if (payload == null) {
      throw const AppFailure(
        kind: FailureKind.invalidResponse,
        userMessage: 'El servidor no devolvió el resultado de la acción.',
      );
    }

    final result = ExecuteUnitActionResult.fromJson(payload);
    AppLogger.info(
      'Action ${request.actionKey} unit=${request.unitId} '
      'corr=${request.correlationId} success=${result.success} '
      'code=${result.code} kind=${result.errorKind}',
    );

    if (!result.success) {
      throw AppFailure(
        kind: FailureKind.functional,
        userMessage: result.userMessage.isEmpty
            ? 'La acción no se completó.'
            : result.userMessage,
        code: result.code,
        isRetryable: result.isRetryable,
      );
    }
    return result;
  }

  ExecuteUnitActionResult _ok(Map<String, String> data) {
    return ExecuteUnitActionResult(
      success: true,
      code: 'OK',
      userMessage: '',
      isRetryable: false,
      data: data,
    );
  }

  ExecuteUnitActionResult _mock(ExecuteUnitActionRequest request) {
    switch (request.actionKey) {
      case MaicActions.refreshDeviceInfo:
        return _ok(_mockInventory(request.unitId));
      case MaicActions.streamOpen:
        return _ok(_mockStreamOpen(request));
      case MaicActions.streamClose:
        return _ok(const {'relay.closed': 'true'});
      case MaicActions.streamOpenMany:
        return _ok(_mockStreamOpenMany(request));
      case MaicActions.snapshotCapture:
        return _ok(_mockSnapshot(request));
      case MaicActions.pulseRelay:
        return ExecuteUnitActionResult(
          success: true,
          code: 'OK',
          userMessage: 'Pulso enviado (demo).',
          isRetryable: false,
          data: {
            'outputIndex': request.parameters['outputIndex']?.toString() ?? '0',
            'enabled': 'true',
          },
        );
      default:
        throw const AppFailure(
          kind: FailureKind.functional,
          userMessage: 'Acción no disponible en modo demo.',
          code: 'NotSupported',
        );
    }
  }

  Map<String, String> _mockInventory(String unitId) {
    return switch (unitId) {
      '11111111-2222-3333-4444-555555555555' => const {
        'videoChannels': '2',
        'inventory.channel.0.requestChannel': '1',
        'inventory.channel.0.name': 'Entrada',
        'inventory.channel.0.state': 'online',
        'inventory.channel.1.requestChannel': '2',
        'inventory.channel.1.name': 'Depósito',
        'inventory.channel.1.state': 'online',
      },
      'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' => const {
        'videoChannels': '1',
        'inventory.channel.0.requestChannel': '1',
        'inventory.channel.0.name': 'Calle',
        'inventory.channel.0.state': 'online',
      },
      _ => const {},
    };
  }

  Map<String, String> _mockStreamOpen(ExecuteUnitActionRequest request) {
    final channel = request.parameters['channel']?.toString() ?? '1';
    final subtype = request.parameters['subtype']?.toString() ?? '1';
    final expires = DateTime.now()
        .toUtc()
        .add(const Duration(minutes: 5))
        .toIso8601String();
    return {
      'relay.protocol': 'DEMO_FILE',
      'relay.transportMode': 'HttpMpegTs',
      'relay.outputTarget': 'mobile',
      'relay.streamUrl': MaicDefaults.demoStreamUrl,
      'relay.leaseId': 'L-MOCK-$channel-$subtype',
      'relay.channel': channel,
      'relay.subtype': subtype,
      'relay.expiresAtUtc': expires,
    };
  }

  Map<String, String> _mockStreamOpenMany(ExecuteUnitActionRequest request) {
    final raw = request.parameters['streams'];
    final streams = raw is List ? raw : const [];
    final data = <String, String>{
      'stream.count': '${streams.length}',
    };
    var ok = 0;
    for (var i = 0; i < streams.length && i < 4; i++) {
      final item = streams[i];
      final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
      final key = map['key']?.toString() ?? 'stream-$i';
      final channel = map['channel']?.toString() ?? '${i + 1}';
      final subtype = map['subtype']?.toString() ?? '1';
      final fail = channel == '99';
      data['stream.$i.key'] = key;
      data['stream.$i.channel'] = channel;
      data['stream.$i.subtype'] = subtype;
      if (fail) {
        data['stream.$i.success'] = 'false';
        data['stream.$i.userMessage'] = 'Canal no disponible (demo).';
        data['stream.$i.retryable'] = 'true';
        continue;
      }
      ok += 1;
      data['stream.$i.success'] = 'true';
      data['stream.$i.relay.streamUrl'] = MaicDefaults.demoStreamUrl;
      data['stream.$i.relay.leaseId'] = 'L-MOCK-MANY-$channel';
      data['stream.$i.relay.transportMode'] = 'HttpMpegTs';
      data['stream.$i.relay.channel'] = channel;
      data['stream.$i.relay.subtype'] = subtype;
    }
    data['stream.successCount'] = '$ok';
    return data;
  }

  Map<String, String> _mockSnapshot(ExecuteUnitActionRequest request) {
    final channel = request.parameters['channel']?.toString() ?? '1';
    return {
      'snapshot.base64': demoJpegBase64,
      'snapshot.extension': '.jpg',
      'snapshot.contentType': 'image/jpeg',
      'snapshot.channel': channel,
      'snapshot.timestampUtc': DateTime.now().toUtc().toIso8601String(),
      'snapshot.transport': 'demo',
    };
  }
}
