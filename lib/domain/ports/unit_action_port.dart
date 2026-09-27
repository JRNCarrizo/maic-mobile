import '../../core/endpoint/server_endpoint.dart';
import '../actions/execute_unit_action.dart';

abstract interface class UnitActionPort {
  Future<ExecuteUnitActionResult> execute({
    required ServerEndpoint endpoint,
    required ExecuteUnitActionRequest request,
  });
}
