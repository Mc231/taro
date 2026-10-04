import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart' as logging;
import 'package:taro_core/taro_core.dart';

/// One log record after the `Redactor` ran: nothing in it may be secret.
@immutable
final class RedactedLogRecord {
  /// Creates a record.
  const RedactedLogRecord({
    required this.level,
    required this.loggerName,
    required this.message,
    this.error,
    this.stack,
  });

  /// The `package:logging` level.
  final logging.Level level;

  /// The full hierarchical name, e.g. `taro.sync`.
  final String loggerName;

  /// The redacted message.
  final String message;

  /// The redacted `toString()` of the attached error, if any.
  final String? error;

  /// The attached stack trace (code locations only).
  final StackTrace? stack;

  /// `LEVEL name: message` plus `| error` when there is one.
  String get line {
    final base = '${level.name} $loggerName: $message';
    return error == null ? base : '$base | $error';
  }
}

/// A destination of redacted log records (02 §13).
abstract interface class LogSink {
  /// The lowest level this sink accepts.
  logging.Level get minLevel;

  /// Writes [record]; called only when `record.level >= minLevel`.
  void write(RedactedLogRecord record);
}

/// The debug console (dev and staging, level FINE; 02 §13).
final class ConsoleLogSink implements LogSink {
  /// Writes each line with [writeLine] (default `debugPrint`, which
  /// throttles long output).
  ConsoleLogSink({
    this.minLevel = logging.Level.FINE,
    void Function(String line)? writeLine,
  }) : _writeLine = writeLine ?? _debugPrint;

  static void _debugPrint(String line) => debugPrint(line);

  @override
  final logging.Level minLevel;

  final void Function(String line) _writeLine;

  @override
  void write(RedactedLogRecord record) {
    _writeLine(record.line);
    if (record.stack case final stack?) _writeLine('$stack');
  }
}

/// Crashlytics breadcrumbs through the `CrashReporter` port (prod, INFO+;
/// 02 §13). The reporter drops them while collection is off.
final class CrashBreadcrumbSink implements LogSink {
  /// Creates a sink over the `crash` reporter.
  CrashBreadcrumbSink(this._crash, {this.minLevel = logging.Level.INFO});

  final CrashReporter _crash;

  @override
  final logging.Level minLevel;

  @override
  void write(RedactedLogRecord record) => _crash.log(record.line);
}

/// Crashlytics non-fatals for `severe` records (prod; 02 §13): a failure
/// that needs attention (for example an attestation failure that blocks
/// readings) is reported with its redacted line, so it can be found without
/// a crash to carry the breadcrumbs. The reporter drops it while collection
/// is off.
final class CrashNonFatalSink implements LogSink {
  /// Creates a sink over the `crash` reporter.
  CrashNonFatalSink(this._crash, {this.minLevel = logging.Level.SEVERE});

  final CrashReporter _crash;

  @override
  final logging.Level minLevel;

  @override
  void write(RedactedLogRecord record) => unawaited(
    _crash.recordError(
      LoggedFailure(record.line),
      record.stack ?? StackTrace.current,
      context: {'logger': record.loggerName},
    ),
  );
}

/// The error reported by [CrashNonFatalSink]: the redacted log line.
@immutable
final class LoggedFailure implements Exception {
  /// Creates the error.
  const LoggedFailure(this.line);

  /// The redacted log line.
  final String line;

  @override
  String toString() => line;
}
