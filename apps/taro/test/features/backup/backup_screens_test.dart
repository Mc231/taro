import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:taro/features/backup/controller/export_controller.dart';
import 'package:taro/features/backup/controller/import_controller.dart';
import 'package:taro/features/backup/view/export_screen.dart';
import 'package:taro/features/backup/view/import_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../skeleton_support.dart';

final ImportPreview _preview = ImportPreview(
  aBackup().withReadings([aReading().build()]).withDailyCards([
    aDailyCard().build(),
  ]).build(),
);

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('en');
    l10n = await enL10n();
  });

  group('S24 export view', () {
    testWidgets('every state', (tester) async {
      var exports = 0;
      var back = 0;
      Future<void> pump(ExportState state) => pumpTaroWidget(
        tester,
        ExportLayout(
          state: state,
          fileName: 'taro-backup-2026-09-27.json',
          onExport: () => exports++,
          onBack: () => back++,
        ),
        size: const Size(430, 1400),
      );
      TaroButton button() => tester.widget<TaroButton>(
        find.widgetWithText(TaroButton, l10n.exportButton).first,
      );
      await pump(const ExportState.idle());
      expect(find.text(l10n.exportBalance), findsOneWidget);
      expect(find.text(l10n.exportConsent), findsOneWidget);
      expect(find.textContaining('taro-backup-2026-09-27.json'), findsOne);
      await tester.tap(find.widgetWithText(TaroButton, l10n.exportButton));
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await pump(const ExportState.preparing());
      expect(
        tester
            .widget<TaroButton>(
              find.widgetWithText(TaroButton, l10n.exportPreparing),
            )
            .onPressed,
        isNull,
      );
      await pump(const ExportState.shareSheetOpen());
      expect(button().onPressed, isNull);
      await pump(const ExportState.done(entries: 2));
      expect(find.text(l10n.exportDoneTitle), findsOneWidget);
      expect(find.text(l10n.exportJournalCount(2)), findsOneWidget);
      await pump(const ExportState.failed(ErrorKind.storage));
      expect(find.text(l10n.exportFailed), findsOneWidget);
      await tapText(tester, l10n.commonRetry);
      expect((exports, back), (2, 1));
    });
  });

  group('S25 import view', () {
    testWidgets('every state', (tester) async {
      final calls = <String>[];
      Future<void> pump(ImportState state, {bool update = true}) =>
          pumpTaroWidget(
            tester,
            ImportLayout(
              state: state,
              onPick: () => calls.add('pick'),
              onReset: () => calls.add('reset'),
              onMode: (m) => calls.add('mode:${m.name}'),
              onConfirm: () => calls.add('confirm'),
              onOpenJournal: () => calls.add('journal'),
              onBack: () => calls.add('back'),
              onUpdateApp: update ? () => calls.add('update') : null,
            ),
            size: const Size(430, 1600),
          );
      await pump(const ImportState.picking());
      await tapText(tester, l10n.importChooseFile);
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await pump(const ImportState.validating());
      expect(find.text(l10n.importValidating), findsOneWidget);
      for (final (reason, text, body) in [
        (
          ImportInvalidReason.notTaro,
          l10n.importInvalidNotTaro,
          l10n.importInvalidNotTaroBody,
        ),
        (
          ImportInvalidReason.newerVersion,
          l10n.importInvalidNewerVersion,
          l10n.importInvalidNewerVersionBody,
        ),
        (
          ImportInvalidReason.corrupt,
          l10n.importInvalidCorrupt,
          l10n.importInvalidCorruptBody,
        ),
        (
          ImportInvalidReason.tooLarge,
          l10n.importInvalidTooLarge,
          l10n.importInvalidTooLargeBody,
        ),
      ]) {
        await pump(ImportState.invalid(reason));
        expect(find.text(text), findsOneWidget);
        expect(find.text(body), findsOneWidget);
        expect(find.text(l10n.importNothingChanged), findsOneWidget);
        expect(
          find.text(l10n.updateButton),
          reason == ImportInvalidReason.newerVersion
              ? findsOneWidget
              : findsNothing,
        );
        if (reason == ImportInvalidReason.newerVersion) {
          await tapText(tester, l10n.updateButton);
        }
      }
      await tapText(tester, l10n.importChooseAnother);
      await tapText(tester, l10n.importBackToSettings);
      await pump(ImportState.preview(_preview));
      expect(find.text(l10n.importSummary(1, 1)), findsOneWidget);
      expect(find.text(l10n.importBalanceNote), findsOneWidget);
      expect(find.text(l10n.importChecked), findsOneWidget);
      await tapText(tester, l10n.importReplace);
      await tapText(tester, l10n.importChooseAnother);
      await tester.tap(find.widgetWithText(TaroButton, l10n.importButton));
      await pump(ImportState.confirmReplace(_preview, localEntries: 4));
      expect(find.text(l10n.importReplace), findsOneWidget);
      await pump(const ImportState.importing(progress: 0.5));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel(l10n.commonBack), findsNothing);
      await pump(
        const ImportState.done(
          summary: MergeReport(),
          readings: 1,
          dailyCards: 1,
        ),
      );
      await tapText(tester, l10n.importOpenJournal);
      await pump(const ImportState.failed(ErrorKind.storage));
      expect(find.text(l10n.importFailed), findsOneWidget);
      await tapText(tester, l10n.commonRetry);
      await pump(
        const ImportState.invalid(ImportInvalidReason.newerVersion),
        update: false,
      );
      expect(find.text(l10n.updateButton), findsNothing);
      expect(calls, [
        'pick',
        'back',
        'update',
        'pick',
        'back',
        'mode:replace',
        'pick',
        'confirm',
        'journal',
        'reset',
      ]);
    });
  });

  group('backup screens with fakes', () {
    late TaroFakes fakes;

    setUp(() {
      fakes = TaroFakes();
      fakes.journal.putReading(aReading().build());
    });

    testWidgets('S24: export shares the file; back', (tester) async {
      await pumpRouted(
        tester,
        const ExportScreen(),
        fakes: fakes,
        pushed: true,
        size: const Size(430, 1400),
      );
      await tester.tap(find.widgetWithText(TaroButton, l10n.exportButton));
      await tester.pumpAndSettle();
      expect(find.text(l10n.exportDoneTitle), findsOneWidget);
      expect(fakes.files.shared, hasLength(1));
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await tester.pumpAndSettle();
      expectRoute('/');
    });

    testWidgets('S25: pick, replace (cancel, confirm), open journal', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const ImportScreen(),
        fakes: fakes,
        pushed: true,
        size: const Size(430, 1400),
      );
      fakes.files.willPick(aBackup().withReadings([]).bytes());
      await tapText(tester, l10n.importChooseFile);
      await tapText(tester, l10n.importChooseAnother);
      fakes.files.willPick(
        aBackup().withReadings([
          aReading().withId('0c6e2b1e-1111-4222-8333-000000000001').build(),
        ]).bytes(),
      );
      await tapText(tester, l10n.importChooseFile);
      await tapText(tester, l10n.importReplace);
      await tapText(tester, l10n.importButton);
      expect(find.text(l10n.importConfirmReplaceBody(1)), findsOneWidget);
      await tapText(tester, l10n.commonCancel);
      await tapText(tester, l10n.importButton);
      await tapText(tester, l10n.importConfirmReplaceAction);
      await tapText(tester, l10n.importOpenJournal);
      expectRoute('/journal');
    });

    testWidgets('S25: back pops', (tester) async {
      await pumpRouted(
        tester,
        const ImportScreen(),
        fakes: fakes,
        pushed: true,
      );
      await tester.tap(find.bySemanticsLabel(l10n.commonBack));
      await tester.pumpAndSettle();
      expectRoute('/');
    });
  });
}
