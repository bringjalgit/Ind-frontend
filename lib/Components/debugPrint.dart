import 'package:flutter/foundation.dart';

class LogHelper {
  static void printLog(String tag, dynamic message) {
    if (kDebugMode) {
      print('$tag: $message');
    }
  }
}
String capitalize(String value) {
  if (value.isEmpty) return "";
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

