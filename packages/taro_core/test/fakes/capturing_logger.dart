import 'package:taro_core/taro_core.dart';

/// A log level of [CapturingLogger].
enum LogLevel {
  /// `fine`.
  fine,

  /// `info`.
  info,

  /// `warning`.
  warning,

  /// `severe`.
  severe,
}

/// One captured log call.
final class LogRecord {
  /// Creates a record.
  const LogRecord(
    this.level,
    this.logger,
    this.message,
    this.error,
    this.stack,
  );

  /// The level.
  final LogLevel level;

  /// The full logger name, e.g. `taro.sync`.
  final String logger;

  /// The message.
  final String message;

  /// The attached error.
  final Object? error;

  /// The attached stack.
  final StackTrace? stack;

  @override
  String toString() => '${level.name} $logger: $message';
}

/// A [Logger] that keeps every call; children share the parent's records.
final class CapturingLogger implements Logger {
  /// A root logger named [name].
  CapturingLogger([this.name = 'taro']) : records = [];

  CapturingLogger._child(this.name, this.records);

  /// This logger's full name.
  final String name;

  /// Every record of this logger and its children, oldest first.
  final List<LogRecord> records;

  /// Every message, oldest first.
  List<String> get messages => [for (final r in records) r.message];

  /// Records at [level].
  List<LogRecord> at(LogLevel level) => [
    for (final r in records)
      if (r.level == level) r,
  ];

  /// Whether a message matching [pattern] was logged (at [level] if given).
  bool logged(Pattern pattern, {LogLevel? level}) => records.any(
    (r) => (level == null || r.level == level) && r.message.contains(pattern),
  );

  void _add(LogLevel level, String message, Object? error, StackTrace? stack) =>
      records.add(LogRecord(level, name, message, error, stack));

  @override
  void fine(String message, {Object? error, StackTrace? stack}) =>
      _add(LogLevel.fine, message, error, stack);

  @override
  void info(String message, {Object? error, StackTrace? stack}) =>
      _add(LogLevel.info, message, error, stack);

  @override
  void warning(String message, {Object? error, StackTrace? stack}) =>
      _add(LogLevel.warning, message, error, stack);

  @override
  void severe(String message, {Object? error, StackTrace? stack}) =>
      _add(LogLevel.severe, message, error, stack);

  @override
  Logger child(String name) =>
      CapturingLogger._child('${this.name}.$name', records);
}

/// The fake of the `Logger` port.
typedef FakeLogger = CapturingLogger;
