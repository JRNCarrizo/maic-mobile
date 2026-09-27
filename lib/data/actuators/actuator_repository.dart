import '../../core/constants/maic_constants.dart';
import '../../core/endpoint/server_endpoint.dart';
import '../../core/ids/ids.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/actions/execute_unit_action.dart';
import '../../domain/ports/unit_action_port.dart';

class ActuatorRepository {
  ActuatorRepository(this._actions);

  final UnitActionPort _actions;

  Future<String> pulseRelay({
    required ServerEndpoint endpoint,
    required String unitId,
    int outputIndex = 0,
    int pulseMs = 2000,
  }) async {
    final result = await _actions.execute(
      endpoint: endpoint,
      request: ExecuteUnitActionRequest(
        unitId: unitId,
        moduleId: MaicModules.videoRecorder,
        actionKey: MaicActions.pulseRelay,
        correlationId: Ids.correlationId(),
        parameters: {'outputIndex': outputIndex, 'pulseMs': pulseMs},
      ),
    );
    AppLogger.info(
      'Pulse relay unit=$unitId output=$outputIndex code=${result.code}',
    );
    return result.userMessage.isEmpty
        ? 'Pulso enviado al relé ${outputIndex + 1}.'
        : result.userMessage;
  }
}
