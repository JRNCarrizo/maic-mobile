import 'video_channel.dart';

class MaicUnit {
  const MaicUnit({
    required this.id,
    required this.displayName,
    this.unitType = '',
    this.unitSubtype = '',
    this.onlineStatus = '',
    this.enabled = true,
    this.visible = true,
    this.groupIds = const [],
    this.channels = const [],
  });

  final String id;
  final String displayName;
  final String unitType;
  final String unitSubtype;
  final String onlineStatus;
  final bool enabled;
  final bool visible;
  final List<String> groupIds;
  final List<VideoChannel> channels;

  bool get isRecorder =>
      unitType.toLowerCase().contains('recorder') ||
      unitSubtype.toLowerCase().contains('recorder');

  bool get isCamera =>
      unitType.toLowerCase().contains('camera') ||
      unitSubtype.toLowerCase().contains('camera');

  OnlineKind get online {
    final value = onlineStatus.toLowerCase();
    if (value.isEmpty) return OnlineKind.unknown;
    if (value.contains('off') ||
        value == 'false' ||
        value == '0' ||
        value.contains('disconnect')) {
      return OnlineKind.offline;
    }
    if (value.contains('on') ||
        value == 'true' ||
        value == '1' ||
        value.contains('connect')) {
      return OnlineKind.online;
    }
    return OnlineKind.unknown;
  }

  String get kindLabel {
    if (isRecorder) return 'Grabador';
    if (isCamera) return 'Cámara';
    return 'Unidad';
  }

  MaicUnit copyWith({List<VideoChannel>? channels}) {
    return MaicUnit(
      id: id,
      displayName: displayName,
      unitType: unitType,
      unitSubtype: unitSubtype,
      onlineStatus: onlineStatus,
      enabled: enabled,
      visible: visible,
      groupIds: groupIds,
      channels: channels ?? this.channels,
    );
  }

  factory MaicUnit.fromJson(Map<String, dynamic> json) {
    final name = (json['displayName'] as String?)?.trim();
    return MaicUnit(
      id: json['id']?.toString() ?? '',
      displayName: (name != null && name.isNotEmpty)
          ? name
          : (json['name'] as String? ?? 'Unidad'),
      unitType: json['unitType']?.toString() ?? '',
      unitSubtype: json['unitSubtype']?.toString() ?? '',
      onlineStatus: json['onlineStatus']?.toString() ?? '',
      enabled: json['enabled'] != false,
      visible: json['visible'] != false,
      groupIds: (json['groupIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

enum OnlineKind { online, offline, unknown }
