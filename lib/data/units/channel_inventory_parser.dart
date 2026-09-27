import '../../domain/units/video_channel.dart';

/// Parsea el diccionario plano de videorecorder.refreshDeviceInfo.
abstract final class ChannelInventoryParser {
  static final _field = RegExp(
    r'^inventory\.channel\.(\d+)\.(requestChannel|name|state|mainStream|extraStream)$',
  );

  static List<VideoChannel> parse(
    Map<String, String> data, {
    bool defaultCameraChannel = false,
  }) {
    final buckets = <int, _Draft>{};
    for (final entry in data.entries) {
      final match = _field.firstMatch(entry.key);
      if (match == null) continue;
      final index = int.parse(match.group(1)!);
      final field = match.group(2)!;
      final draft = buckets.putIfAbsent(index, _Draft.new);
      switch (field) {
        case 'requestChannel':
          draft.requestChannel = int.tryParse(entry.value);
        case 'name':
          draft.name = entry.value;
        case 'state':
          draft.state = entry.value;
        case 'mainStream':
          draft.mainStream = entry.value;
        case 'extraStream':
          draft.extraStream = entry.value;
      }
    }

    final channels = buckets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final parsed = <VideoChannel>[];
    for (final item in channels) {
      final request = item.value.requestChannel;
      if (request == null) continue;
      parsed.add(
        VideoChannel(
          requestChannel: request,
          name: item.value.name.isEmpty
              ? 'Canal $request'
              : item.value.name,
          state: item.value.state,
          mainStream: item.value.mainStream,
          extraStream: item.value.extraStream,
        ),
      );
    }

    if (parsed.isEmpty && defaultCameraChannel) {
      return const [VideoChannel(requestChannel: 1, name: 'Canal 1')];
    }
    return parsed;
  }
}

class _Draft {
  int? requestChannel;
  String name = '';
  String state = '';
  String mainStream = '';
  String extraStream = '';
}
