import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/backup/controller/export_controller.dart';
import 'package:taro/features/backup/controller/import_controller.dart';
import 'package:taro_core/taro_core.dart';

import '../../helpers/pump_app.dart';

const ReadingId _importedId = ReadingId(
  '0c6e2b1e-1111-4222-8333-000000000001',
);

void main() {
  late TaroFakes fakes;

  setUp(() {
    fakes = TaroFakes();
    fakes.journal
      ..putReading(aReading().build())
      ..putDailyCard(aDailyCard().build());
  });

  group('ExportController (S24)', () {
    (ProviderContainer, ExportController, List<ExportState>) open() {
      final container = fakes.container();
      final states = <ExportState>[];
      container.listen(
        exportControllerProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );
      return (
        container,
        container.read(exportControllerProvider.notifier),
        states,
      );
    }

    test(
      'idle → preparing → shareSheetOpen → done; export_completed',
      () async {
        final (_, controller, states) = open();
        await controller.export();
        expect(states, const [
          ExportState.idle(),
          ExportState.preparing(),
          ExportState.shareSheetOpen(),
          ExportState.done(entries: 2),
        ]);
        expect(
          fakes.files.shared.single.fileName,
          'taro-backup-2026-09-26.json',
        );
        expect(fakes.analytics.events.single.parameters, {
          'entries_bucket': '1-10',
        });
      },
    );

    test('a journal read failure is failed(storage)', () async {
      fakes.journalRepository.failNext(const Failure.storage(), on: 'snapshot');
      final (_, controller, states) = open();
      await controller.export();
      expect(states.last, const ExportState.failed(ErrorKind.storage));
      expect(fakes.analytics.events.single.parameters, {
        'entries_bucket': '0',
        'error': 'storage',
      });
    });

    test('a share failure logs share_failed; unknown otherwise', () async {
      fakes.files.failNext(const Failure.network(), on: 'share');
      final (_, controller, states) = open();
      await controller.export();
      expect(states.last, const ExportState.failed(ErrorKind.network));
      expect(fakes.analytics.events.single.parameters['error'], 'share_failed');
    });

    test(
      'a second tap while busy is ignored; closing drops the result',
      () async {
        final (container, controller, _) = open();
        final first = controller.export();
        await controller.export();
        container.dispose();
        await first;
        expect(fakes.files.shared, hasLength(1));
      },
    );

    test('an unexpected failure before the share is unknown', () async {
      fakes.journalRepository.failNext(
        const Failure.network(),
        on: 'snapshot',
      );
      final (_, controller, _) = open();
      await controller.export();
      expect(fakes.analytics.events.single.parameters['error'], 'unknown');
    });
  });

  group('ImportController (S25)', () {
    (ProviderContainer, ImportController, ImportState Function()) open() {
      final container = fakes.container()
        ..listen(importControllerProvider, (_, _) {});
      return (
        container,
        container.read(importControllerProvider.notifier),
        () => container.read(importControllerProvider),
      );
    }

    Uint8List backupBytes() => aBackup()
        .withReadings([aReading().withId(_importedId.value).build()])
        .withDailyCards([aDailyCard().on('2026-09-01').build()])
        .bytes();

    test('picking; a cancelled picker stays; a valid file previews', () async {
      final (_, controller, read) = open();
      expect(read(), const ImportState.picking());
      await controller.pick();
      expect(read(), const ImportState.picking());
      fakes.files.willPick(backupBytes());
      await controller.pick();
      final preview = read() as ImportPreviewing;
      expect(preview.preview.readings, 1);
      expect(preview.preview.dailyCards, 1);
      expect(preview.mode, MergeMode.merge);
    });

    test('merge imports; import_completed', () async {
      fakes.files.willPick(backupBytes());
      final (_, controller, read) = open();
      await controller.pick();
      await controller.confirm();
      expect(
        read(),
        isA<ImportDone>()
            .having((s) => s.readings, 'readings', 1)
            .having((s) => s.dailyCards, 'dailyCards', 1),
      );
      expect(fakes.journal.readings, contains(_importedId));
      expect(fakes.analytics.events.single.parameters, {
        'mode': 'merge',
        'entries_bucket': '1-10',
        'schema_version': 1,
      });
    });

    test('replace asks first; cancel returns; confirm replaces', () async {
      fakes.files.willPick(backupBytes());
      final (_, controller, read) = open();
      await controller.pick();
      controller.setMode(MergeMode.replace);
      expect((read() as ImportPreviewing).mode, MergeMode.replace);
      await controller.confirm();
      expect(
        read(),
        isA<ImportConfirmReplace>().having((s) => s.localEntries, 'n', 2),
      );
      controller.cancelReplace();
      expect((read() as ImportPreviewing).mode, MergeMode.replace);
      await controller.confirm();
      await controller.confirmReplace();
      expect(read(), isA<ImportDone>());
      expect(fakes.journal.readings.keys, [_importedId]);
      expect(
        fakes.analytics.events.single.parameters['mode'],
        'replace',
      );
    });

    test('invalid(reason) for each validator failure; import_failed', () async {
      final cases = <Uint8List, ImportInvalidReason>{
        Uint8List.fromList(utf8.encode('not json')):
            ImportInvalidReason.notTaro,
        aBackup().withVersion(2).bytes(): ImportInvalidReason.newerVersion,
        aBackup().withChecksum('0' * 64).bytes(): ImportInvalidReason.corrupt,
      };
      for (final MapEntry(key: bytes, value: reason) in cases.entries) {
        fakes.files.willPick(bytes);
        final (container, controller, read) = open();
        await controller.pick();
        expect(read(), ImportState.invalid(reason));
        controller.reset();
        expect(read(), const ImportState.picking());
        container.dispose();
      }
      expect(
        fakes.analytics.events.map((e) => e.parameters['reason']),
        ['not_taro', 'newer_version', 'corrupt'],
      );
    });

    test('reason mapping', () {
      expect(
        ImportInvalidReason.of(BackupInvalidReason.wrongFormat),
        ImportInvalidReason.notTaro,
      );
      expect(
        ImportInvalidReason.of(BackupInvalidReason.schema),
        ImportInvalidReason.corrupt,
      );
      expect(
        ImportInvalidReason.of(BackupInvalidReason.tooLarge),
        ImportInvalidReason.tooLarge,
      );
      expect(
        ImportInvalidReason.tooLarge.analytics,
        ImportFailureReason.tooLarge,
      );
    });

    test('picker, content and write failures are failed', () async {
      fakes.files.failNext(const Failure.storage(), on: 'pickJson');
      var (container, controller, read) = open();
      await controller.pick();
      expect(read(), const ImportState.failed(ErrorKind.storage));
      container.dispose();

      fakes
        ..files.willPick(backupBytes())
        ..content.failNext(const Failure.storage(), on: 'deck');
      (container, controller, read) = open();
      await controller.pick();
      expect(read(), const ImportState.failed(ErrorKind.storage));
      container.dispose();

      fakes
        ..files.willPick(backupBytes())
        ..journalRepository.failNext(const Failure.storage(), on: 'replaceAll');
      (container, controller, read) = open();
      await controller.pick();
      await controller.confirm();
      expect(read(), const ImportState.failed(ErrorKind.storage));
      expect(
        fakes.analytics.events.map((e) => e.parameters['reason']).toSet(),
        {'storage'},
      );
    });

    test('actions out of order are ignored', () async {
      final (_, controller, read) = open();
      controller
        ..setMode(MergeMode.replace)
        ..cancelReplace();
      await controller.confirm();
      await controller.confirmReplace();
      expect(read(), const ImportState.picking());
    });

    test('a failed local count still asks with 0 entries', () async {
      fakes.files.willPick(backupBytes());
      final (_, controller, read) = open();
      await controller.pick();
      controller.setMode(MergeMode.replace);
      fakes.journalRepository.failNext(const Failure.storage(), on: 'snapshot');
      await controller.confirm();
      expect((read() as ImportConfirmReplace).localEntries, 0);
    });
  });
}
