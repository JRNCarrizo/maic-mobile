class MaicEvent {
  const MaicEvent({
    required this.id,
    required this.message,
    this.timestampUtc,
    this.source = '',
    this.type = '',
    this.severity = '',
    this.unitId,
  });

  final String id;
  final String message;
  final DateTime? timestampUtc;
  final String source;
  final String type;
  final String severity;
  final String? unitId;

  factory MaicEvent.fromJson(Map<String, dynamic> json) {
    return MaicEvent(
      id: json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      timestampUtc: DateTime.tryParse(json['timestampUtc']?.toString() ?? ''),
      source: json['source']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      severity: json['severity']?.toString() ?? '',
      unitId: json['unitId']?.toString(),
    );
  }
}

class MaicAlarm {
  const MaicAlarm({
    required this.id,
    required this.message,
    this.moduleId = '',
    this.unitId,
    this.alarmType = '',
    this.severity = '',
    this.state = 'active',
    this.raisedAtUtc,
    this.acknowledgedAtUtc,
    this.acknowledgedBy,
  });

  final String id;
  final String message;
  final String moduleId;
  final String? unitId;
  final String alarmType;
  final String severity;
  final String state;
  final DateTime? raisedAtUtc;
  final DateTime? acknowledgedAtUtc;
  final String? acknowledgedBy;

  bool get isActive => state.toLowerCase() == 'active' && acknowledgedAtUtc == null;

  MaicAlarm acknowledged({required DateTime at, String? by}) {
    return MaicAlarm(
      id: id,
      message: message,
      moduleId: moduleId,
      unitId: unitId,
      alarmType: alarmType,
      severity: severity,
      state: 'acknowledged',
      raisedAtUtc: raisedAtUtc,
      acknowledgedAtUtc: at,
      acknowledgedBy: by,
    );
  }

  factory MaicAlarm.fromJson(Map<String, dynamic> json) {
    return MaicAlarm(
      id: json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      moduleId: json['moduleId']?.toString() ?? '',
      unitId: json['unitId']?.toString(),
      alarmType: json['alarmType']?.toString() ?? '',
      severity: json['severity']?.toString() ?? '',
      state: json['state']?.toString() ?? 'active',
      raisedAtUtc: DateTime.tryParse(json['raisedAtUtc']?.toString() ?? ''),
      acknowledgedAtUtc: DateTime.tryParse(
        json['acknowledgedAtUtc']?.toString() ?? '',
      ),
      acknowledgedBy: json['acknowledgedBy']?.toString(),
    );
  }
}
