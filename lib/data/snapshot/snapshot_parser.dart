import 'dart:convert';
import 'dart:typed_data';

import '../../core/errors/app_failure.dart';
import '../../domain/snapshot/snapshot_image.dart';

abstract final class SnapshotParser {
  static SnapshotImage parse(Map<String, String> data, {required int channel}) {
    final raw = data['snapshot.base64'] ?? '';
    if (raw.isEmpty) {
      throw const AppFailure(
        kind: FailureKind.invalidResponse,
        userMessage: 'El servidor no envió la imagen.',
      );
    }

    late final Uint8List bytes;
    try {
      bytes = Uint8List.fromList(base64Decode(raw));
    } catch (_) {
      throw const AppFailure(
        kind: FailureKind.invalidResponse,
        userMessage: 'La imagen del snapshot no se pudo leer.',
      );
    }
    if (bytes.isEmpty) {
      throw const AppFailure(
        kind: FailureKind.invalidResponse,
        userMessage: 'La imagen del snapshot vino vacía.',
      );
    }

    return SnapshotImage(
      bytes: bytes,
      channel: int.tryParse(data['snapshot.channel'] ?? '') ?? channel,
      contentType: data['snapshot.contentType'] ?? 'image/jpeg',
      extension: data['snapshot.extension'] ?? '.jpg',
      timestampUtc: DateTime.tryParse(data['snapshot.timestampUtc'] ?? ''),
    );
  }
}
