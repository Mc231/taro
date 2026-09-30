import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'reading_session.freezed.dart';

/// A card fixed before the ritual: the daily card behind "Reflect deeper"
/// (01 §7.6) or the declined draw reused by "Reflect on the cards without a
/// question" (01 §7.5). Placed on the spread positions in order.
@freezed
abstract class PresetCard with _$PresetCard {
  /// Creates a preset card.
  const factory PresetCard({
    required CardId cardId,
    required bool reversed,
  }) = _PresetCard;
}

/// The reading being drawn: what S07 hands to S08 (02 §9.3).
///
/// An AI session carries the pre-draw [hold] (RC50); a Classic session
/// carries its [classicReason] and no hold (RC20); a resumed session
/// ([resumeReadingId], Journal "Finish reading") re-requests a stored
/// `pending`/`failed` reading with the same cards (RC49).
@freezed
abstract class ReadingSession with _$ReadingSession {
  /// Creates a session.
  const factory ReadingSession({
    required SpreadDefinition spread,
    required ReadingFlowSource source,
    required String locale,
    String? question,
    @Default(<PresetCard>[]) List<PresetCard> presetCards,
    ReadingHold? hold,
    ClassicReadingReason? classicReason,
    ReadingId? resumeReadingId,
  }) = _ReadingSession;

  const ReadingSession._();

  /// Whether this is a Classic reading (no hold, no Worker call).
  bool get isClassic => classicReason != null;
}

/// The current [ReadingSession] (keep-alive: it outlives S07 while S08 is
/// open). Only `QuestionController` starts AI and Classic sessions.
final class ReadingSessionController extends Notifier<ReadingSession?> {
  @override
  ReadingSession? build() => null;

  /// Starts [session], replacing any previous one.
  // A command on the controller, not a property.
  // ignore: use_setters_to_change_properties
  void start(ReadingSession session) => state = session;

  /// Starts a resume session for the stored reading [id] (S15 "Finish
  /// reading" → S08 `awaitingReading`). Returns `false` when the reading or
  /// its spread cannot be loaded, or it is not `pending`/`failed`.
  Future<bool> resume(ReadingId id) async {
    final stored = await ref.read(readingRepositoryProvider).get(id);
    final reading = stored.valueOrNull;
    if (reading == null) return false;
    final retryable = switch (reading.status) {
      ReadingStatusPending() || ReadingStatusFailed() => true,
      _ => false,
    };
    if (!retryable) return false;
    final spreads = await ref.read(contentRepositoryProvider).spreads();
    final spread = spreads.valueOrNull?.firstWhereOrNull(
      (s) => s.id == reading.spreadId,
    );
    if (spread == null || !ref.mounted) return false;
    state = ReadingSession(
      spread: spread,
      source: ReadingFlowSource.journalRetry,
      locale: reading.contentLocale,
      question: reading.question,
      resumeReadingId: id,
    );
    await ref
        .read(analyticsServiceProvider)
        .log(
          ReadingFlowStartedEvent(
            source: ReadingFlowSource.journalRetry,
            spread: AnalyticsSpread.fromId(spread.id),
          ),
        );
    return true;
  }

  /// Ends the session.
  void clear() => state = null;
}

/// The current reading session (`readingSessionProvider`).
final readingSessionProvider =
    NotifierProvider<ReadingSessionController, ReadingSession?>(
      ReadingSessionController.new,
    );

/// An S08 outcome that belongs to S07 (02 §9.3): the Worker declined the
/// question, readings paused, AI consent or the region was refused after
/// the hold. S08 posts it; `QuestionController` takes it and shows the
/// matching S07 state with the question kept.
@freezed
sealed class ReadingHandoff with _$ReadingHandoff {
  /// Declined (`status: declined`, not a crisis category): `rephrase` or
  /// `refused(category)`. [draw] is the declined draw ("Reflect on the
  /// cards without a question").
  const factory ReadingHandoff.declined({
    required SafetyInfo safety,
    required Draw draw,
  }) = ReadingHandoffDeclined;

  /// `503 READINGS_DISABLED` / `AI_BUDGET_EXHAUSTED` → S31 (RC47).
  const factory ReadingHandoff.paused({@Default(false) bool freePaused}) =
      ReadingHandoffPaused;

  /// `412 AI_CONSENT_REQUIRED` → S04 (RC28).
  const factory ReadingHandoff.consentRequired() = ReadingHandoffConsent;

  /// `403 AI_UNAVAILABLE_REGION` → Classic offer (RC29).
  const factory ReadingHandoff.aiUnavailableRegion() = ReadingHandoffRegion;
}

/// Holds the pending [ReadingHandoff] until S07 takes it.
final class ReadingHandoffController extends Notifier<ReadingHandoff?> {
  @override
  ReadingHandoff? build() => null;

  /// Posts [handoff] for S07.
  // A command on the controller, not a property.
  // ignore: use_setters_to_change_properties
  void post(ReadingHandoff handoff) => state = handoff;

  /// Takes (and clears) the pending handoff.
  ReadingHandoff? take() {
    final handoff = state;
    state = null;
    return handoff;
  }
}

/// The S08 → S07 handoff (`readingHandoffProvider`).
final readingHandoffProvider =
    NotifierProvider<ReadingHandoffController, ReadingHandoff?>(
      ReadingHandoffController.new,
    );

/// Small list helper (no `collection` import in features).
extension FirstWhereOrNull<T> on Iterable<T> {
  /// The first element matching [test], or `null`.
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
