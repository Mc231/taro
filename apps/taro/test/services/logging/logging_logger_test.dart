import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart' as logging;
import 'package:taro/services/logging/log_sink.dart';
import 'package:taro/services/logging/logging_logger.dart';
import 'package:taro/services/logging/redactor.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';

final class _MemorySink implements LogSink {
  _MemorySink([this.minLevel = logging.Level.ALL]);

  @override
  final logging.Level minLevel;

  final List<RedactedLogRecord> records = [];

  List<String> get lines => [for (final r in records) r.line];

  @override
  void write(RedactedLogRecord record) => records.add(record);
}

final class _BrokenSink implements LogSink {
  @override
  logging.Level get minLevel => logging.Level.ALL;

  @override
  void write(RedactedLogRecord record) => throw StateError('sink down');
}

void main() {
  group('PackageLoggingLogger', () {
    runLoggerContract(
      () => PackageLoggingLogger.root(sinks: [_MemorySink()]),
    );
  });

  group('SilentLogger', () {
    runLoggerContract(SilentLogger.new);

    test('children are silent too', () {
      const silent = SilentLogger();
      expect(silent.child('x'), same(silent));
    });
  });

  test('writes every level with hierarchical names', () {
    final sink = _MemorySink();
    final root = PackageLoggingLogger.root(sinks: [sink])..fine('f');
    final sync = root.child('sync')..info('i');
    sync.child('balance').warning('w', error: StateError('x'));
    final stack = StackTrace.current;
    root.severe('s', stack: stack);
    expect(sink.lines, [
      'FINE taro: f',
      'INFO taro.sync: i',
      'WARNING taro.sync.balance: w | Bad state: x',
      'SEVERE taro: s',
    ]);
    expect(sink.records.last.stack, stack);
    expect((sync as PackageLoggingLogger).name, 'taro.sync');
    expect(root.child('sync'), same(sync));
  });

  test('redacts messages and errors before any sink sees them', () {
    final sink = _MemorySink();
    final redactor = Redactor();
    final root = PackageLoggingLogger.root(sinks: [sink], redactor: redactor);
    expect(root.redactor, same(redactor));
    const installId = '0f1e2d3c-4b5a-4968-8776-655443322110';
    const secret = 'the-install-secret';
    redactor
      ..registerInstallId(installId)
      ..registerSecret(secret);
    root
        .child('api')
        .info(
          'register {"installId":"$installId","installSecret":"$secret"}',
          error: Exception('question: will it rain'),
        );
    final record = sink.records.single;
    expect(
      record.message,
      'register {"installId":"0f1e2d3c…","installSecret":"<redacted>"}',
    );
    expect(record.error, 'Exception: question: <redacted>');
  });

  test('each sink gets only its levels', () {
    final all = _MemorySink();
    final infoUp = _MemorySink(logging.Level.INFO);
    final severeOnly = _MemorySink(logging.Level.SEVERE);
    PackageLoggingLogger.root(sinks: [all, infoUp, severeOnly])
      ..fine('f')
      ..info('i')
      ..severe('s');
    expect(all.lines, hasLength(3));
    expect(infoUp.lines, ['INFO taro: i', 'SEVERE taro: s']);
    expect(severeOnly.lines, ['SEVERE taro: s']);
  });

  test('a record below every sink level is skipped', () {
    final sink = _MemorySink(logging.Level.SEVERE);
    PackageLoggingLogger.root(sinks: [sink]).fine('quiet');
    expect(sink.records, isEmpty);
  });

  test('a broken sink neither throws nor starves the others', () {
    final sink = _MemorySink();
    final logger = PackageLoggingLogger.root(sinks: [_BrokenSink(), sink]);
    expect(() => logger.info('still logged'), returnsNormally);
    expect(sink.lines, ['INFO taro: still logged']);
  });

  group('forBuild', () {
    test('dev and staging: console at FINE, no breadcrumbs', () {
      final lines = <String>[];
      final crash = FakeCrashReporter();
      PackageLoggingLogger.forBuild(
          isProd: false,
          crash: crash,
          writeLine: lines.add,
        )
        ..fine('trace')
        ..warning('careful', stack: StackTrace.fromString('frame 1'));
      expect(lines, ['FINE taro: trace', 'WARNING taro: careful', 'frame 1']);
      expect(crash.breadcrumbs, isEmpty);
    });

    test('prod: redacted Crashlytics breadcrumbs at INFO+', () {
      final crash = FakeCrashReporter();
      PackageLoggingLogger.forBuild(isProd: true, crash: crash)
        ..fine('trace')
        ..info('purchase {"purchaseToken":"abc"}')
        ..severe('failed', error: StateError('boom'));
      expect(crash.breadcrumbs, [
        'INFO taro: purchase {"purchaseToken":"<redacted>"}',
        'SEVERE taro: failed | Bad state: boom',
      ]);
    });
  });

  test('ConsoleLogSink defaults to FINE and debugPrint', () {
    final printed = <String?>[];
    final previous = debugPrint;
    debugPrint = (message, {wrapWidth}) => printed.add(message);
    addTearDown(() => debugPrint = previous);
    final sink = ConsoleLogSink();
    expect(sink.minLevel, logging.Level.FINE);
    sink.write(
      const RedactedLogRecord(
        level: logging.Level.INFO,
        loggerName: 'taro',
        message: 'hello',
      ),
    );
    expect(printed, ['INFO taro: hello']);
  });

  test('CrashBreadcrumbSink defaults to INFO', () {
    expect(
      CrashBreadcrumbSink(FakeCrashReporter()).minLevel,
      logging.Level.INFO,
    );
  });
}
