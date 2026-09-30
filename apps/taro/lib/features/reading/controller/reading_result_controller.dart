import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/reading/share/share_reading_use_case.dart';
import 'package:taro_core/taro_core.dart';

part 'reading_result_controller.freezed.dart';

/// What S09 opens: the reading and where it was opened from
/// (`reading_viewed.origin`).
@freezed
abstract class ReadingResultArgs with _$ReadingResultArgs {
  /// Creates the arguments.
  const factory ReadingResultArgs({
    required ReadingId id,
    @Default(ReadingViewOrigin.fresh) ReadingViewOrigin origin,
  }) = _ReadingResultArgs;
}

/// The stored reading with its localized card texts (01 §7.4).
@freezed
abstract class ReadingResultView with _$ReadingResultView {
  /// Creates a view.
  const factory ReadingResultView({
    required Reading reading,
    required Map<CardId, CardText> cardTexts,
  }) = _ReadingResultView;

  const ReadingResultView._();

  /// Whether the menu offers "Report this reading" (S33, AI readings only,
  /// RC72); a reported reading shows "Reported" instead.
  bool get canReport => ReportReading.canReport(reading) && !reading.reported;

  /// Whether the reading was already reported (S33 `alreadyReported`).
  bool get reported => reading.reported;
}

/// S09 Reading result (01 §8.3): the disclaimer footer is rendered in every
/// state by the view.
@freezed
sealed class ReadingResultState with _$ReadingResultState {
  /// Reading the stored reading.
  const factory ReadingResultState.loadingFromStorage() =
      ReadingResultLoadingFromStorage;

  /// The reading, not rated yet.
  const factory ReadingResultState.content(ReadingResultView view) =
      ReadingResultContent;

  /// The reading with the user's rating shown.
  const factory ReadingResultState.ratingGiven(ReadingResultView view) =
      ReadingResultRatingGiven;

  /// The share sheet is being prepared or open.
  const factory ReadingResultState.sharing(ReadingResultView view) =
      ReadingResultSharing;

  /// No such reading (deleted, or a stale link).
  const factory ReadingResultState.notFound() = ReadingResultNotFound;

  /// The card texts could not be read.
  const factory ReadingResultState.failed(Failure failure) =
      ReadingResultFailed;
}

/// S09: follows the stored reading; rating, favourite, reflection prompts
/// and share (PR19). A thumbs-up on an AI reading feeds the in-app review
/// policy (`ReviewPrompter`, 01 §6; Classic readings never count).
final class ReadingResultController extends Notifier<ReadingResultState> {
  /// A controller for [args].
  ReadingResultController(this.args);

  /// The reading and the origin.
  final ReadingResultArgs args;

  final Map<CardId, CardText> _texts = {};
  Reading? _reading;
  bool _viewed = false;
  bool _sharing = false;

  @override
  ReadingResultState build() {
    final readings = ref.watch(readingRepositoryProvider);
    final subscription = readings.watch(args.id).listen(_onReading);
    ref.onDispose(subscription.cancel);
    return const ReadingResultState.loadingFromStorage();
  }

  Future<void> _onReading(Reading? reading) async {
    if (!ref.mounted) return;
    if (reading == null) {
      _reading = null;
      state = const ReadingResultState.notFound();
      return;
    }
    final locale = ref.read(appLocaleProvider)();
    final content = ref.read(contentRepositoryProvider);
    for (final card in reading.cards) {
      if (_texts.containsKey(card.cardId)) continue;
      final text = await content.cardText(card.cardId, locale);
      if (!ref.mounted) return;
      switch (text) {
        case Ok(:final value):
          _texts[card.cardId] = value;
        case Err(:final failure):
          state = ReadingResultState.failed(failure);
          return;
      }
    }
    _reading = reading;
    state = _stateFor(reading);
    if (!_viewed) {
      _viewed = true;
      await ref
          .read(analyticsServiceProvider)
          .log(
            ReadingViewedEvent(
              spread: AnalyticsSpread.fromId(reading.spreadId),
              origin: args.origin,
            ),
          );
    }
  }

  ReadingResultState _stateFor(Reading reading) {
    final view = ReadingResultView(
      reading: reading,
      cardTexts: Map.unmodifiable(_texts),
    );
    if (_sharing) return ReadingResultState.sharing(view);
    return reading.rating == null
        ? ReadingResultState.content(view)
        : ReadingResultState.ratingGiven(view);
  }

  /// 👍 / 👎 with an optional reason on 👎 (no free text).
  Future<Result<void>> rate(Rating rating, {RatingReason? reason}) async {
    final reading = _reading;
    if (reading == null) return const Result.ok(null);
    final saved = await ref
        .read(readingRepositoryProvider)
        .setRating(
          reading.id,
          rating,
          reason: rating == Rating.down ? reason : null,
        );
    if (saved.isOk) {
      await ref
          .read(analyticsServiceProvider)
          .log(
            ReadingRatedEvent(
              spread: AnalyticsSpread.fromId(reading.spreadId),
              rating: rating,
              reason: rating == Rating.down ? reason : null,
            ),
          );
      if (rating == Rating.up && reading.status is ReadingStatusComplete) {
        await ref
            .read(reviewPrompterProvider)
            .maybePrompt(ReviewTrigger.positiveRating);
      }
    }
    return saved;
  }

  /// Favourite on/off.
  Future<Result<void>> toggleFavourite() async {
    final reading = _reading;
    if (reading == null) return const Result.ok(null);
    final on = !reading.favourite;
    final saved = await ref
        .read(readingRepositoryProvider)
        .setFavourite(reading.id, favourite: on);
    if (saved.isOk) {
      await ref
          .read(analyticsServiceProvider)
          .log(
            JournalFavouriteToggledEvent(
              entryType: JournalEntryType.reading,
              on: on,
            ),
          );
    }
    return saved;
  }

  /// "Write about this" on a reflection prompt (the note editor opens).
  Future<void> useReflectionPrompt() async {
    final reading = _reading;
    if (reading == null) return;
    await ref
        .read(analyticsServiceProvider)
        .log(
          ReflectionPromptUsedEvent(
            spread: AnalyticsSpread.fromId(reading.spreadId),
          ),
        );
  }

  /// Share as text (PR19); the question only with [includeQuestion].
  Future<Result<void>> share(
    ShareCopy copy, {
    required bool includeQuestion,
  }) async {
    final reading = _reading;
    if (reading == null || _sharing) return const Result.ok(null);
    _sharing = true;
    state = _stateFor(reading);
    final useCase = ShareReadingUseCase(
      content: ref.read(contentRepositoryProvider),
      share: ref.read(shareTextProvider),
    );
    final shared = await useCase(
      reading,
      copy,
      locale: ref.read(appLocaleProvider)(),
      includeQuestion: includeQuestion,
    );
    if (!ref.mounted) return shared;
    _sharing = false;
    state = _stateFor(_reading ?? reading);
    if (shared.isOk) {
      await ref
          .read(analyticsServiceProvider)
          .log(
            ReadingSharedEvent(
              spread: AnalyticsSpread.fromId(reading.spreadId),
              includeQuestion: includeQuestion,
            ),
          );
    }
    return shared;
  }
}

/// S09 (`readingResultControllerProvider(args)`).
final NotifierProviderFamily<
  ReadingResultController,
  ReadingResultState,
  ReadingResultArgs
>
readingResultControllerProvider = NotifierProvider.autoDispose.family(
  ReadingResultController.new,
);
