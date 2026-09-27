import '../../core/constants/maic_constants.dart';
import '../../core/endpoint/server_endpoint.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/layouts/last_view.dart';
import '../../domain/ports/layout_port.dart';
import '../api/dio_maic_client.dart';
import '../storage/local_settings.dart';

class LayoutRepository implements LayoutPort {
  LayoutRepository(this._client, this._settings);

  final DioMaicClient _client;
  final LocalSettings _settings;

  static const _localKey = 'maic.layout.last';

  @override
  Future<LastView?> readLast(ServerEndpoint endpoint) async {
    if (_settings.readDataSource() == DataSourceKind.mock) {
      return LastView.tryParse(_settings.raw(_localKey));
    }
    try {
      final response = await _client.post<List<dynamic>>(
        endpoint,
        MaicPaths.layoutList,
        body: {
          'moduleId': MaicModules.viewer,
          'scopeType': 'User',
          'layoutKind': MaicDefaults.layoutKindLast,
        },
        parseData: (raw) => raw is List ? raw : const [],
      );
      if (!response.result) return null;
      for (final item in response.data ?? const []) {
        if (item is! Map) continue;
        final json = item['layoutJson']?.toString();
        final view = LastView.tryParse(json);
        if (view != null) return view;
      }
    } catch (error) {
      AppLogger.warn('Layout list: ${error.runtimeType}');
    }
    return null;
  }

  @override
  Future<void> saveLast(ServerEndpoint endpoint, LastView view) async {
    if (_settings.readDataSource() == DataSourceKind.mock) {
      await _settings.writeRaw(_localKey, view.toJsonString());
      return;
    }
    try {
      await _client.post<void>(
        endpoint,
        MaicPaths.layoutSave,
        body: {
          'moduleId': MaicModules.viewer,
          'viewKey': MaicDefaults.layoutViewKeyLast,
          'displayName': 'Última vista',
          'scopeType': 'User',
          'layoutKind': MaicDefaults.layoutKindLast,
          'layoutJson': view.toJsonString(),
          'isDefault': false,
          'lastUsedAtUtc': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (error) {
      AppLogger.warn('Layout save: ${error.runtimeType}');
    }
  }
}
