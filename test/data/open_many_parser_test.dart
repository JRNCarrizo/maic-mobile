import 'package:flutter_test/flutter_test.dart';
import 'package:maic_mobile/data/video/open_many_parser.dart';

void main() {
  test('acepta éxito parcial por item', () {
    final items = OpenManyParser.parse(const {
      'stream.count': '2',
      'stream.successCount': '1',
      'stream.0.key': 'cam-01',
      'stream.0.channel': '1',
      'stream.0.subtype': '1',
      'stream.0.success': 'true',
      'stream.0.relay.streamUrl': 'http://maic-server:37888/a',
      'stream.0.relay.leaseId': 'L-A',
      'stream.1.key': 'cam-02',
      'stream.1.channel': '2',
      'stream.1.subtype': '1',
      'stream.1.success': 'false',
      'stream.1.userMessage': 'Cámara no disponible.',
    });

    expect(items, hasLength(2));
    expect(items[0].success, isTrue);
    expect(items[0].ticket?.streamUrl, 'http://maic-server:37888/a');
    expect(items[1].success, isFalse);
    expect(items[1].userMessage, 'Cámara no disponible.');
  });
}
