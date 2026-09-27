import 'package:flutter/foundation.dart';

import '../../domain/auth/user_session.dart';

/// Sesión solo en memoria. Nunca persistir sessionId.
class SessionStore extends ChangeNotifier {
  UserSession? _session;

  UserSession? get session => _session;

  bool get isAuthenticated => _session != null;

  void replace(UserSession session) {
    _session = session;
    notifyListeners();
  }

  void clear() {
    if (_session == null) return;
    _session = null;
    notifyListeners();
  }
}
