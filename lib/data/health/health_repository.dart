import '../../core/constants/maic_constants.dart';
import '../../core/endpoint/server_endpoint.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/ports/health_port.dart';
import '../api/dio_maic_client.dart';

class HealthRepository implements HealthPort {
  HealthRepository(this._client);

  final DioMaicClient _client;

  @override
  Future<HealthReport> probe(ServerEndpoint endpoint) async {
    await _client.ping(endpoint, MaicPaths.health);
    AppLogger.info('Health OK ${endpoint.host}:${endpoint.port}');
    return const HealthReport(
      available: true,
      detail: 'MAIC Server disponible.',
    );
  }
}
