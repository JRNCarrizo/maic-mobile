import 'package:flutter_test/flutter_test.dart';
import 'package:maic_mobile/core/errors/app_failure.dart';
import 'package:maic_mobile/data/video/relay_ticket_parser.dart';

void main() {
  test('toma streamUrl y lease sin reconstruir la URL', () {
    final ticket = RelayTicketParser.parse(const {
      'relay.streamUrl': 'http://maic-server:37888/opaque/lease',
      'relay.leaseId': 'L-1',
      'relay.channel': '2',
      'relay.subtype': '1',
      'relay.transportMode': 'HttpMpegTs',
      'relay.host': 'otro-host',
      'relay.port': '1',
    }, channel: 1, subtype: 0);

    expect(ticket.streamUrl, 'http://maic-server:37888/opaque/lease');
    expect(ticket.leaseId, 'L-1');
    expect(ticket.channel, 2);
    expect(ticket.subtype, 1);
  });

  test('falla si no hay streamUrl', () {
    expect(
      () => RelayTicketParser.parse(const {}, channel: 1, subtype: 1),
      throwsA(isA<AppFailure>()),
    );
  });
}
