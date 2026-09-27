import 'package:flutter/foundation.dart';

/// Logger que no debe recibir secretos. El caller sanitiza.
abstract final class AppLogger {
  static void info(String message) {
    debugPrint('[MAIC] $message');
  }

  static void warn(String message) {
    debugPrint('[MAIC][WARN] $message');
  }

  static void error(String message) {
    debugPrint('[MAIC][ERROR] $message');
  }
}
