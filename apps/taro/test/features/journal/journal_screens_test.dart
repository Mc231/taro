import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:taro/features/journal/controller/journal_entry_controller.dart';
import 'package:taro/features/journal/view/journal_labels.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../skeleton_support.dart';

final Reading _failed = aReading()
    .withId('r-failed')
    .failed(const Failure.server(status: 500), refunded: true)
    .withQuestion(null)
    .build();
final DailyCard _daily = aDailyCard()
    .on('2026-09-25')
    .withNote('n')
    .favourite()
    .build();

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('en');
    l10n = await enL10n();
  });

  group('JournalLabels', () {
    test('keys, titles, statuses and locations', () {
      expect(
        JournalLabels.keyOf('2026-09-25'),
        const JournalEntryKey.dailyCard('2026-09-25'),
      );
      expect(
        JournalLabels.keyOf('r1'),
        const JournalEntryKey.reading(ReadingId('r1')),
      );
      expect(
        JournalLabels.title(l10n, JournalItem.reading(_failed)),
        l10n.spread_three_ppf_name,
      );
      expect(
        JournalLabels.title(l10n, JournalItem.dailyCard(_daily)),
        l10n.commonDailyCard,
      );
      expect(
        JournalLabels.location(JournalItem.dailyCard(_daily)),
        '/journal/2026-09-25',
      );
      expect(
        JournalLabels.finishLocation(const ReadingId('r1')),
        '/reading/draw?resume=r1',
      );
      for (final status in JournalEntryTileStatus.values) {
        expect(JournalLabels.statusLabel(l10n, status), isNotEmpty);
      }
      expect(
        JournalLabels.status(
          JournalItem.reading(aReading().refused().build()),
        ),
        JournalEntryTileStatus.ai,
      );
      expect(JournalLabels.month(l10n, '2026-09'), 'September 2026');
      expect(
        RoutePaths.journalEntry('r1', prompt: 'Why now?'),
        '/journal/r1?prompt=Why+now%3F',
      );
      expect(RoutePaths.journalEntry('r1'), '/journal/r1');
      expect(RoutePaths.journalWithCard('major_17'), '/journal?card=major_17');
    });
  });
}
