class ExecuteUnitActionRequest {
  const ExecuteUnitActionRequest({
    required this.unitId,
    required this.moduleId,
    required this.actionKey,
    required this.correlationId,
    this.parameters = const {},
  });

  final String unitId;
  final String moduleId;
  final String actionKey;
  final String correlationId;
  final Map<String, dynamic> parameters;

  Map<String, dynamic> toJson() => {
    'unitId': unitId,
    'moduleId': moduleId,
    'actionKey': actionKey,
    'correlationId': correlationId,
    'parameters': parameters,
  };
}

class ExecuteUnitActionResult {
  const ExecuteUnitActionResult({
    required this.success,
    required this.code,
    required this.userMessage,
    required this.isRetryable,
    required this.data,
    this.errorKind = 0,
  });

  final bool success;
  final String code;
  final String userMessage;
  final bool isRetryable;
  final int errorKind;
  final Map<String, String> data;

  factory ExecuteUnitActionResult.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return ExecuteUnitActionResult(
      success: json['success'] == true,
      code: json['code']?.toString() ?? '',
      userMessage: _userMessage(json),
      isRetryable: json['isRetryable'] == true,
      errorKind: json['errorKind'] is int ? json['errorKind'] as int : 0,
      data: _stringMap(rawData),
    );
  }

  static String _userMessage(Map<String, dynamic> json) {
    final user = json['userMessage']?.toString() ?? '';
    if (user.isNotEmpty) return user;
    return json['message']?.toString() ?? '';
  }

  static Map<String, String> _stringMap(Object? raw) {
    if (raw is! Map) return const {};
    return raw.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
  }
}
