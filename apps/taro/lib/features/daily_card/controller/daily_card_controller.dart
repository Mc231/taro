import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'daily_card_controller.freezed.dart';

/// Today's card with its authored text (01 §7.6).
@freezed
abstract class DailyCardView with _$DailyCardView {
  /// Creates a view.
  const factory DailyCardView({
    required DailyCard card,
    required CardText text,
    required DeckCard deckCard,
  }) = _DailyCardView;

  const DailyCardView._();

  /// The three keywords for the drawn orientation.
  List<String> get keywords =>
      text.keywords(reversed: card.reversed).take(3).toList(growable: false);

  /// The authored short meaning.
  String get shortMeaning => text.short(reversed: card.reversed);

  /// One authored reflection question.
  String? get reflectionQuestion =>
      text.reflectionQuestions.isEmpty ? null : text.reflectionQuestions.first;
}

/// Where "Reflect deeper with AI" goes (PR4): S07 on the `single` spread
/// with this card pre-set; the gate and the hold still apply.
@freezed
abstract class DailyCardDeeper with _$DailyCardDeeper {
  /// Creates the target.
  const factory DailyCardDeeper({
    required SpreadId spreadId,
    required CardId cardId,
    required bool reversed,
  }) = _DailyCardDeeper;
}

/// S13 Daily card (01 §8.3).
@freezed
sealed class DailyCardState with _$DailyCardState {
  /// Reading today's card from the journal.
  const factory DailyCardState.loading() = DailyCardLoading;

  /// Not drawn today: the tap-to-reveal card back.
  const factory DailyCardState.notDrawn() = DailyCardNotDrawn;

  /// The single flip is running (CSPRNG draw).
  const factory DailyCardState.revealing() = DailyCardRevealing;

  /// Today's card.
  const factory DailyCardState.drawn(DailyCardView view) = DailyCardDrawn;

  /// The note editor is open.
  const factory DailyCardState.noteEditing(DailyCardView view) =
      DailyCardNoteEditing;

  /// After the first-ever reveal, once: "Would you like a gentle daily
  /// reminder?" [Yes, remind me] [No thanks] (01 §7.7).
  const factory DailyCardState.reminderOffer(DailyCardView view) =
      DailyCardReminderOffer;

  /// The journal or the bundled content could not be read.
  const factory DailyCardState.failed(Failure failure) = DailyCardFailed;
}

/// S13: one CSPRNG card per install-local day, persisted as a journal
/// entry; the same day shows the same card.
final class DailyCardController extends Notifier<DailyCardState> {
  /// The note limit (01 §7.8, backup schema `note.maxLength`).
  static const int noteMaxLength = BackupSchemaV1.noteMaxLength;

  /// The spread "Reflect deeper" opens.
  static const SpreadId deeperSpread = SpreadId('single');

  @override
  DailyCardState build() {
    final cards = ref.watch(dailyCardRepositoryProvider);
    final subscription = cards.watchToday().listen(_onCard);
    ref.onDispose(subscription.cancel);
    return const DailyCardState.loading();
  }

  DailyCardView? get _view => switch (state) {
    DailyCardDrawn(:final view) ||
    DailyCardNoteEditing(:final view) ||
    DailyCardReminderOffer(:final view) => view,
    _ => null,
  };

  Future<void> _onCard(DailyCard? card) async {
    if (!ref.mounted || state is DailyCardRevealing) return;
    if (card == null) {
      state = const DailyCardState.notDrawn();
      return;
    }
    final loaded = await _load(card);
    if (!ref.mounted || state is DailyCardRevealing) return;
    switch (loaded) {
      case Err(:final failure):
        state = DailyCardState.failed(failure);
      case Ok(value: final view):
        state = switch (state) {
          DailyCardNoteEditing() => DailyCardState.noteEditing(view),
          DailyCardReminderOffer() => DailyCardState.reminderOffer(view),
          _ => DailyCardState.drawn(view),
        };
    }
  }

  Future<Result<DailyCardView>> _load(DailyCard card) async {
    final content = ref.read(contentRepositoryProvider);
    final text = await content.cardText(
      card.cardId,
      ref.read(appLocaleProvider)(),
    );
    final deck = await content.deck();
    return text.then(
      (t) async => deck.then((d) async {
        final deckCard = d.card(card.cardId);
        return deckCard == null
            ? const Result.err(Failure.storage())
            : Result.ok(DailyCardView(card: card, text: t, deckCard: deckCard));
      }),
    );
  }

  /// The tap-to-reveal flip.
  Future<void> reveal() async {
    if (state is! DailyCardNotDrawn) return;
    state = const DailyCardState.revealing();
    final drawn = await ref.read(dailyCardRepositoryProvider).drawToday();
    if (!ref.mounted) return;
    final loaded = await drawn.then(_load);
    if (!ref.mounted) return;
    switch (loaded) {
      case Err(:final failure):
        state = DailyCardState.failed(failure);
      case Ok(value: final view):
        await _revealed(view);
    }
  }

  Future<void> _revealed(DailyCardView view) async {
    final snapshot = await ref.read(journalRepositoryProvider).snapshot();
    if (!ref.mounted) return;
    final dates = {
      for (final c in snapshot.valueOrNull?.dailyCards ?? const <DailyCard>[])
        c.localDate,
    }..add(view.card.localDate);
    var streak = 0;
    while (dates.contains(LocalDates.addDays(view.card.localDate, -streak))) {
      streak++;
    }
    final firstEver = dates.length == 1;
    final reminderOff = !ref
        .read(settingsRepositoryProvider)
        .current
        .reminder
        .enabled;
    state = firstEver && reminderOff
        ? DailyCardState.reminderOffer(view)
        : DailyCardState.drawn(view);
    await ref
        .read(analyticsServiceProvider)
        .log(
          DailyCardRevealedEvent(
            reversed: view.card.reversed,
            arcana: view.deckCard.arcana,
            streakDays: streak,
          ),
        );
  }

  /// The reminder offer was answered; the OS prompt only follows **Yes**.
  Future<void> answerReminderOffer({required bool accepted}) async {
    final view = _view;
    if (state is! DailyCardReminderOffer || view == null) return;
    state = DailyCardState.drawn(view);
    final analytics = ref.read(analyticsServiceProvider);
    final reminders = ref.read(reminderSchedulerProvider);
    final settings = ref.read(settingsRepositoryProvider);
    final locale = ref.read(appLocaleProvider)();
    await analytics.log(ReminderOfferAnsweredEvent(accepted: accepted));
    if (!accepted) return;
    final granted = await reminders.requestPermission();
    await analytics.log(NotificationPermissionResultEvent(granted: granted));
    if (!granted) return;
    final saved = await settings.update(
      (s) => s.copyWith(reminder: s.reminder.copyWith(enabled: true)),
    );
    if (saved case Ok(:final value)) {
      await reminders.schedule(value.reminder, locale);
      await analytics.log(
        ReminderChangedEvent(enabled: true, hour: value.reminder.hour),
      );
    }
  }

  /// "Add a note": the editor opens.
  void editNote() {
    final view = _view;
    if (view != null) state = DailyCardState.noteEditing(view);
  }

  /// The editor closed without saving.
  void cancelNote() {
    final view = _view;
    if (view != null) state = DailyCardState.drawn(view);
  }

  /// Saves the note (empty clears it; ≤ 5,000 characters).
  Future<Result<void>> saveNote(String note) async {
    final view = _view;
    if (view == null) return const Result.ok(null);
    final limited = QuestionPrecheck.limit(
      note.trim(),
      maxChars: noteMaxLength,
    );
    final value = limited.isEmpty ? null : limited;
    final saved = await ref
        .read(dailyCardRepositoryProvider)
        .setNote(view.card.localDate, value);
    if (!ref.mounted) return saved;
    if (saved.isOk) {
      state = DailyCardState.drawn(
        view.copyWith(card: view.card.copyWith(note: value)),
      );
      await ref
          .read(analyticsServiceProvider)
          .log(
            JournalNoteSavedEvent(
              entryType: JournalEntryType.daily,
              noteLenBucket: NoteLengthBucket.fromLength(limited.length),
            ),
          );
    }
    return saved;
  }

  /// Favourite on/off.
  Future<Result<void>> toggleFavourite() async {
    final view = _view;
    if (view == null) return const Result.ok(null);
    final on = !view.card.favourite;
    final saved = await ref
        .read(dailyCardRepositoryProvider)
        .setFavourite(view.card.localDate, favourite: on);
    if (saved.isOk) {
      await ref
          .read(analyticsServiceProvider)
          .log(
            JournalFavouriteToggledEvent(
              entryType: JournalEntryType.daily,
              on: on,
            ),
          );
    }
    return saved;
  }

  /// "Reflect deeper with AI" (PR4): where S07 opens; `null` before the
  /// card is drawn.
  DailyCardDeeper? reflectDeeper() {
    final view = _view;
    if (view == null) return null;
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .log(const DailyCardDeeperTappedEvent()),
    );
    return DailyCardDeeper(
      spreadId: deeperSpread,
      cardId: view.card.cardId,
      reversed: view.card.reversed,
    );
  }
}

/// S13 (`dailyCardControllerProvider`).
final NotifierProvider<DailyCardController, DailyCardState>
dailyCardControllerProvider = NotifierProvider.autoDispose(
  DailyCardController.new,
);
