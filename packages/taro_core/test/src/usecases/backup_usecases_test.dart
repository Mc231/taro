import 'dart:convert';
import 'dart:typed_data';

import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../../contracts/contract_support.dart';
import '../../fakes/fakes.dart';

void main() {
  late InMemoryJournal store;
  late FakeJournalRepository journal;
  late FakeSettingsRepository settings;
  late FakeFileTransfer files;
  late FakeContentRepository content;
  late FakeClock clock;

  final complete = aReading().build();
  final pending = aReading()
      .withId('44444444-4444-4444-8444-444444444444')
      .pending()
      .build();
  final daily = aDailyCard().build();

  setUp(() {
    store = InMemoryJournal();
    journal = FakeJournalRepository(store);
    settings = FakeSettingsRepository(journal: store);
    files = FakeFileTransfer();
    content = FakeContentRepository();
    // 22:30Z is 01:30 the next day in Kyiv.
    clock = FakeClock(DateTime.utc(2026, 9, 26, 22, 30));
  });

  group('ExportBackup', () {
    late ExportBackup export;

    setUp(() {
      export = ExportBackup(
        journal: journal,
        settings: settings,
        appInfo: const FakeAppInfo(version: '1.2.0', buildNumber: '34'),
        files: files,
        clock: clock,
      );
      store
        ..putReading(complete)
        ..putReading(pending)
        ..putDailyCard(daily)
        ..putSettings(const UserSettings(themeMode: ThemeMode.dark));
    });

    test('shares a valid, checksummed file of exportable entries', () async {
      final backup = expectOk(await export());
      expect(backup.exportedAt, clock.now());
      expect(backup.appVersion, '1.2.0+34');
      expect(backup.data.readings, [complete]);
      expect(backup.data.dailyCards, [daily]);
      expect(backup.data.settings.themeMode, ThemeMode.dark);
      expect(backup.checksum, BackupChecksum.of(backup.data));

      final file = files.shared.single;
      expect(file.fileName, 'taro-backup-2026-09-27.json');
      expect(file.mime, ExportBackup.mimeType);
      expect(jsonDecode(utf8.decode(file.bytes)), backup.toJson());
      // The exported file passes the import validator.
      final checked = BackupValidator(deck: aDeck().build()).validateBytes(
        file.bytes,
      );
      expect(expectOk(checked).data.readings.single.id, complete.id);
    });

    test('a journal failure shares nothing', () async {
      journal.failNext(const Failure.storage(), on: 'snapshot');
      expect(expectErr(await export()), const Failure.storage());
      expect(files.shared, isEmpty);
    });

    test('a share failure is returned', () async {
      files.failNext(const Failure.storage(), on: 'share');
      expect(expectErr(await export()), const Failure.storage());
    });
  });

  group('ImportBackup', () {
    late ImportBackup import;

    setUp(() {
      import = ImportBackup(
        files: files,
        content: content,
        journal: journal,
        settings: settings,
      );
    });

    group('pick', () {
      test('a cancelled picker is Ok(null)', () async {
        expect(expectOk(await import.pick()), isNull);
      });

      test('a picker failure is returned', () async {
        files.failNext(const Failure.storage(), on: 'pickJson');
        expect(expectErr(await import.pick()), const Failure.storage());
      });

      test('a valid file yields a preview with counts', () async {
        files.willPick(aBackup().bytes());
        final preview = expectOk(await import.pick())!;
        expect(preview.readings, 1);
        expect(preview.dailyCards, 1);
      });
    });

    group('inspect', () {
      test('keeps the device reduce-motion setting', () async {
        await settings.update((s) => s.copyWith(reduceMotion: true));
        final preview = expectOk(await import.inspect(aBackup().bytes()));
        expect(preview.backup.data.settings.reduceMotion, isTrue);
      });

      test('rejects invalid files with the reason', () async {
        final cases = <Uint8List, BackupInvalidReason>{
          Uint8List.fromList(utf8.encode('not json')):
              BackupInvalidReason.notJson,
          aBackup().withFormat('other').bytes():
              BackupInvalidReason.wrongFormat,
          aBackup().withVersion(2).bytes():
              BackupInvalidReason.unsupportedVersion,
          aBackup().withExtraKey('credits', 5, inData: true).bytes():
              BackupInvalidReason.schema,
          aBackup().withChecksum('0' * 64).bytes():
              BackupInvalidReason.checksum,
        };
        for (final MapEntry(key: bytes, value: reason) in cases.entries) {
          expect(
            expectErr(await import.inspect(bytes)),
            Failure.backupInvalid(reason: reason),
            reason: reason.name,
          );
        }
      });

      test('a missing deck is a failure', () async {
        content.failNext(const Failure.storage(), on: 'deck');
        expect(
          expectErr(await import.inspect(aBackup().bytes())),
          const Failure.storage(),
        );
      });
    });

    group('apply', () {
      final incoming = aReading()
          .withId('55555555-5555-4555-8555-555555555555')
          .build();

      late ImportPreview preview;

      setUp(() async {
        store
          ..putReading(complete)
          ..putReading(pending);
        preview = expectOk(
          await import.inspect(
            aBackup().withReadings([incoming]).withDailyCards([daily]).bytes(),
          ),
        );
      });

      test('merges by default and writes in one transaction', () async {
        final report = expectOk(await import.apply(preview));
        expect(report.added, 2);
        expect(journal.replaced, hasLength(1));
        expect(
          store.readings.keys,
          containsAll([complete.id, pending.id, incoming.id]),
        );
        expect(store.dailyCards.keys, [daily.localDate]);
      });

      test('replace drops local entries but keeps pending ones', () async {
        final report = expectOk(
          await import.apply(preview, mode: MergeMode.replace),
        );
        expect(report.removed, 1);
        expect(store.readings.keys, unorderedEquals([pending.id, incoming.id]));
      });

      test('a journal read failure is returned', () async {
        journal.failNext(const Failure.storage(), on: 'snapshot');
        expect(expectErr(await import.apply(preview)), const Failure.storage());
        expect(journal.replaced, isEmpty);
      });

      test('a write failure is returned and nothing changes', () async {
        journal.failNext(const Failure.storage(), on: 'replaceAll');
        expect(expectErr(await import.apply(preview)), const Failure.storage());
        expect(store.readings.keys, unorderedEquals([complete.id, pending.id]));
      });
    });
  });
}
