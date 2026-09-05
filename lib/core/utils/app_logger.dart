import 'package:flutter/foundation.dart';

/// Log levels supported by [AppLogger].
enum LogLevel { debug, info, warning, error }

/// Lightweight leveled logger that replaces raw `debugPrint` usage.
///
/// In release builds only warnings and errors are printed; verbose debug/info
/// logs are filtered out so production logs stay clean.
class AppLogger {
  AppLogger._();

  static const bool _verboseAllowed = kDebugMode;

  static String _label(LogLevel level) => switch (level) {
        LogLevel.debug => 'DEBUG',
        LogLevel.info => 'INFO',
        LogLevel.warning => 'WARN',
        LogLevel.error => 'ERROR',
      };

  static void debug(String tag, String message) =>
      _log(LogLevel.debug, tag, message);

  static void info(String tag, String message) =>
      _log(LogLevel.info, tag, message);

  static void warning(String tag, String message) =>
      _log(LogLevel.warning, tag, message);

  static void error(String tag, String message,
      [Object? error, StackTrace? stack]) {
    var text = message;
    if (error != null) text = '$message ($error)';
    _log(LogLevel.error, tag, text, stack: stack);
  }

  static void _log(LogLevel level, String tag, String message,
      {StackTrace? stack}) {
    // Production log filtering: drop debug/info outside debug builds.
    if (!_verboseAllowed &&
        (level == LogLevel.debug || level == LogLevel.info)) {
      return;
    }
    debugPrint('[$tag][${_label(level)}] $message');
    if (stack != null && _verboseAllowed) {
      debugPrint(stack.toString());
    }
  }
}
