import 'dart:convert';

class LastView {
  const LastView({required this.unitId, this.version = 1});

  final int version;
  final String unitId;

  String toJsonString() => jsonEncode({'v': version, 'unitId': unitId});

  static LastView? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      final unitId = map['unitId']?.toString() ?? '';
      if (unitId.isEmpty) return null;
      return LastView(
        version: map['v'] is int ? map['v'] as int : 1,
        unitId: unitId,
      );
    } catch (_) {
      return null;
    }
  }
}
