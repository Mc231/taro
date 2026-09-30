import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../../fakes/fakes.dart';

void main() {
  late FakeInstallRepository install;
  late FakeSessionTokenStore tokens;
  late FakeRemoteConfigRepository config;
  late FakeClock clock;
  late FakeBalanceRepository balance;
  late FakePurchaseOutboxDrainer drainer;
  late FakeReadingRepository readings;
  late FakeDataDeletionGateway deletion;
  late FakeReminderScheduler reminders;
  late FakeSettingsRepository settings;
  late CapturingLogger logger;
  late CallRecorder recorder;
  late SyncAccount sync;

  final cached = aCreditBalance().withLedgerVersion(1).build();
  final server = aCreditBalance().withLedgerVersion(2).withBonus(1).build();
  final validToken = SessionToken(
    token: 'jwt',
    expiresAt: kTestNow.add(const Duration(days: 7)),
  );

  setUp(() {
    recorder = CallRecorder();
    install = FakeInstallRepository()..recorder = recorder;
    tokens = FakeSessionTokenStore(validToken);
    config = FakeRemoteConfigRepository()..recorder = recorder;
    clock = FakeClock();
    balance = FakeBalanceRepository(cached: cached, server: server)
      ..recorder = recorder;
    drainer = FakePurchaseOutboxDrainer()..recorder = recorder;
    final journal = InMemoryJournal();
    readings = FakeReadingRepository(journal: journal, clock: clock)
      ..recorder = recorder;
    deletion = FakeDataDeletionGateway()..recorder = recorder;
    reminders = FakeReminderScheduler()..recorder = recorder;
    settings = FakeSettingsRepository(
      journal: journal,
      initial: const UserSettings(
        reminder: ReminderSettings(enabled: true, time: '20:00'),
      ),
    );
    logger = CapturingLogger();
    final ids = SequentialIdGenerator();
    sync = SyncAccount(
      install: install,
      tokens: tokens,
      config: config,
      timezone: clock,
      balance: balance,
      purchases: drainer,
      resume: ResumeReading(readings: readings, logger: logger),
      readings: readings,
      deletion: DeleteAllData(
        journal: FakeJournalRepository(journal),
        deletion: deletion,
        reminders: reminders,
        ids: ids,
        logger: logger,
      ),
      reminders: reminders,
      settings: settings,
      clock: clock,
      logger: logger,
    );
  });

  test('runs every step in order and reports synced', () async {
    readings.journal.putReading(aReading().pending().build());
    drainer.outcomes = {'txn-1': const PurchaseOutcome.alreadyGranted()};
    readings.pendingAcks.add(const ReadingId('queued-ack'));
    deletion.queuedKey = 'erase-1';

    final status = await sync(SyncReason.launch, locale: 'uk');

    expect(status, SyncStatus.synced(at: clock.now()));
    expect(
      recorder.calls,
      [
        'InstallRepository.ensureRegistered',
        'RemoteConfigRepository.refresh',
        'BalanceRepository.sync',
        'PurchaseOutboxDrainer.drainOutbox',
        'ReadingRepository.pending',
        'ReadingRepository.resume',
        'ReadingRepository.ack',
        'ReadingRepository.flushPendingAcks',
        'DataDeletionGateway.queued',
        'DataDeletionGateway.eraseServerData',
        'DataDeletionGateway.clearQueue',
        'ReminderScheduler.schedule',
      ],
    );
    expect(balance.syncReasons, [SyncReason.launch]);
    expect(install.calls, isNot(contains('refreshToken')));
    expect(drainer.reasons, [SyncReason.launch]);
    expect(readings.acked, contains(const ReadingId('queued-ack')));
    expect(deletion.erased, ['erase-1']);
    expect(reminders.scheduled?.$1.time, '20:00');
    expect(reminders.scheduled?.$2, 'uk');
    expect(logger.at(LogLevel.warning), isEmpty);
  });

  group('authentication', () {
    test('a token expiring within 24 h is refreshed instead', () async {
      tokens.token = SessionToken(
        token: 'jwt',
        expiresAt: kTestNow.add(const Duration(hours: 23)),
      );
      await sync(SyncReason.resume, locale: 'en');
      expect(install.calls, contains('refreshToken'));
      expect(install.calls, isNot(contains('ensureRegistered')));
    });

    test('a failed refresh falls back to registration', () async {
      tokens.token = SessionToken(token: 'jwt', expiresAt: kTestNow);
      install.failNext(const Failure.sessionExpired(), on: 'refreshToken');
      await sync(SyncReason.resume, locale: 'en');
      expect(
        install.calls,
        containsAllInOrder(['refreshToken', 'ensureRegistered']),
      );
      expect(logger.logged('sync step token failed'), isTrue);
    });

    test('an unreadable token store registers', () async {
      tokens.failNext(const Failure.storage(), on: 'read');
      await sync(SyncReason.launch, locale: 'en');
      expect(install.calls, contains('ensureRegistered'));
    });

    test('a failed registration is logged; the pass continues', () async {
      install.failNext(const Failure.network(), on: 'ensureRegistered');
      final status = await sync(SyncReason.launch, locale: 'en');
      expect(status, isA<SyncStatusSynced>());
      expect(logger.logged('sync step register failed: NETWORK'), isTrue);
    });
  });

  group('time zone', () {
    test('a changed device zone is re-registered and applied', () async {
      clock.setTimeZone('Asia/Tokyo', utcOffset: const Duration(hours: 9));
      install.timezoneBalance = aCreditBalance().withLedgerVersion(5).build();
      await sync(SyncReason.resume, locale: 'en');
      expect(install.timezoneUpdates, ['Asia/Tokyo']);
      expect(balance.applied.first.free.timezone, 'Asia/Tokyo');
    });

    test('a rejected change keeps the server boundary', () async {
      clock.setTimeZone('Asia/Tokyo');
      install.failNext(
        Failure.timezoneChangeRejected(allowedAfter: kTestNow),
        on: 'updateTimezone',
      );
      await sync(SyncReason.resume, locale: 'en');
      expect(logger.logged('timezone kept: TIMEZONE_CHANGE_TOO_SOON'), isTrue);
    });

    test('without a balance the registered zone is compared', () async {
      balance.seed(null);
      clock.setTimeZone('Asia/Tokyo');
      await sync(SyncReason.launch, locale: 'en');
      expect(install.timezoneUpdates, ['Asia/Tokyo']);
    });

    test('an unknown previous zone is left alone', () async {
      balance.seed(null);
      install.failNext(const Failure.storage(), on: 'getOrCreate');
      clock.setTimeZone('Asia/Tokyo');
      await sync(SyncReason.launch, locale: 'en');
      expect(install.timezoneUpdates, isEmpty);
    });

    test('an unchanged zone is not re-registered', () async {
      await sync(SyncReason.resume, locale: 'en');
      expect(install.timezoneUpdates, isEmpty);
    });
  });

  group('status', () {
    test('a failed balance sync with a cache is stale', () async {
      balance.failNext(const Failure.network(), on: 'sync');
      expect(
        await sync(SyncReason.resume, locale: 'en'),
        SyncStatus.stale(lastSyncedAt: cached.syncedAt),
      );
      expect(logger.logged('sync step balance failed: NETWORK'), isTrue);
    });

    test('a failed balance sync without a cache is unavailable', () async {
      balance
        ..seed(null)
        ..failNext(const Failure.network(), on: 'sync');
      expect(
        await sync(SyncReason.launch, locale: 'en'),
        const SyncStatus.unavailable(failure: Failure.network()),
      );
    });
  });

  test('failed steps are logged and the pass continues', () async {
    config.failNext(const Failure.timeout());
    drainer.failNext(const Failure.storage());
    readings
      ..failNext(const Failure.storage(), on: 'pending')
      ..failNext(const Failure.network(), on: 'flushPendingAcks');
    final status = await sync(SyncReason.connectivityRegained, locale: 'en');
    expect(status, isA<SyncStatusSynced>());
    for (final step in ['config', 'outbox', 'resume', 'acks']) {
      expect(logger.logged('sync step $step failed'), isTrue, reason: step);
    }
    expect(reminders.calls, contains('schedule'));
  });
}
