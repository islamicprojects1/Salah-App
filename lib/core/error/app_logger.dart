import 'package:flutter/foundation.dart';

/// Centralized logger for the Salah app.
///
/// - **Debug builds**: prints to console with level prefix.
/// - **Release builds**: extend [_onRelease] to forward to Crashlytics / Datadog / etc.
///
/// Usage:
/// ```dart
/// AppLogger.info('Prayer times fetched');
/// AppLogger.error('Sync failed', err, stackTrace);
/// ```
class AppLogger {
  const AppLogger._();

  // ============================================================
  // PUBLIC API
  // ============================================================

  /// Low-level debug info. Only emitted in debug builds.
  static void debug(String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) _emit(_Level.debug, message, error, stack);
  }

  /// General informational messages.
  static void info(String message, [Object? error, StackTrace? stack]) =>
      _emit(_Level.info, message, error, stack);

  /// Non-fatal unexpected states.
  static void warning(String message, [Object? error, StackTrace? stack]) =>
      _emit(_Level.warning, message, error, stack);

  /// Errors that should be investigated.
  static void error(String message, [Object? error, StackTrace? stack]) =>
      _emit(_Level.error, message, error, stack);

  // ============================================================
  // INTERNALS
  // ============================================================

  static void _emit(
    _Level level,
    String message,
    Object? error,
    StackTrace? stack,
  ) {
    final buffer = StringBuffer('[${level.label}] $message');
    if (error != null) buffer.write('\n  error: $error');
    if (stack != null) buffer.write('\n$stack');

    final output = buffer.toString();

    if (kDebugMode) {
      // ignore: avoid_print
      print(output);
    }

    if (!kDebugMode) _onRelease(level, output);
  }

  /// Override this to integrate with a crash-reporting SDK in release mode.
  /// Example: `FirebaseCrashlytics.instance.recordError(error, stack)`.
  static void _onRelease(_Level level, String formattedMessage) {
    // TODO: integrate Crashlytics / Sentry / Datadog here.
  }
}

enum _Level {
  debug('DEBUG'),
  info('INFO'),
  warning('WARN'),
  error('ERROR');

  final String label;
  const _Level(this.label);
}
