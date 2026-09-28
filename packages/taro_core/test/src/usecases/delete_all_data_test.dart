import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../../contracts/contract_support.dart';
import '../../fakes/fakes.dart';

void main() {
  late FakeJournalRepository journal;
  late FakeDataDeletionGateway deletion;
  late FakeReminderScheduler reminders;
  late SequentialIdGenerator ids;
  late CapturingLogger logger;
  late CallRecorder recorder;
  late DeleteAllData deleteAll;

  setUp(() {
    recorder = CallRecorder();
    journal = FakeJournalRepository()..recorder = recorder;
    journal.journal
      ..putReading(aReading().build())
      ..putDailyCard(aDailyCard().build())
      ..putSettings(const UserSettings(themeMode: ThemeMode.dark));
    deletion = FakeDataDeletionGateway()..recorder = recorder;
    reminders = FakeReminderScheduler()..recorder = recorder;
    ids = SequentialIdGenerator('erase-');
    logger = CapturingLogger();
    deleteAll = DeleteAllData(
      journal: journal,
      deletion: deletion,
      reminders: reminders,
      ids: ids,
      logger: logger,
    );
  });

  group('call', () {
    test(
      'wipes the journal, cancels reminders and erases the server',
      () async {
        await reminders.schedule(const ReminderSettings(enabled: true), 'en');
        final outcome = expectOk(await deleteAll());
        expect(outcome, DataDeletionOutcome.complete);
        expect(journal.journal.readings, isEmpty);
        expect(journal.journal.dailyCards, isEmpty);
        expect(journal.journal.settings, const UserSettings());
        expect(reminders.scheduled, isNull);
        expect(deletion.erased, ['erase-1']);
        expect(deletion.queuedKey, isNull);
        // Queued before the call, so a kill mid-call still erases later.
        expect(
          recorder.isBefore(
            'DataDeletionGateway.queue',
            'DataDeletionGateway.eraseServerData',
          ),
          isTrue,
        );
        expect(
          recorder.isBefore(
            'JournalRepository.deleteAll',
            'DataDeletionGateway.queue',
          ),
          isTrue,
        );
      },
    );

    test('a failed local wipe fails and touches nothing else', () async {
      journal.failNext(const Failure.storage(), on: 'deleteAll');
      expect(expectErr(await deleteAll()), const Failure.storage());
      expect(journal.journal.readings, isNotEmpty);
      expect(reminders.calls, isEmpty);
      expect(deletion.calls, isEmpty);
    });

    test('a failed server erasure is partial and stays queued', () async {
      deletion.failNext(const Failure.network(), on: 'eraseServerData');
      expect(expectOk(await deleteAll()), DataDeletionOutcome.partial);
      expect(deletion.queuedKey, 'erase-1');
      expect(logger.logged('NETWORK', level: LogLevel.info), isTrue);
    });

    test('a failed queue write is logged; erasure still runs', () async {
      deletion.failNext(const Failure.storage(), on: 'queue');
      expect(expectOk(await deleteAll()), DataDeletionOutcome.complete);
      expect(deletion.erased, ['erase-1']);
      expect(logger.logged('STORAGE', level: LogLevel.warning), isTrue);
    });
  });

  group('retryQueued', () {
    test('does nothing when nothing is queued', () async {
      expect(await deleteAll.retryQueued(), isNull);
      expect(deletion.erased, isEmpty);
    });

    test('does nothing when the queue cannot be read', () async {
      deletion
        ..queuedKey = 'erase-9'
        ..failNext(const Failure.storage(), on: 'queued');
      expect(await deleteAll.retryQueued(), isNull);
      expect(deletion.erased, isEmpty);
    });

    test('erases with the queued key and clears it', () async {
      deletion.queuedKey = 'erase-9';
      expect(await deleteAll.retryQueued(), DataDeletionOutcome.complete);
      expect(deletion.erased, ['erase-9']);
      expect(deletion.queuedKey, isNull);
    });

    test('keeps the key when the erasure fails again', () async {
      deletion
        ..queuedKey = 'erase-9'
        ..failNext(const Failure.timeout(), on: 'eraseServerData');
      expect(await deleteAll.retryQueued(), DataDeletionOutcome.partial);
      expect(deletion.queuedKey, 'erase-9');
    });
  });
}
