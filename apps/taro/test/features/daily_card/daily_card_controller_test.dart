import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/daily_card/controller/daily_card_controller.dart';
import 'package:taro_core/taro_core.dart';

import '../feature_test_support.dart';

void main() {
  late TaroFakes fakes;

  setUp(() => fakes = TaroFakes());

  Future<(StateLog<DailyCardState>, DailyCardController)> open() async {
    final container = fakes.container();
    final log = StateLog(container, dailyCardControllerProvider);
    await pumpEventQueue();
    return (log, container.read(dailyCardControllerProvider.notifier));
  }

  DailyCardView viewOf(DailyCardState state) => switch (state) {
    DailyCardDrawn(:final view) ||
    DailyCardNoteEditing(:final view) ||
    DailyCardReminderOffer(:final view) => view,
    _ => throw StateError('no view in $state'),
  };

  test('loading → notDrawn → revealing → reminderOffer (first ever)', () async {
    final container = fakes.container();
    final log = StateLog(container, dailyCardControllerProvider);
    expect(log.last, isA<DailyCardLoading>());
    await pumpEventQueue();
    expect(log.last, isA<DailyCardNotDrawn>());
    await container.read(dailyCardControllerProvider.notifier).reveal();
    await pumpEventQueue();
    expect(log.states, contains(isA<DailyCardRevealing>()));
    final offer = log.last as DailyCardReminderOffer;
    expect(offer.view.keywords.length, lessThanOrEqualTo(3));
    expect(offer.view.shortMeaning, isNotEmpty);
    expect(offer.view.reflectionQuestion, isNotNull);
    final revealed = eventsOf<DailyCardRevealedEvent>(fakes).single;
    expect(revealed.streakDays, 1);
    expect(revealed.arcana, offer.view.deckCard.arcana);
  });

  test('the same day shows the same card; a streak is counted', () async {
    final yesterday = LocalDates.addDays(fakes.clock.localDate, -1);
    fakes.journal.putDailyCard(
      aDailyCard().build().copyWith(localDate: yesterday),
    );
    final (log, controller) = await open();
    await controller.reveal();
    await pumpEventQueue();
    final drawn = log.last as DailyCardDrawn;
    expect(eventsOf<DailyCardRevealedEvent>(fakes).single.streakDays, 2);
    await controller.reveal();
    final (again, _) = await open();
    expect(viewOf(again.last).card, drawn.view.card);
  });

  test('reminder offer: Yes → permission → scheduled', () async {
    final (log, controller) = await open();
    await controller.reveal();
    await pumpEventQueue();
    await controller.answerReminderOffer(accepted: true);
    expect(log.last, isA<DailyCardDrawn>());
    expect(fakes.reminders.scheduled?.$1.enabled, isTrue);
    expect(fakes.settings.current.reminder.enabled, isTrue);
    expect(eventsOf<ReminderOfferAnsweredEvent>(fakes).single.accepted, isTrue);
    expect(
      eventsOf<NotificationPermissionResultEvent>(fakes).single.granted,
      isTrue,
    );
    expect(eventsOf<ReminderChangedEvent>(fakes).single.hour, 9);
    await controller.answerReminderOffer(accepted: true);
    expect(eventsOf<ReminderOfferAnsweredEvent>(fakes), hasLength(1));
  });

  test('reminder offer: permission denied, and No thanks', () async {
    fakes.reminders.permission = false;
    final (log, controller) = await open();
    await controller.reveal();
    await pumpEventQueue();
    await controller.answerReminderOffer(accepted: true);
    expect(fakes.reminders.scheduled, isNull);
    expect(
      eventsOf<NotificationPermissionResultEvent>(fakes).single.granted,
      isFalse,
    );

    fakes = TaroFakes();
    final (_, other) = await open();
    await other.reveal();
    await pumpEventQueue();
    await other.answerReminderOffer(accepted: false);
    expect(fakes.reminders.permissionRequests, 0);
    expect(log.last, isA<DailyCardDrawn>());
  });

  test('a failed settings write schedules nothing', () async {
    final (_, controller) = await open();
    await controller.reveal();
    await pumpEventQueue();
    fakes.settings.failNext(const Failure.storage());
    await controller.answerReminderOffer(accepted: true);
    expect(fakes.reminders.scheduled, isNull);
  });

  test('no offer when the reminder is already on', () async {
    fakes.journal.putSettings(
      const UserSettings(reminder: ReminderSettings(enabled: true)),
    );
    final (log, controller) = await open();
    await controller.reveal();
    await pumpEventQueue();
    expect(log.last, isA<DailyCardDrawn>());
  });

  test('noteEditing → saved; cancel; empty clears', () async {
    await fakes.dailyCards.drawToday();
    final (log, controller) = await open();
    controller.editNote();
    expect(log.last, isA<DailyCardNoteEditing>());
    fakes.journal.notify();
    await pumpEventQueue();
    expect(log.last, isA<DailyCardNoteEditing>());
    await controller.saveNote('  A calm morning.  ');
    await pumpEventQueue();
    expect(viewOf(log.last).card.note, 'A calm morning.');
    expect(log.last, isA<DailyCardDrawn>());
    expect(
      eventsOf<JournalNoteSavedEvent>(fakes).single.entryType,
      JournalEntryType.daily,
    );
    controller
      ..editNote()
      ..cancelNote();
    expect(log.last, isA<DailyCardDrawn>());
    await controller.saveNote('   ');
    await pumpEventQueue();
    expect(viewOf(log.last).card.note, isNull);
  });

  test('a failed note write keeps the editor open', () async {
    await fakes.dailyCards.drawToday();
    final (log, controller) = await open();
    controller.editNote();
    fakes.dailyCards.failNext(const Failure.storage());
    final saved = await controller.saveNote('x');
    expect(saved.isOk, isFalse);
    expect(log.last, isA<DailyCardNoteEditing>());
  });

  test('favourite and Reflect deeper', () async {
    await fakes.dailyCards.drawToday();
    final (log, controller) = await open();
    await controller.toggleFavourite();
    await pumpEventQueue();
    expect(viewOf(log.last).card.favourite, isTrue);
    expect(eventsOf<JournalFavouriteToggledEvent>(fakes).single.on, isTrue);
    final deeper = controller.reflectDeeper()!;
    expect(deeper.spreadId, const SpreadId('single'));
    expect(deeper.cardId, viewOf(log.last).card.cardId);
    await pumpEventQueue();
    expect(eventsOf<DailyCardDeeperTappedEvent>(fakes), hasLength(1));
  });

  test('actions before the card is drawn do nothing', () async {
    final (log, controller) = await open();
    controller
      ..editNote()
      ..cancelNote();
    expect((await controller.saveNote('x')).isOk, isTrue);
    expect((await controller.toggleFavourite()).isOk, isTrue);
    expect(controller.reflectDeeper(), isNull);
    await controller.answerReminderOffer(accepted: true);
    expect(log.last, isA<DailyCardNotDrawn>());
    expect(fakes.analytics.events, isEmpty);
  });

  test('failed draws and unreadable content', () async {
    fakes.dailyCards.failNext(const Failure.storage());
    final (log, controller) = await open();
    await controller.reveal();
    expect(log.last, isA<DailyCardFailed>());

    fakes = TaroFakes();
    await fakes.dailyCards.drawToday();
    fakes.content.failNext(const Failure.storage(), on: 'cardText');
    final (failed, _) = await open();
    expect(failed.last, isA<DailyCardFailed>());

    fakes = TaroFakes();
    await fakes.dailyCards.drawToday();
    fakes.content.bundledDeck = aDeck().build().copyWith(cards: const []);
    final (missing, _) = await open();
    expect(missing.last, isA<DailyCardFailed>());
  });
}
