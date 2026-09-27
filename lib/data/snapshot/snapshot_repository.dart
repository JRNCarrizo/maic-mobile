import '../../core/constants/maic_constants.dart';
import '../../core/endpoint/server_endpoint.dart';
import '../../core/ids/ids.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/actions/execute_unit_action.dart';
import '../../domain/ports/unit_action_port.dart';
import '../../domain/snapshot/snapshot_image.dart';
import 'snapshot_parser.dart';

class SnapshotRepository {
  SnapshotRepository(this._actions);

  final UnitActionPort _actions;

  Future<SnapshotImage> capture({
    required ServerEndpoint endpoint,
    required String unitId,
    required int channel,
    int subtype = 1,
  }) async {
    final result = await _actions.execute(
      endpoint: endpoint,
      request: ExecuteUnitActionRequest(
        unitId: unitId,
        moduleId: MaicModules.videoRecorder,
        actionKey: MaicActions.snapshotCapture,
        correlationId: Ids.correlationId(),
        parameters: {'channel': channel, 'subtype': subtype},
      ),
    );
    final image = SnapshotParser.parse(result.data, channel: channel);
    AppLogger.info(
      'Snapshot unit=$unitId channel=$channel bytes=${image.bytes.length}',
    );
    return image;
  }
}
