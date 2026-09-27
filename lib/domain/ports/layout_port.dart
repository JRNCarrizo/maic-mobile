import '../../core/endpoint/server_endpoint.dart';
import '../layouts/last_view.dart';

abstract interface class LayoutPort {
  Future<LastView?> readLast(ServerEndpoint endpoint);

  Future<void> saveLast(ServerEndpoint endpoint, LastView view);
}
