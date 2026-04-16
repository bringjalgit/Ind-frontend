import 'dart:math';

class VersionUtils {
  /// Compare two semantic versions.
  /// Returns: -1 (v1 < v2), 0 (equal), 1 (v1 > v2)
  static int compare(String v1, String v2) {
    try {
      final parts1 = v1.split('.').map(int.parse).toList();
      final parts2 = v2.split('.').map(int.parse).toList();
      final len = max(parts1.length, parts2.length);
      for (int i = 0; i < len; i++) {
        final p1 = i < parts1.length ? parts1[i] : 0;
        final p2 = i < parts2.length ? parts2[i] : 0;
        if (p1 < p2) return -1;
        if (p1 > p2) return 1;
      }
      return 0;
    } catch (_) {
      return 0; // Fallback: treat as equal on parse error
    }
  }

  /// Returns true if current < minimum (needs force update)
  static bool needsForceUpdate(String current, String minSupported) {
    return compare(current, minSupported) < 0;
  }

  /// Returns true if current < latest (optional update available)
  static bool hasOptionalUpdate(String current, String latest) {
    return compare(current, latest) < 0;
  }
}
