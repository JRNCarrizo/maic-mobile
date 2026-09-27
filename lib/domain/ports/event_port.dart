import '../../core/endpoint/server_endpoint.dart';
import '../events/maic_event.dart';

abstract interface class EventPort {
  Future<List<MaicEvent>> listEvents(ServerEndpoint endpoint, {int count = 100});

  Future<List<MaicAlarm>> listAlarms(ServerEndpoint endpoint);

  Future<void> ackAlarm(ServerEndpoint endpoint, String alarmId);
}
