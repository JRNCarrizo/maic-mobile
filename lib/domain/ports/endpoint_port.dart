import '../../core/endpoint/server_endpoint.dart';

abstract interface class EndpointPort {
  ServerEndpoint? read();
  Future<void> save(ServerEndpoint endpoint);
  Future<void> clear();
}
