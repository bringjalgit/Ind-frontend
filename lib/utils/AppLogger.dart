import 'package:flutter/foundation.dart';

class AppLogger {
  /// General log (debug only)
  static void log(String message) {
    if (kDebugMode) {
      debugPrint("🔹 $message"); // direct call, no recursion
    }
  }

  /// Error log (debug only)
  static void error(String message) {
    if (kDebugMode) {
      debugPrint("❌ ERROR: $message"); // no recursive call
    }
  }

  /// Info log (debug only)
  static void info(String message) {
    // if (kDebugMode) {
      debugPrint("✅ INFO: $message"); // no recursive call
    // }
  }
}
