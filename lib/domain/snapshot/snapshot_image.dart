import 'dart:typed_data';

class SnapshotImage {
  const SnapshotImage({
    required this.bytes,
    required this.channel,
    this.contentType = 'image/jpeg',
    this.extension = '.jpg',
    this.timestampUtc,
  });

  final Uint8List bytes;
  final int channel;
  final String contentType;
  final String extension;
  final DateTime? timestampUtc;
}
