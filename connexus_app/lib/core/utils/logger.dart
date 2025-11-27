import 'package:flutter/foundation.dart';

/// Centralized logging utility
class Logger {
  static const String _tag = 'ConnexUS';

  static void debug(String message, [dynamic data]) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('🔍 $_tag [DEBUG]: $message');
      if (data != null) {
        // ignore: avoid_print
        print('   Data: $data');
      }
    }
  }

  static void info(String message, [dynamic data]) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('ℹ️ $_tag [INFO]: $message');
      if (data != null) {
        // ignore: avoid_print
        print('   Data: $data');
      }
    }
  }

  static void warning(String message, [dynamic data]) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('⚠️ $_tag [WARNING]: $message');
      if (data != null) {
        // ignore: avoid_print
        print('   Data: $data');
      }
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    // ignore: avoid_print
    print('❌ $_tag [ERROR]: $message');
    if (error != null) {
      // ignore: avoid_print
      print('   Error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      // ignore: avoid_print
      print('   Stack trace:\n$stackTrace');
    }
  }

  static void network(String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('🌐 $_tag [NETWORK]: $message');
      if (data != null) {
        // ignore: avoid_print
        print('   Request/Response: $data');
      }
    }
  }
}
