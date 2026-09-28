import 'package:test/test.dart';

import 'logic_support.dart';

DateTime _t(int hour) => DateTime.utc(2026, 9, 25, hour);

Draw _draw({int version = 3, String card = 'major_16'}) => Draw(
  spreadId: const SpreadId('single'),
  spreadVersion: version,
  cards: [
    DrawnCard(
      positionId: const PositionId('focus'),
      cardId: CardId(card),
      reversed: false,
    ),
  ],
  drawnAt: _t(1),
);

Reading _reading(
  String id, {
  int updated = 7,
  String? note,
  bool favourite = false,
  ReadingStatus status = const ReadingStatus.complete(),
  Draw? draw,
  String? modelId,
  ChargeSource? chargeSource,
  bool deliveryAcked = false,
}) => Reading(
  id: ReadingId(id),
  createdAt: _t(1),
  updatedAt: _t(updated),
  localDate: '2026-09-25',
  draw: draw ?? _draw(),
  status: status,
  contentLocale: 'en',
  note: note,
  favourite: favourite,
  modelId: modelId,
  chargeSource: chargeSource,
  deliveryAcked: deliveryAcked,
);

DailyCard _daily(
  String localDate, {
  int updated = 7,
  String? note,
  bool favourite = false,
}) => DailyCard(
  localDate: localDate,
  cardId: const CardId('major_17'),
  reversed: false,
  drawnAt: _t(1),
  createdAt: _t(1),
  updatedAt: _t(updated),
  note: note,
  favourite: favourite,
);

const _localSettings = UserSettings(
  themeMode: ThemeMode.light,
  reduceMotion: true,
);
const _fileSettings = UserSettings(
  themeMode: ThemeMode.dark,
  hapticsEnabled: false,
);

MergeResult _run(
  MergeMode mode, {
  List<Reading> local = const [],
  List<Reading> incoming = const [],
  List<DailyCard> localDaily = const [],
  List<DailyCard> incomingDaily = const [],
}) => BackupMerge.merge(
  localSettings: _localSettings,
  localReadings: local,
  localDailyCards: localDaily,
  incoming: BackupData(
    settings: _fileSettings,
    readings: incoming,
    dailyCards: incomingDaily,
  ),
  mode: mode,
);

void main() {
  group('BackupMerge merge: reading conflict table (01 §7.11)', () {
    // (case, local, incoming, expected merged reading or null for
    // "unchanged", expected report)
    final table = <(String, Reading, Reading, Reading?, MergeReport)>[
      (
        'file newer → file wins',
        _reading('a', updated: 8),
        _reading('a', updated: 9, favourite: true),
        _reading('a', updated: 9, favourite: true),
        const MergeReport(updated: 1),
      ),
      (
        'file older → local kept',
        _reading('a', updated: 9, favourite: true),
        _reading('a', updated: 8),
        null,
        const MergeReport(skipped: 1),
      ),
      (
        'same updatedAt → local kept',
        _reading('a', favourite: true),
        _reading('a'),
        null,
        const MergeReport(skipped: 1),
      ),
      (
        'identical → skipped',
        _reading('a', note: 'n'),
        _reading('a', note: 'n'),
        null,
        const MergeReport(skipped: 1),
      ),
      (
        'file newer, local note longer → file wins with local note',
        _reading('a', updated: 8, note: 'a long local note'),
        _reading('a', updated: 9, note: 'short', favourite: true),
        _reading('a', updated: 9, note: 'a long local note', favourite: true),
        const MergeReport(updated: 1),
      ),
      (
        'file newer, file note longer → file note',
        _reading('a', updated: 8, note: 'short'),
        _reading('a', updated: 9, note: 'a longer file note'),
        _reading('a', updated: 9, note: 'a longer file note'),
        const MergeReport(updated: 1),
      ),
      (
        'file older but note longer → local with file note',
        _reading('a', updated: 9, note: 'short', favourite: true),
        _reading('a', updated: 8, note: 'the longer, older note'),
        _reading(
          'a',
          updated: 9,
          note: 'the longer, older note',
          favourite: true,
        ),
        const MergeReport(updated: 1),
      ),
      (
        'file newer, local note but none in file → note kept',
        _reading('a', updated: 8, note: 'keep me'),
        _reading('a', updated: 9),
        _reading('a', updated: 9, note: 'keep me'),
        const MergeReport(updated: 1),
      ),
      (
        'notes of equal length differ → winner note',
        _reading('a', updated: 8, note: 'aaaa'),
        _reading('a', updated: 9, note: 'bbbb'),
        _reading('a', updated: 9, note: 'bbbb'),
        const MergeReport(updated: 1),
      ),
      (
        'file newer keeps local device-only fields',
        _reading(
          'a',
          updated: 8,
          status: const ReadingStatus.pending(),
          draw: _draw(version: 7),
          modelId: 'claude-sonnet-5',
          chargeSource: ChargeSource.paid,
          deliveryAcked: true,
        ),
        _reading('a', updated: 9, draw: _draw(version: 1, card: 'cups_02')),
        _reading(
          'a',
          updated: 9,
          draw: _draw(version: 7),
          modelId: 'claude-sonnet-5',
          chargeSource: ChargeSource.paid,
          deliveryAcked: true,
        ),
        const MergeReport(updated: 1),
      ),
    ];

    for (final (name, local, incoming, expected, report) in table) {
      test(name, () {
        final other = _reading('local-only');
        final r = _run(
          MergeMode.merge,
          local: [local, other],
          incoming: [incoming],
        );
        expect(r.readings, [expected ?? local, other]);
        expect(r.report, report);
        expect(r.settings, _localSettings, reason: 'merge keeps settings');
      });
    }

    test('new readings are added after the journal, in file order', () {
      final r = _run(
        MergeMode.merge,
        local: [_reading('a')],
        incoming: [_reading('c'), _reading('a'), _reading('b')],
      );
      expect([for (final x in r.readings) x.id.value], ['a', 'c', 'b']);
      expect(r.report, const MergeReport(added: 2, skipped: 1));
    });

    test('a duplicate id inside the file merges into the first copy', () {
      final r = _run(
        MergeMode.merge,
        incoming: [_reading('a', updated: 8), _reading('a', updated: 9)],
      );
      expect(r.readings, [_reading('a', updated: 9)]);
      expect(r.report, const MergeReport(added: 1, updated: 1));
    });
  });

  group('BackupMerge merge: daily cards by localDate', () {
    final table = <(String, DailyCard, DailyCard, DailyCard?, MergeReport)>[
      (
        'file newer → file wins',
        _daily('2026-09-25', updated: 8),
        _daily('2026-09-25', updated: 9, favourite: true),
        _daily('2026-09-25', updated: 9, favourite: true),
        const MergeReport(updated: 1),
      ),
      (
        'file older → skipped',
        _daily('2026-09-25', updated: 9),
        _daily('2026-09-25', updated: 8, favourite: true),
        null,
        const MergeReport(skipped: 1),
      ),
      (
        'file newer, local note longer → local note kept',
        _daily('2026-09-25', updated: 8, note: 'long local'),
        _daily('2026-09-25', updated: 9, note: 'x'),
        _daily('2026-09-25', updated: 9, note: 'long local'),
        const MergeReport(updated: 1),
      ),
      (
        'file older, note longer → file note',
        _daily('2026-09-25', updated: 9),
        _daily('2026-09-25', updated: 8, note: 'from the file'),
        _daily('2026-09-25', updated: 9, note: 'from the file'),
        const MergeReport(updated: 1),
      ),
    ];

    for (final (name, local, incoming, expected, report) in table) {
      test(name, () {
        final r = _run(
          MergeMode.merge,
          localDaily: [local],
          incomingDaily: [incoming, _daily('2026-09-24')],
        );
        expect(r.dailyCards, [expected ?? local, _daily('2026-09-24')]);
        expect(r.report, report + const MergeReport(added: 1));
      });
    }

    test('readings and daily cards add up in one report', () {
      final r = _run(
        MergeMode.merge,
        local: [_reading('a')],
        incoming: [_reading('a', updated: 9), _reading('b')],
        localDaily: [_daily('2026-09-25', updated: 9)],
        incomingDaily: [_daily('2026-09-25')],
      );
      expect(r.report, const MergeReport(added: 1, updated: 1, skipped: 1));
    });
  });

  group('BackupMerge replace', () {
    test('the file replaces journal and settings; device-only kept', () {
      final pending = _reading('p', status: const ReadingStatus.pending());
      final failed = _reading(
        'f',
        status: const ReadingStatus.failed(Failure.network()),
      );
      final pendingInFile = _reading(
        'q',
        status: const ReadingStatus.pending(),
      );
      final r = _run(
        MergeMode.replace,
        local: [_reading('a'), pending, failed, pendingInFile, _reading('b')],
        incoming: [_reading('x'), _reading('q', updated: 9)],
        localDaily: [_daily('2026-09-25'), _daily('2026-09-24')],
        incomingDaily: [_daily('2026-09-01')],
      );
      expect([for (final x in r.readings) x.id.value], ['p', 'f', 'x', 'q']);
      expect(r.dailyCards, [_daily('2026-09-01')]);
      expect(
        r.settings,
        _fileSettings.copyWith(reduceMotion: _localSettings.reduceMotion),
      );
      expect(r.report, const MergeReport(added: 3, removed: 5));
    });

    test('an empty journal: only additions', () {
      final r = _run(
        MergeMode.replace,
        incoming: [_reading('x')],
        incomingDaily: [_daily('2026-09-01')],
      );
      expect(r.report, const MergeReport(added: 2));
    });
  });

  test('MergeReport defaults and sum', () {
    expect(const MergeReport().added, 0);
    expect(const MergeReport().removed, 0);
    expect(
      const MergeReport(added: 1, removed: 2) +
          const MergeReport(updated: 3, skipped: 4, removed: 1),
      const MergeReport(added: 1, updated: 3, skipped: 4, removed: 3),
    );
  });
}
