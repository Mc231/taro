@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/backup/controller/import_controller.dart';
import 'package:taro/features/backup/view/import_screen.dart';
import 'package:taro_core/taro_core.dart' hide ThemeMode;

import 'golden_app_support.dart';

ImportLayout _layout(ImportState state) => ImportLayout(
  state: state,
  onPick: () {},
  onReset: () {},
  onMode: (_) {},
  onConfirm: () {},
  onOpenJournal: () {},
  onBack: () {},
  onUpdateApp: () {},
);

void main() {
  // The canvas samples (docs/design/screens/S25, `Import.dc.html`,
  // `ImportInvalid.dc.html`): 96 readings and 40 daily cards from
  // 12 September 2026.
  final preview = ImportPreview(
    aBackup()
        .exportedAt(DateTime.utc(2026, 9, 12, 10))
        .withReadings([
          for (var i = 0; i < 96; i++)
            aReading()
                .withId(
                  '0c6e2b1e-1111-4222-8333-${i.toString().padLeft(12, '0')}',
                )
                .build(),
        ])
        .withDailyCards([
          for (var i = 0; i < 40; i++)
            aDailyCard()
                .on(
                  '2026-08-${(i % 28 + 1).toString().padLeft(2, '0')}',
                )
                .build(),
        ])
        .build(),
  );

  goldenMatrix(
    's25_import_preview',
    (_) => _layout(ImportState.preview(preview)),
    keyScreen: true,
    accessibility: true,
    largeText: true,
    pump: pumpAppGolden(goldenFakes),
  );

  for (final reason in ImportInvalidReason.values) {
    goldenMatrix(
      's25_import_invalid_${reason.name}',
      (_) => _layout(ImportState.invalid(reason)),
      keyScreen: reason == ImportInvalidReason.notTaro,
      accessibility: reason == ImportInvalidReason.notTaro,
      largeText: reason == ImportInvalidReason.notTaro,
      pump: pumpAppGolden(goldenFakes),
    );
  }
}
