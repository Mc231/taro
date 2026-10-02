import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/share_reading_use_case.dart';
import 'package:taro/features/journal/controller/journal_entry_controller.dart';
import 'package:taro_core/taro_core.dart';

import '../../helpers/pump_app.dart';

const ReadingId _id = ReadingId('r-1');
const JournalEntryKey _readingKey = JournalEntryKey.reading(_id);
const JournalEntryKey _dailyKey = JournalEntryKey.dailyCard('2026-09-21');

void main() {
  late TaroFakes fakes;

  setUp(() {
    fakes = TaroFakes();
    fakes.journal
      ..putReading(aReading().withId('r-1').withNote('first').build())
      ..putDailyCard(aDailyCard().on('2026-09-21').build());
  });

  (ProviderContainer, JournalEntryController, JournalEntryState Function())
  open([JournalEntryKey key = _readingKey]) {
    final container = fakes.container();
    final provider = journalEntryControllerProvider(key);
    container.listen(provider, (_, _) {});
    return (
      container,
      container.read(provider.notifier),
      () => container.read(provider),
    );
  }

  JournalEntryView viewOf(JournalEntryState state) => switch (state) {
    JournalEntryContent(:final view) ||
    JournalEntryPending(:final view) ||
    JournalEntryFailed(:final view) => view,
    _ => throw StateError('no view in $state'),
  };

  test('loading, then content with the stored note', () async {
    final (_, _, read) = open();
    expect(read(), const JournalEntryState.loading());
    await pumpEventQueue();
    final view = viewOf(read());
    expect(read(), isA<JournalEntryContent>());
    expect(view.note, 'first');
    expect(view.noteStatus, NoteStatus.saved);
    expect(view.canDelete, isTrue);
    expect(view.favourite, isFalse);
  });

  test('pending and failed readings', () async {
    fakes.journal
      ..putReading(aReading().withId('p').pending().build())
      ..putReading(
        aReading()
            .withId('f')
            .failed(const Failure.network(), refunded: true)
            .build(),
      );
    var (container, _, read) = open(
      const JournalEntryKey.reading(ReadingId('p')),
    );
    await pumpEventQueue();
    expect(read(), isA<JournalEntryPending>());
    container.dispose();
    (container, _, read) = open(const JournalEntryKey.reading(ReadingId('f')));
    await pumpEventQueue();
    expect(
      read(),
      isA<JournalEntryFailed>().having((s) => s.refunded, 'refunded', isTrue),
    );
  });

  test('a missing entry is notFound', () async {
    final (_, _, read) = open(
      const JournalEntryKey.reading(ReadingId('nope')),
    );
    await pumpEventQueue();
    expect(read(), const JournalEntryState.notFound());
  });

  testWidgets('note autosave after the pause, clamped to 5,000 chars', (
    tester,
  ) async {
    final (_, controller, read) = open();
    await tester.pump();
    controller.editNote('x' * (kJournalNoteMaxChars + 10));
    expect(viewOf(read()).noteStatus, NoteStatus.editing);
    expect(viewOf(read()).note, hasLength(kJournalNoteMaxChars));
    controller.editNote('x' * (kJournalNoteMaxChars + 20));
    await tester.pump(kJournalNoteAutosaveDelay);
    await tester.pump();
    expect(viewOf(read()).noteStatus, NoteStatus.saved);
    expect(fakes.journal.readings[_id]?.note, hasLength(kJournalNoteMaxChars));
    expect(fakes.analytics.events.single.parameters, {
      'entry_type': 'reading',
      'note_len_bucket': '2001+',
    });
  });

  test('flushNote saves at once; an empty note is cleared', () async {
    final (_, controller, read) = open();
    await pumpEventQueue();
    controller.editNote('   ');
    await controller.flushNote();
    expect(fakes.journal.readings[_id]?.note, isNull);
    expect(viewOf(read()).noteStatus, NoteStatus.saved);
    await controller.flushNote();
    expect(fakes.analytics.events, hasLength(1));
  });

  test('a failed save keeps the draft and retries on flush', () async {
    fakes.readings.failNext(const Failure.storage(), on: 'setNote');
    final (_, controller, read) = open();
    await pumpEventQueue();
    controller.editNote('new text');
    await controller.flushNote();
    expect(viewOf(read()).noteStatus, NoteStatus.failed);
    expect(viewOf(read()).note, 'new text');
    await controller.flushNote();
    expect(fakes.journal.readings[_id]?.note, 'new text');
  });

  test('leaving the screen saves a pending edit', () async {
    final (container, controller, _) = open();
    await pumpEventQueue();
    controller.editNote('saved on leave');
    container.dispose();
    await pumpEventQueue();
    expect(fakes.journal.readings[_id]?.note, 'saved on leave');
  });

  test('favourite toggles and logs', () async {
    final (_, controller, read) = open();
    await pumpEventQueue();
    await controller.toggleFavourite();
    await pumpEventQueue();
    expect(viewOf(read()).favourite, isTrue);
    expect(fakes.analytics.events.single.parameters, {
      'entry_type': 'reading',
      'on': true,
    });
  });

  test('a failed favourite is a storage error', () async {
    fakes.readings.failNext(const Failure.storage(), on: 'setFavourite');
    final (_, controller, read) = open();
    await pumpEventQueue();
    await controller.toggleFavourite();
    expect(read(), const JournalEntryState.storageError());
  });

  test('toggleFavourite before load does nothing', () async {
    final (_, controller, _) = open();
    await controller.toggleFavourite();
    expect(fakes.analytics.events, isEmpty);
  });

  test('delete → deleted with a 5 s undo; undo restores', () async {
    final (_, controller, read) = open();
    await pumpEventQueue();
    await controller.delete();
    await pumpEventQueue();
    expect(
      read(),
      JournalEntryState.deleted(
        undoUntil: fakes.clock.now().add(ReadingRepository.undoWindow),
      ),
    );
    await controller.undo();
    await pumpEventQueue();
    expect(read(), isA<JournalEntryContent>());
    expect(fakes.analytics.events.single.parameters, {
      'entry_type': 'reading',
      'undone': true,
    });
    await controller.undo();
    expect(fakes.analytics.events, hasLength(1));
  });

  test('an undo past the window leaves it deleted', () async {
    final (_, controller, read) = open();
    await pumpEventQueue();
    await controller.delete();
    fakes.clock.advance(ReadingRepository.undoWindow);
    await controller.undo();
    await pumpEventQueue();
    expect(read(), const JournalEntryState.notFound());
    expect(fakes.analytics.events.single.parameters['undone'], isFalse);
  });

  testWidgets('the undo window lapses', (tester) async {
    final (_, controller, read) = open();
    await tester.pump();
    await controller.delete();
    await tester.pump(ReadingRepository.undoWindow);
    expect(read(), const JournalEntryState.notFound());
    expect(fakes.analytics.events.single.parameters['undone'], isFalse);
  });

  test('closing during the window logs not undone', () async {
    final (container, controller, _) = open();
    await pumpEventQueue();
    await controller.delete();
    container.dispose();
    await pumpEventQueue();
    expect(fakes.analytics.events.single.parameters['undone'], isFalse);
  });

  test('a failed delete is a storage error', () async {
    fakes.readings.failNext(const Failure.storage(), on: 'delete');
    final (_, controller, read) = open();
    await pumpEventQueue();
    await controller.delete();
    expect(read(), const JournalEntryState.storageError());
  });

  test('daily card: note, favourite; it cannot be deleted', () async {
    final (_, controller, read) = open(_dailyKey);
    await pumpEventQueue();
    expect(viewOf(read()).canDelete, isFalse);
    expect(viewOf(read()).note, '');
    controller.editNote('a daily thought');
    await controller.flushNote();
    await controller.toggleFavourite();
    await controller.delete();
    await controller.undo();
    await pumpEventQueue();
    final card = fakes.journal.dailyCards['2026-09-21']!;
    expect(card.note, 'a daily thought');
    expect(card.favourite, isTrue);
    expect(viewOf(read()).favourite, isTrue);
    expect(fakes.analytics.events.map((e) => e.parameters['entry_type']), [
      'daily',
      'daily',
    ]);
  });

  test('editing the same text is a no-op', () async {
    final (_, controller, read) = open();
    await pumpEventQueue();
    controller.editNote('first');
    expect(viewOf(read()).noteStatus, NoteStatus.saved);
  });

  test('a classic reading is content', () async {
    fakes.journal.putReading(aReading().withId('c').classic().build());
    final (_, _, read) = open(const JournalEntryKey.reading(ReadingId('c')));
    await pumpEventQueue();
    expect(read(), isA<JournalEntryContent>());
  });

  test(
    'writeAbout adds the prompt as a heading, once, and autosaves',
    () async {
      final (_, controller, read) = open();
      await pumpEventQueue();
      controller.writeAbout('  What helps?  ');
      expect(viewOf(read()).note, 'first\n\nWhat helps?\n\n');
      expect(viewOf(read()).noteStatus, NoteStatus.editing);
      controller
        ..writeAbout('What helps?')
        ..writeAbout('   ');
      expect(viewOf(read()).note, 'first\n\nWhat helps?\n\n');
      await controller.flushNote();
      expect(fakes.journal.readings[_id]!.note, 'first\n\nWhat helps?\n\n');

      final (_, daily, readDaily) = open(_dailyKey);
      await pumpEventQueue();
      daily.writeAbout('Why now?');
      expect(viewOf(readDaily()).note, 'Why now?\n\n');
    },
  );

  test('share: a reading as text, the question only when asked', () async {
    const copy = ShareCopy(
      disclaimerLine: 'For reflection only.',
      questionLabel: 'My question',
      reversedLabel: 'Reversed',
      fallbackTitle: 'Three cards',
    );
    final (_, controller, _) = open();
    await pumpEventQueue();
    expect((await controller.share(copy, includeQuestion: false)).isOk, isTrue);
    expect(fakes.files.shared, hasLength(1));
    expect(
      fakes.analytics.events
          .whereType<ReadingSharedEvent>()
          .single
          .includeQuestion,
      isFalse,
    );
    fakes.files.failNext(const Failure.storage(), on: 'share');
    expect((await controller.share(copy, includeQuestion: true)).isOk, isFalse);
    expect(
      fakes.analytics.events.whereType<ReadingSharedEvent>(),
      hasLength(1),
    );

    final (_, daily, _) = open(_dailyKey);
    await pumpEventQueue();
    expect((await daily.share(copy, includeQuestion: false)).isOk, isTrue);
    expect(fakes.files.shared, hasLength(1));
  });
}
