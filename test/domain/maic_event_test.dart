import 'package:flutter_test/flutter_test.dart';
import 'package:maic_mobile/domain/events/maic_event.dart';

void main() {
  test('tolera campos extra en EventDto', () {
    final event = MaicEvent.fromJson({
      'id': '1',
      'message': 'Cruce',
      'type': 'LineCrossing',
      'payloadJson': '{...}',
      'nuevoCampo': true,
    });
    expect(event.id, '1');
    expect(event.message, 'Cruce');
  });

  test('alarma activa se puede reconocer', () {
    final alarm = MaicAlarm.fromJson({
      'id': 'a1',
      'message': 'Entrada',
      'state': 'active',
    });
    expect(alarm.isActive, isTrue);
    final done = alarm.acknowledged(at: DateTime.utc(2026, 9, 27));
    expect(done.isActive, isFalse);
  });
}
