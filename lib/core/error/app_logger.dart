import 'package:flutter/foundation.dart';

/// Centralized logging for the app.
///
/// In debug: prints to console. In release: can be extended to send
/// to Crashlytics or a logging backend. Use instead of print()/debugPrint().
class AppLogger {
  AppLogger._();

  static void _log(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final buffer = StringBuffer('[$level] $message');
    if (error != null) buffer.write(' | $error');
    if (stackTrace != null) buffer.write('\n$stackTrace');
    if (kDebugMode) {
      // ignore: avoid_print
      print(buffer);
    }
    // In release: e.g. FirebaseCrashlytics.instance.log(buffer.toString());
  }

  static void debug(String message, [Object? error]) {
    if (kDebugMode) _log('DEBUG', message, error: error);
  }

  static void info(String message, [Object? error]) {
    _log('INFO', message, error: error);
  }

  static void warning(String message, [Object? error, StackTrace? stack]) {
    _log('WARN', message, error: error, stackTrace: stack);
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    _log('ERROR', message, error: error, stackTrace: stack);
  }
}
