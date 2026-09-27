import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:maic_mobile/core/errors/app_failure.dart';
import 'package:maic_mobile/data/snapshot/demo_jpeg.dart';
import 'package:maic_mobile/data/snapshot/snapshot_parser.dart';

void main() {
  test('decodifica base64 y no exige el string después', () {
    final image = SnapshotParser.parse({
      'snapshot.base64': demoJpegBase64,
      'snapshot.extension': '.jpg',
      'snapshot.contentType': 'image/jpeg',
      'snapshot.channel': '2',
    }, channel: 1);

    expect(image.bytes, isNotEmpty);
    expect(image.channel, 2);
    expect(image.contentType, 'image/jpeg');
  });

  test('el JPEG demo se puede decodificar', () async {
    final image = SnapshotParser.parse({
      'snapshot.base64': demoJpegBase64,
    }, channel: 1);
    final codec = await ui.instantiateImageCodec(image.bytes);
    expect(codec.frameCount, greaterThan(0));
  });

  test('falla sin base64', () {
    expect(
      () => SnapshotParser.parse(const {}, channel: 1),
      throwsA(isA<AppFailure>()),
    );
  });
}
