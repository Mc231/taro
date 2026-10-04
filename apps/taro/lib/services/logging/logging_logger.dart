import 'package:logging/logging.dart' as logging;
import 'package:taro/services/logging/log_sink.dart';
import 'package:taro/services/logging/redactor.dart';
import 'package:taro_core/taro_core.dart';

/// The production `Logger` (RC41, 02 §13) over `package:logging`.
///
/// Each name (`taro`, `taro.sync`, …) is a detached `package:logging`
/// logger, so no global `Logger.root` state is touched. Every record is run
/// through the [Redactor] before it reaches a [LogSink]; a failing sink never
/// breaks the caller or the other sinks.
final class PackageLoggingLogger implements Logger {
  PackageLoggingLogger._(this._hub, this._delegate);

  /// The root logger named [name] writing to [sinks].
  factory PackageLoggingLogger.root({
    required List<LogSink> sinks,
    Redactor? redactor,
    String name = 'taro',
  }) => _LogHub(sinks, redactor ?? Redactor()).logger(name);

  /// The sinks of 02 §13 for a build: the debug console (FINE) in dev and
  /// staging; in prod, Crashlytics breadcrumbs (INFO+) and a non-fatal for
  /// each SEVERE record.
  factory PackageLoggingLogger.forBuild({
    required bool isProd,
    required CrashReporter crash,
    Redactor? redactor,
    void Function(String line)? writeLine,
  }) => PackageLoggingLogger.root(
    redactor: redactor,
    sinks: isProd
        ? [CrashBreadcrumbSink(crash), CrashNonFatalSink(crash)]
        : [ConsoleLogSink(writeLine: writeLine)],
  );

  final _LogHub _hub;
  final logging.Logger _delegate;

  /// The full hierarchical name, e.g. `taro.sync`.
  String get name => _delegate.fullName;

  /// The redactor shared by this logger and its children (register the
  /// install ID and secrets on it once they are known).
  Redactor get redactor => _hub.redactor;

  @override
  void fine(String message, {Object? error, StackTrace? stack}) =>
      _delegate.fine(message, error, stack);

  @override
  void info(String message, {Object? error, StackTrace? stack}) =>
      _delegate.info(message, error, stack);

  @override
  void warning(String message, {Object? error, StackTrace? stack}) =>
      _delegate.warning(message, error, stack);

  @override
  void severe(String message, {Object? error, StackTrace? stack}) =>
      _delegate.severe(message, error, stack);

  @override
  Logger child(String name) => _hub.logger('${this.name}.$name');
}

/// The `Logger` that drops everything (tests, 02 §5).
final class SilentLogger implements Logger {
  /// Creates a silent logger.
  const SilentLogger();

  @override
  void fine(String message, {Object? error, StackTrace? stack}) {}

  @override
  void info(String message, {Object? error, StackTrace? stack}) {}

  @override
  void warning(String message, {Object? error, StackTrace? stack}) {}

  @override
  void severe(String message, {Object? error, StackTrace? stack}) {}

  @override
  Logger child(String name) => this;
}

/// Shared by a root logger and its children: the sinks, the redactor and
/// one cached logger per name.
final class _LogHub {
  _LogHub(List<LogSink> sinks, this.redactor)
    : _sinks = List.unmodifiable(sinks);

  final List<LogSink> _sinks;
  final Redactor redactor;
  final Map<String, PackageLoggingLogger> _loggers = {};

  PackageLoggingLogger logger(String name) => _loggers.putIfAbsent(name, () {
    final delegate = logging.Logger.detached(name)..level = logging.Level.ALL;
    delegate.onRecord.listen(_dispatch);
    return PackageLoggingLogger._(this, delegate);
  });

  void _dispatch(logging.LogRecord record) {
    final sinks = [
      for (final sink in _sinks)
        if (record.level >= sink.minLevel) sink,
    ];
    if (sinks.isEmpty) return;
    final redacted = RedactedLogRecord(
      level: record.level,
      loggerName: record.loggerName,
      message: redactor.redact(record.message),
      error: switch (record.error) {
        null => null,
        final error => redactor.redact('$error'),
      },
      stack: record.stackTrace,
    );
    for (final sink in sinks) {
      try {
        sink.write(redacted);
      } on Object {
        // Logging is best effort: a broken sink must neither throw into the
        // caller nor starve the other sinks, and reporting it through this
        // logger would recurse into the same sink.
      }
    }
  }
}
