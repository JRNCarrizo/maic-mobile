import '../../core/constants/maic_constants.dart';
import '../../core/endpoint/server_endpoint.dart';
import '../../core/ids/ids.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/actions/execute_unit_action.dart';
import '../../domain/ports/unit_action_port.dart';
import '../../domain/video/stream_request.dart';
import '../../domain/video/video_ticket.dart';
import 'open_many_parser.dart';
import 'relay_ticket_parser.dart';

class VideoTicketRepository implements VideoTicketPort {
  VideoTicketRepository(this._actions);

  final UnitActionPort _actions;

  @override
  Future<VideoTicket> open({
    required ServerEndpoint endpoint,
    required String unitId,
    required int channel,
    required int subtype,
  }) async {
    final result = await _actions.execute(
      endpoint: endpoint,
      request: ExecuteUnitActionRequest(
        unitId: unitId,
        moduleId: MaicModules.videoRecorder,
        actionKey: MaicActions.streamOpen,
        correlationId: Ids.correlationId(),
        parameters: {
          'channel': channel,
          'subtype': subtype,
          'target': MaicDefaults.videoTargetMobile,
        },
      ),
    );
    final ticket = RelayTicketParser.parse(
      result.data,
      channel: channel,
      subtype: subtype,
    );
    AppLogger.info(
      'Stream open unit=$unitId channel=$channel subtype=$subtype '
      'mode=${ticket.transportMode}',
    );
    return ticket;
  }

  @override
  Future<void> close({
    required ServerEndpoint endpoint,
    required String unitId,
    required String leaseId,
  }) async {
    if (leaseId.isEmpty) return;
    try {
      await _actions.execute(
        endpoint: endpoint,
        request: ExecuteUnitActionRequest(
          unitId: unitId,
          moduleId: MaicModules.videoRecorder,
          actionKey: MaicActions.streamClose,
          correlationId: Ids.correlationId(),
          parameters: {'relayLeaseId': leaseId},
        ),
      );
      AppLogger.info('Stream close unit=$unitId');
    } catch (error) {
      AppLogger.warn('Stream close best-effort: ${error.runtimeType}');
    }
  }

  @override
  Future<List<StreamOpenResult>> openMany({
    required ServerEndpoint endpoint,
    required String unitId,
    required List<StreamRequest> streams,
  }) async {
    final limited = streams.take(4).toList();
    final result = await _actions.execute(
      endpoint: endpoint,
      request: ExecuteUnitActionRequest(
        unitId: unitId,
        moduleId: MaicModules.videoRecorder,
        actionKey: MaicActions.streamOpenMany,
        correlationId: Ids.correlationId(),
        parameters: {
          'target': MaicDefaults.videoTargetMobile,
          'streams': [for (final item in limited) item.toJson()],
        },
      ),
    );
    final items = OpenManyParser.parse(result.data);
    AppLogger.info(
      'Stream openMany unit=$unitId requested=${limited.length} '
      'items=${items.length} ok=${items.where((e) => e.success).length}',
    );
    return items;
  }
}
