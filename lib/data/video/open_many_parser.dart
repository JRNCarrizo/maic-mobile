import '../../domain/video/stream_request.dart';
import 'relay_ticket_parser.dart';

abstract final class OpenManyParser {
  static final _index = RegExp(r'^stream\.(\d+)\.');

  static List<StreamOpenResult> parse(Map<String, String> data) {
    final indexes = <int>{};
    for (final key in data.keys) {
      final match = _index.firstMatch(key);
      if (match != null) indexes.add(int.parse(match.group(1)!));
    }
    final ordered = indexes.toList()..sort();
    return [
      for (final i in ordered) _item(data, i),
    ];
  }

  static StreamOpenResult _item(Map<String, String> data, int i) {
    final prefix = 'stream.$i.';
    final success = data['${prefix}success']?.toLowerCase() == 'true';
    final key = data['${prefix}key'] ?? 'stream-$i';
    final channel = int.tryParse(data['${prefix}channel'] ?? '') ?? 0;
    final subtype = int.tryParse(data['${prefix}subtype'] ?? '') ?? 1;
    if (!success) {
      return StreamOpenResult(
        key: key,
        channel: channel,
        subtype: subtype,
        success: false,
        userMessage:
            data['${prefix}userMessage'] ??
            data['${prefix}error'] ??
            'No se pudo abrir este stream.',
      );
    }

    final relay = <String, String>{};
    final relayPrefix = '${prefix}relay.';
    data.forEach((mapKey, value) {
      if (mapKey.startsWith(relayPrefix)) {
        relay['relay.${mapKey.substring(relayPrefix.length)}'] = value;
      }
    });

    try {
      return StreamOpenResult(
        key: key,
        channel: channel,
        subtype: subtype,
        success: true,
        ticket: RelayTicketParser.parse(
          relay,
          channel: channel,
          subtype: subtype,
        ),
      );
    } catch (_) {
      return StreamOpenResult(
        key: key,
        channel: channel,
        subtype: subtype,
        success: false,
        userMessage: 'Este stream no trajo una URL válida.',
      );
    }
  }
}
