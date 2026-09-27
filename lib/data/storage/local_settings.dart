import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/endpoint/server_endpoint.dart';
import '../../core/ids/ids.dart';
import '../../domain/ports/endpoint_port.dart';

enum DataSourceKind { mock, remote }

class LocalSettings implements EndpointPort {
  LocalSettings(this._prefs);

  final SharedPreferences _prefs;

  static const _endpointKey = 'maic.endpoint';
  static const _sourceKey = 'maic.dataSource';
  static const _installKey = 'maic.installationId';
  static const _hostsKey = 'maic.savedHosts';

  @override
  ServerEndpoint? read() {
    final raw = _prefs.getString(_endpointKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return ServerEndpoint.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(ServerEndpoint endpoint) {
    return _prefs.setString(_endpointKey, jsonEncode(endpoint.toJson()));
  }

  @override
  Future<void> clear() => _prefs.remove(_endpointKey);

  DataSourceKind readDataSource() {
    final raw = _prefs.getString(_sourceKey);
    return raw == DataSourceKind.remote.name
        ? DataSourceKind.remote
        : DataSourceKind.mock;
  }

  Future<void> saveDataSource(DataSourceKind kind) {
    return _prefs.setString(_sourceKey, kind.name);
  }

  List<ServerEndpoint> readSavedHosts() {
    final raw = _prefs.getString(_hostsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((item) => ServerEndpoint.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> rememberHost(ServerEndpoint endpoint) async {
    if (endpoint.host == 'demo.maic.local') return;
    final next = [
      endpoint,
      ...readSavedHosts().where((item) => item != endpoint),
    ];
    await _prefs.setString(
      _hostsKey,
      jsonEncode([for (final item in next.take(12)) item.toJson()]),
    );
  }

  String installationId() {
    final existing = _prefs.getString(_installKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = Ids.newInstallationId();
    _prefs.setString(_installKey, created);
    return created;
  }

  String? raw(String key) => _prefs.getString(key);

  Future<void> writeRaw(String key, String value) => _prefs.setString(key, value);
}
