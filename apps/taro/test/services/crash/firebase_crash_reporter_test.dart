import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/crash/firebase_crash_reporter.dart';
import 'package:taro/services/crash/noop_crash_reporter.dart';
import 'package:taro/services/logging/redactor.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../analytics/firebase_fakes.dart';

const _installId = '3f2c9a71-5b6e-4d2a-9c1f-8e7d6b5a4c3b';

Future<FirebaseCrashReporter> _reporter({
  bool enabled = true,
  Redactor? redactor,
}) => FirebaseCrashReporter.create(
  FirebaseCrashlytics.instance,
  flavor: 'staging',
  collectionEnabled: enabled,
  redactor: redactor ?? Redactor(),
);

void main() {
  setUpAll(setUpFirebaseFakes);

  group('contract', () {
    late FirebaseCrashReporter reporter;

    setUp(() async {
      await setUpFirebaseFakes();
      reporter = await _reporter();
    });

    runCrashReporterContract(() => reporter);
  });

  group('NoOpCrashReporter', () {
    runCrashReporterContract(NoOpCrashReporter.new);
  });

  setUp(setUpFirebaseFakes);

  test('create applies collection and the flavor key', () async {
    final reporter = await _reporter(enabled: false);
    expect(reporter.collectionEnabled, isFalse);
    expect(crashlyticsPlatform.collection, [false]);
    expect(crashlyticsPlatform.keys, {'flavor': 'staging'});
  });

  test('records errors with redacted text and context', () async {
    final redactor = Redactor()..registerInstallId(_installId);
    final reporter = await _reporter(redactor: redactor);
    await reporter.recordError(
      StateError('boom for install $_installId'),
      StackTrace.current,
      fatal: true,
      context: {'step': 'balance', 'installSecret': 's3cr3t-value'},
    );
    final error = crashlyticsPlatform.errors.single;
    expect(error.fatal, isTrue);
    expect(
      error.exception,
      'StateError: Bad state: boom for install 3f2c9a71…',
    );
    expect(error.information, 'step=balance\ninstallSecret=<redacted>');
    expect(error.information, isNot(contains('s3cr3t')));
  });

  test('an error whose text names its type keeps it once', () async {
    final reporter = await _reporter();
    await reporter.recordError(const _Named(), StackTrace.empty);
    expect(crashlyticsPlatform.errors.single.exception, '_Named went wrong');
  });

  test('every UnexpectedFailure is reported non-fatal, unwrapped', () async {
    final reporter = await _reporter();
    final failure = Failure.unexpected(
      error: ArgumentError('bad'),
      stack: StackTrace.current,
    );
    await reporter.recordError(failure, StackTrace.empty, fatal: true);
    await reporter.recordFailure(failure);
    await reporter.recordFailure(const Failure.network());
    expect(crashlyticsPlatform.errors, hasLength(2));
    for (final error in crashlyticsPlatform.errors) {
      expect(error.fatal, isFalse);
      expect(error.exception, 'ArgumentError: Invalid argument(s): bad');
    }
  });

  test('breadcrumbs are redacted', () async {
    (await _reporter()).log(
      'INFO taro.api: Authorization: Bearer abc.def.ghi',
    );
    await pumpEventQueue();
    expect(crashlyticsPlatform.logs, [
      'INFO taro.api: Authorization: <redacted>',
    ]);
  });

  test('nothing is recorded while collection is off', () async {
    final reporter = await _reporter();
    await reporter.setCollectionEnabled(enabled: false);
    reporter.log('ignored');
    await reporter.recordError(StateError('ignored'), StackTrace.empty);
    await pumpEventQueue();
    expect(crashlyticsPlatform.logs, isEmpty);
    expect(crashlyticsPlatform.errors, isEmpty);
    expect(crashlyticsPlatform.collection, [true, false]);

    await reporter.setCollectionEnabled(enabled: true);
    expect(reporter.collectionEnabled, isTrue);
    reporter.log('kept');
    await pumpEventQueue();
    expect(crashlyticsPlatform.logs, ['kept']);
  });

  test('custom keys: locale, sync_status, last_route', () async {
    final reporter = await _reporter();
    await reporter.setLocale('pt-BR');
    await reporter.setLastRoute('/journal/reading?token=abc123');
    await reporter.setSyncStatus(const SyncStatus.syncing());
    expect(crashlyticsPlatform.keys, {
      'flavor': 'staging',
      'locale': 'pt-BR',
      'last_route': '/journal/reading?token=<redacted>',
      'sync_status': 'syncing',
    });
    final statuses = {
      SyncStatus.synced(at: DateTime.utc(2026)): 'synced',
      const SyncStatus.stale(): 'stale',
      const SyncStatus.unavailable(failure: Failure.network()):
          'unavailable:NETWORK',
    };
    for (final MapEntry(key: status, value: wire) in statuses.entries) {
      await reporter.setSyncStatus(status);
      expect(crashlyticsPlatform.keys[CrashKeys.syncStatus], wire);
    }
  });

  test('Crashlytics failures never escape', () async {
    crashlyticsPlatform.failWith = StateError('platform down');
    final reporter = await _reporter();
    reporter.log('lost');
    await reporter.recordError(StateError('lost'), StackTrace.empty);
    await reporter.setCollectionEnabled(enabled: false);
    await reporter.setLocale('en');
    await pumpEventQueue();
    expect(crashlyticsPlatform.errors, isEmpty);
  });
}

final class _Named {
  const _Named();

  @override
  String toString() => '_Named went wrong';
}
