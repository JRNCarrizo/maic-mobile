import '../../core/constants/maic_constants.dart';
import '../../core/endpoint/server_endpoint.dart';
import '../../core/errors/app_failure.dart';
import '../../core/ids/ids.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/actions/execute_unit_action.dart';
import '../../domain/ports/unit_action_port.dart';
import '../../domain/ports/unit_catalog_port.dart';
import '../../domain/units/unit.dart';
import '../../domain/units/video_channel.dart';
import '../api/dio_maic_client.dart';
import '../storage/local_settings.dart';
import 'channel_inventory_parser.dart';

class UnitCatalogRepository implements UnitCatalogPort {
  UnitCatalogRepository(this._client, this._settings, this._actions);

  final DioMaicClient _client;
  final LocalSettings _settings;
  final UnitActionPort _actions;

  @override
  Future<List<MaicUnit>> listViewerUnits(ServerEndpoint endpoint) async {
    if (_settings.readDataSource() == DataSourceKind.mock) {
      return _mockUnits();
    }

    final response = await _client.get<List<MaicUnit>>(
      endpoint,
      MaicPaths.viewerUnits,
      parseData: _parseUnits,
    );

    if (!response.result) {
      throw AppFailure(
        kind: FailureKind.functional,
        userMessage: response.error?.message ?? 'No se pudieron listar las unidades.',
        code: response.error?.code,
      );
    }

    final units = response.data ?? const <MaicUnit>[];
    AppLogger.info('Viewer units: ${units.length}');
    return units.where((unit) => unit.id.isNotEmpty).toList();
  }

  @override
  Future<List<VideoChannel>> refreshChannels({
    required ServerEndpoint endpoint,
    required String unitId,
    bool defaultCameraChannel = false,
  }) async {
    final result = await _actions.execute(
      endpoint: endpoint,
      request: ExecuteUnitActionRequest(
        unitId: unitId,
        moduleId: MaicModules.videoRecorder,
        actionKey: MaicActions.refreshDeviceInfo,
        correlationId: Ids.correlationId(),
      ),
    );
    return ChannelInventoryParser.parse(
      result.data,
      defaultCameraChannel: defaultCameraChannel,
    );
  }

  List<MaicUnit> _parseUnits(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => MaicUnit.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<MaicUnit> _mockUnits() {
    return const [
      MaicUnit(
        id: '11111111-2222-3333-4444-555555555555',
        displayName: 'NVR Principal',
        unitType: 'SecurityVideoRecorder',
        onlineStatus: 'online',
      ),
      MaicUnit(
        id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        displayName: 'Calle',
        unitType: 'SecurityCamera',
        onlineStatus: 'online',
      ),
      MaicUnit(
        id: '99999999-0000-0000-0000-000000000000',
        displayName: 'Taller',
        unitType: 'SecurityCamera',
        onlineStatus: 'offline',
      ),
    ];
  }
}
