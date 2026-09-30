import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/features/reading/controller/reading_session.dart';
import 'package:taro_core/taro_core.dart';

part 'question_state.freezed.dart';

/// What S07 opens with: the spread, where the flow started (01 §15
/// `reading_flow_started.source`) and any preset cards (the daily card's
/// "Reflect deeper", 01 §7.6).
@freezed
abstract class QuestionArgs with _$QuestionArgs {
  /// Creates the arguments.
  const factory QuestionArgs({
    required SpreadId spreadId,
    @Default(ReadingFlowSource.home) ReadingFlowSource source,
    @Default(<PresetCard>[]) List<PresetCard> presetCards,
  }) = _QuestionArgs;
}

/// The question as typed (01 §7.2), kept in every S07 state so it survives
/// every notice, S04, S10 and a declined question.
@freezed
abstract class QuestionDraft with _$QuestionDraft {
  /// Creates a draft.
  const factory QuestionDraft({
    required SpreadId spreadId,
    required QuestionCheck check,
    required int maxChars,
    SpreadDefinition? spread,
    @Default('') String text,
    @Default(false) bool usedSuggestion,
    @Default(<PresetCard>[]) List<PresetCard> presetCards,
  }) = _QuestionDraft;

  const QuestionDraft._();

  /// Whether **Begin** is enabled: the spread is loaded and the pre-check
  /// passes (an empty question is allowed).
  bool get canBegin => spread != null && check.isValid;

  /// Whether the character counter shows (≥ 250, 01 §7.2).
  bool get showsCounter => check.length >= QuestionPrecheck.counterFrom;
}

/// S07 Question input + **Begin** (01 §8.3, 02 §7): every state keeps the
/// [draft].
@freezed
sealed class QuestionState with _$QuestionState {
  const QuestionState._();

  /// Typing; Begin enabled when `draft.canBegin`.
  const factory QuestionState.editing(QuestionDraft draft) = QuestionEditing;

  /// Gate + pre-draw hold running after Begin (PR5, RC44, RC50).
  const factory QuestionState.checking(QuestionDraft draft) = QuestionChecking;

  /// The hold is taken (or a Classic reading chosen): S08 opens.
  const factory QuestionState.ready(QuestionDraft draft) = QuestionReady;

  /// No connection: Begin disabled with an inline notice.
  const factory QuestionState.offline(QuestionDraft draft) = QuestionOffline;

  /// AI consent missing or outdated → S04 (RC21); after "Not now" the
  /// Classic reading is offered (F7, F8).
  const factory QuestionState.consentRequired(QuestionDraft draft) =
      QuestionConsentRequired;

  /// The install is not registered: "Readings unavailable on this device".
  const factory QuestionState.deviceUnverified(QuestionDraft draft) =
      QuestionDeviceUnverified;

  /// S31 with daily card / Learn / Classic links; never a paywall (RC47).
  /// [freePaused] selects "Free readings are resting until tomorrow"
  /// (RC64).
  const factory QuestionState.readingsPaused(
    QuestionDraft draft, {
    @Default(false) bool freePaused,
  }) = QuestionReadingsPaused;

  /// `403 AI_UNAVAILABLE_REGION` → Classic offer (RC29).
  const factory QuestionState.aiUnavailableRegion(QuestionDraft draft) =
      QuestionAiUnavailableRegion;

  /// S10 before anything is drawn; [source] is `out_of_readings_viewed`'s.
  const factory QuestionState.outOfReadings(
    QuestionDraft draft, {
    required PaywallOptions options,
    required OutOfReadingsSource source,
  }) = QuestionOutOfReadings;

  /// "You've reached today's reading limit"; no paywall (RC74).
  const factory QuestionState.dailyLimitReached(QuestionDraft draft) =
      QuestionDailyLimitReached;

  /// S10 with "Free readings aren't available on this device right now";
  /// purchase and rewarded stay available (RC74).
  const factory QuestionState.lowTrustLimited(
    QuestionDraft draft, {
    required PaywallOptions options,
  }) = QuestionLowTrustLimited;

  /// Declined with `canRephrase: true`: hint + example rewordings.
  const factory QuestionState.rephrase(
    QuestionDraft draft, {
    required SafetyInfo safety,
    required Draw draw,
  }) = QuestionRephrase;

  /// Declined without a rewording hint (03 §9.4 categories, RC27).
  const factory QuestionState.refused(
    QuestionDraft draft, {
    required RefusalCategory category,
    required SafetyInfo safety,
  }) = QuestionRefused;

  /// `429 RATE_LIMITED` with `details.reason = burst`.
  const factory QuestionState.rateLimited(
    QuestionDraft draft, {
    Duration? retryAfter,
  }) = QuestionRateLimited;

  /// The spread is not in `spreads.enabled` (a stale link or config flip).
  const factory QuestionState.spreadDisabled(QuestionDraft draft) =
      QuestionSpreadDisabled;

  /// Any other failure (storage, server): `TaroErrorView(kind)` + Retry.
  const factory QuestionState.failed(
    QuestionDraft draft, {
    required Failure failure,
  }) = QuestionFailed;

  /// Whether the Classic reading is offered here (F8: `consentRequired`
  /// after "Not now", `aiUnavailableRegion`, `readingsPaused`).
  bool get offersClassic => switch (this) {
    QuestionConsentRequired() ||
    QuestionAiUnavailableRegion() ||
    QuestionReadingsPaused() => true,
    _ => false,
  };
}
