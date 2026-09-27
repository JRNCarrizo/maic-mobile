class UserSession {
  const UserSession({
    required this.sessionId,
    required this.displayName,
    required this.loginName,
    required this.role,
    required this.permissions,
    this.userPrincipalName = '',
    this.issuedAtUtc,
    this.expiresAtUtc,
  });

  final String sessionId;
  final String displayName;
  final String loginName;
  final String userPrincipalName;
  final int role;
  final List<String> permissions;
  final DateTime? issuedAtUtc;
  final DateTime? expiresAtUtc;

  String get roleLabel => switch (role) {
    0 => 'Viewer',
    1 => 'Operador',
    2 => 'Admin',
    _ => 'Rol $role',
  };

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      sessionId: json['sessionId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      loginName: json['loginName'] as String? ?? '',
      userPrincipalName: json['userPrincipalName'] as String? ?? '',
      role: json['role'] as int? ?? 0,
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      issuedAtUtc: _parseTime(json['issuedAtUtc']),
      expiresAtUtc: _parseTime(json['expiresAtUtc']),
    );
  }

  static DateTime? _parseTime(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }
}

class LoginResult {
  const LoginResult({required this.session, this.licenseStatusText = 'OK'});

  final UserSession session;
  final String licenseStatusText;
}
