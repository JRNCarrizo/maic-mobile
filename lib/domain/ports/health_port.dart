import '../../core/endpoint/server_endpoint.dart';

class HealthReport {
  const HealthReport({required this.available, this.detail = ''});

  final bool available;
  final String detail;
}

abstract interface class HealthPort {
  Future<HealthReport> probe(ServerEndpoint endpoint);
}
