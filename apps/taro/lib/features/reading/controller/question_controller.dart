import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:taro/app_state/connectivity_controller.dart';
import 'package:taro/app_state/consent_controller.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/reading/controller/question_state.dart';
import 'package:taro/features/reading/controller/reading_session.dart';
import 'package:taro_core/taro_core.dart';

/// S07 Question input + **Begin** (01 §7.2, §7.3 step 1, 02 §9.3).
///
/// Begin runs `ReadingGate` (via `ResolveReadingGate`, RC44) and, when it
/// allows, the Worker pre-draw hold (RC50) **before** any card is drawn:
/// hold 402 → S10, 503 → S31, 429 `dailyLimit` → `dailyLimitReached`. Only
/// a `201` hold starts the [ReadingSession] S08 draws under. Nothing
/// auto-starts after S10 or S12 (RC58); an AI consent granted on S04 re-runs
/// the gate (F7).
final class QuestionController extends Notifier<QuestionState> {
  /// A controller for [args].
  QuestionController(this.args);

  /// The spread, flow source and preset cards.
  final QuestionArgs args;

  QuestionDraft? _draft;
  bool _flowLogged = false;
  bool _spreadRequested = false;

  /// Remembered `403 AI_UNAVAILABLE_REGION` (the client never knows its
  /// region otherwise, 02 §4.1).
  bool _regionBlocked = false;

  @override
  QuestionState build() {
    final config = ref.watch(remoteConfigRepositoryProvider);
    final analytics = ref.watch(analyticsServiceProvider);
    ref
      ..listen<bool>(aiConsentValidProvider, (previous, valid) {
        if (valid && state is QuestionConsentRequired) unawaited(begin());
      })
      ..listen<bool>(connectivityProvider, (previous, online) {
        if (online && state is QuestionOffline) {
          state = QuestionState.editing(_current);
        }
      })
      ..listen<ReadingHandoff?>(readingHandoffProvider, (previous, handoff) {
        // Deferred: a provider may not change others while it builds.
        if (handoff != null) unawaited(Future.microtask(_takeHandoff));
      }, fireImmediately: true);
    final draft = _draft ??= QuestionDraft(
      spreadId: args.spreadId,
      check: QuestionPrecheck.check(
        '',
        maxChars: config.current.aiQuestionMaxChars,
      ),
      maxChars: config.current.aiQuestionMaxChars,
      presetCards: args.presetCards,
    );
    if (!_flowLogged) {
      _flowLogged = true;
      unawaited(
        analytics.log(
          ReadingFlowStartedEvent(
            source: args.source,
            spread: AnalyticsSpread.fromId(args.spreadId),
          ),
        ),
      );
    }
    if (!_spreadRequested) {
      _spreadRequested = true;
      unawaited(Future.microtask(_loadSpread));
    }
    return QuestionState.editing(draft);
  }

  QuestionDraft get _current => _draft!;

  Future<void> _loadSpread() async {
    final spreads = await ref.read(contentRepositoryProvider).spreads();
    if (!ref.mounted) return;
    switch (spreads) {
      case Ok(:final value):
        final spread = value.firstWhereOrNull((s) => s.id == args.spreadId);
        if (spread == null) {
          state = QuestionState.spreadDisabled(_current);
          return;
        }
        _set(_current.copyWith(spread: spread));
      case Err(:final failure):
        state = QuestionState.failed(_current, failure: failure);
    }
  }

  void _set(QuestionDraft draft) {
    _draft = draft;
    state = state.copyWith(draft: draft);
  }

  /// The question field changed.
  void updateText(String text) => _edit(text, usedSuggestion: false);

  /// A suggestion chip was tapped: it fills the field (01 §7.2).
  void useSuggestion(String text) => _edit(text, usedSuggestion: true);

  void _edit(String text, {required bool usedSuggestion}) {
    if (state is QuestionChecking || state is QuestionReady) return;
    final draft = _current.copyWith(
      text: text,
      usedSuggestion: usedSuggestion,
      check: QuestionPrecheck.check(text, maxChars: _current.maxChars),
    );
    _draft = draft;
    state = QuestionState.editing(draft);
  }

  /// Back to `editing` with the question kept: a notice dismissed, S10
  /// closed after a grant or purchase (Begin enabled, nothing auto-starts,
  /// RC58), S31 left.
  void dismissNotice() {
    if (state is QuestionChecking) return;
    state = QuestionState.editing(_current);
  }

  /// **Begin**: the gate, then the pre-draw hold (RC44, RC50).
  Future<void> begin() async {
    final draft = _current;
    final spread = draft.spread;
    if (spread == null || !draft.check.isValid || state is QuestionChecking) {
      return;
    }
    state = QuestionState.checking(draft);
    final analytics = ref.read(analyticsServiceProvider);
    final aSpread = AnalyticsSpread.fromId(spread.id);
    await analytics.log(
      QuestionSubmittedEvent(
        spread: aSpread,
        hasQuestion: draft.check.question != null,
        questionLenBucket: QuestionLengthBucket.fromLength(draft.check.length),
        usedSuggestion: draft.usedSuggestion,
      ),
    );
    if (_regionBlocked) {
      await _blocked(
        QuestionState.aiUnavailableRegion(draft),
        GateBlockReason.region,
        aSpread,
      );
      return;
    }
    final gate = await ref.read(resolveReadingGateProvider).call(spread);
    if (!ref.mounted) return;
    switch (gate) {
      case Err(:final failure):
        state = QuestionState.failed(draft, failure: failure);
      case Ok(value: final decision):
        await analytics.log(
          ReadingGateEvaluatedEvent(decision: decision.kind, spread: aSpread),
        );
        if (!ref.mounted) return;
        await _onDecision(decision, draft, spread, aSpread);
    }
  }

  Future<void> _onDecision(
    GateDecision decision,
    QuestionDraft draft,
    SpreadDefinition spread,
    AnalyticsSpread aSpread,
  ) => switch (decision) {
    GateAllowed() => _hold(draft, spread, aSpread),
    GateDeviceUnverified() => _deviceUnverified(draft, aSpread),
    GateNeedsAiConsent() => _blocked(
      QuestionState.consentRequired(draft),
      GateBlockReason.noConsent,
      aSpread,
    ),
    // `needsSync` after the gate's own sync means the balance could not be
    // confirmed: the same "connect to start a reading" notice as offline.
    GateOffline() || GateNeedsSync() => _blocked(
      QuestionState.offline(draft),
      GateBlockReason.offline,
      aSpread,
    ),
    GateReadingsPaused(:final freePaused) => _paused(
      draft,
      aSpread,
      freePaused: freePaused,
    ),
    GateAiUnavailableRegion() => _blocked(
      QuestionState.aiUnavailableRegion(draft),
      GateBlockReason.region,
      aSpread,
    ),
    GateSpreadDisabled() => _blocked(
      QuestionState.spreadDisabled(draft),
      GateBlockReason.spreadDisabled,
      aSpread,
    ),
    GateNeedsCredits(:final options) => _paywall(
      draft,
      aSpread,
      options,
      hold: false,
    ),
    GateDailyLimitReached() => _blocked(
      QuestionState.dailyLimitReached(draft),
      GateBlockReason.dailyLimit,
      aSpread,
    ),
  };

  Future<void> _hold(
    QuestionDraft draft,
    SpreadDefinition spread,
    AnalyticsSpread aSpread,
  ) async {
    final locale = ref.read(appLocaleProvider)();
    final result = await ref
        .read(requestReadingProvider)
        .hold(spread, locale: locale);
    if (!ref.mounted) return;
    final analytics = ref.read(analyticsServiceProvider);
    switch (result) {
      case Ok(value: final hold):
        await analytics.log(
          ReadingHoldResultEvent(result: HoldResult.held, spread: aSpread),
        );
        if (!ref.mounted) return;
        ref
            .read(readingSessionProvider.notifier)
            .start(
              ReadingSession(
                spread: spread,
                source: args.source,
                locale: locale,
                question: draft.check.question,
                presetCards: draft.presetCards,
                hold: hold,
              ),
            );
        state = QuestionState.ready(draft);
      case Err(:final failure):
        await analytics.log(
          ReadingHoldResultEvent(result: _holdResult(failure), spread: aSpread),
        );
        if (!ref.mounted) return;
        await _holdFailed(failure, draft, aSpread);
    }
  }

  static HoldResult _holdResult(Failure failure) => switch (failure) {
    InsufficientCreditsFailure() => HoldResult.insufficientCredits,
    ReadingsPausedFailure() => HoldResult.paused,
    _ => HoldResult.error,
  };

  Future<void> _holdFailed(
    Failure failure,
    QuestionDraft draft,
    AnalyticsSpread aSpread,
  ) async {
    switch (failure) {
      case InsufficientCreditsFailure(reason: InsufficientReason.freePaused):
        await _paused(draft, aSpread, freePaused: true);
      case InsufficientCreditsFailure(:final reason, :final balance):
        final options = _paywallOptions(
          balance,
          reason == InsufficientReason.lowTrustCap
              ? PaywallReason.lowTrustCap
              : PaywallReason.noCredits,
        );
        if (options == null) {
          state = QuestionState.failed(draft, failure: failure);
          return;
        }
        await _paywall(draft, aSpread, options, hold: true);
      case RateLimitedFailure(reason: RateLimitReason.dailyLimit):
        await _blocked(
          QuestionState.dailyLimitReached(draft),
          GateBlockReason.dailyLimit,
          aSpread,
        );
      case RateLimitedFailure(reason: RateLimitReason.lowTrustCap):
        final options = _paywallOptions(null, PaywallReason.lowTrustCap);
        if (options == null) {
          state = QuestionState.failed(draft, failure: failure);
          return;
        }
        await _paywall(draft, aSpread, options, hold: true);
      case RateLimitedFailure(:final retryAfter):
        await _blocked(
          QuestionState.rateLimited(draft, retryAfter: retryAfter),
          GateBlockReason.rateLimited,
          aSpread,
        );
      case AiConsentRequiredFailure():
        await _blocked(
          QuestionState.consentRequired(draft),
          GateBlockReason.noConsent,
          aSpread,
        );
      case AiUnavailableRegionFailure():
        _regionBlocked = true;
        await _blocked(
          QuestionState.aiUnavailableRegion(draft),
          GateBlockReason.region,
          aSpread,
        );
      case ReadingsPausedFailure(:final reason):
        await _paused(
          draft,
          aSpread,
          freePaused: reason == PausedReason.freeStop,
        );
      case NetworkFailure() || TimeoutFailure():
        await _blocked(
          QuestionState.offline(draft),
          GateBlockReason.offline,
          aSpread,
        );
      case AttestationFailure() || SessionExpiredFailure():
        await _deviceUnverified(draft, aSpread);
      default:
        state = QuestionState.failed(draft, failure: failure);
    }
  }

  /// The S10 options for a hold `402` (04 §5.5): from the balance that came
  /// with the error, else the cached one.
  PaywallOptions? _paywallOptions(
    CreditBalance? fromError,
    PaywallReason reason,
  ) {
    final balance = fromError ?? ref.read(balanceRepositoryProvider).cached;
    if (balance == null) return null;
    return ReadingGate.paywall(
      balance,
      ref.read(remoteConfigRepositoryProvider).current,
      ref.read(consentStoreProvider).current,
      reason: reason,
      online: true,
      now: ref.read(clockProvider).now(),
    );
  }

  Future<void> _paywall(
    QuestionDraft draft,
    AnalyticsSpread aSpread,
    PaywallOptions options, {
    required bool hold,
  }) {
    final lowTrust = options.reason == PaywallReason.lowTrustCap;
    return _blocked(
      lowTrust
          ? QuestionState.lowTrustLimited(draft, options: options)
          : QuestionState.outOfReadings(
              draft,
              options: options,
              source: hold
                  ? OutOfReadingsSource.hold402
                  : OutOfReadingsSource.questionGate,
            ),
      lowTrust ? GateBlockReason.lowTrust : GateBlockReason.insufficientCredits,
      aSpread,
    );
  }

  Future<void> _paused(
    QuestionDraft draft,
    AnalyticsSpread aSpread, {
    required bool freePaused,
  }) async {
    await _blocked(
      QuestionState.readingsPaused(draft, freePaused: freePaused),
      freePaused ? GateBlockReason.freePaused : GateBlockReason.readingsPaused,
      aSpread,
    );
    await ref
        .read(analyticsServiceProvider)
        .log(
          const ReadingsPausedShownEvent(origin: AppNoticeOrigin.readingGate),
        );
  }

  Future<void> _deviceUnverified(
    QuestionDraft draft,
    AnalyticsSpread aSpread,
  ) async {
    await _blocked(
      QuestionState.deviceUnverified(draft),
      GateBlockReason.deviceUnverified,
      aSpread,
    );
    await ref
        .read(analyticsServiceProvider)
        .log(
          const DeviceUnverifiedShownEvent(origin: AppNoticeOrigin.readingGate),
        );
  }

  Future<void> _blocked(
    QuestionState next,
    GateBlockReason reason,
    AnalyticsSpread aSpread,
  ) async {
    if (!ref.mounted) return;
    state = next;
    await ref
        .read(analyticsServiceProvider)
        .log(ReadingGateBlockedEvent(reason: reason, spread: aSpread));
  }

  /// Starts a Classic reading (F8, RC20) from `consentRequired` (after "Not
  /// now"), `aiUnavailableRegion` or `readingsPaused`: no hold, no Worker
  /// call.
  Future<void> startClassic() async {
    final current = state;
    final spread = _current.spread;
    final reason = switch (current) {
      QuestionConsentRequired() => ClassicReadingReason.noConsent,
      QuestionAiUnavailableRegion() => ClassicReadingReason.region,
      QuestionReadingsPaused() => ClassicReadingReason.paused,
      _ => null,
    };
    if (reason == null || spread == null) return;
    ref
        .read(readingSessionProvider.notifier)
        .start(
          ReadingSession(
            spread: spread,
            source: args.source,
            locale: ref.read(appLocaleProvider)(),
            question: _current.check.question,
            presetCards: _current.presetCards,
            classicReason: reason,
          ),
        );
    state = QuestionState.ready(_current);
    await ref
        .read(analyticsServiceProvider)
        .log(
          ClassicReadingStartedEvent(
            spread: AnalyticsSpread.fromId(spread.id),
            reason: reason,
          ),
        );
  }

  /// "Reflect on the cards without a question" (01 §7.5): the question is
  /// removed and the declined cards are reused, then Begin runs again (a new
  /// hold; no credit was used by the decline).
  Future<void> reflectWithoutQuestion() async {
    final current = state;
    if (current is! QuestionRephrase) return;
    _draft = current.draft.copyWith(
      text: '',
      usedSuggestion: false,
      check: QuestionPrecheck.check('', maxChars: current.draft.maxChars),
      presetCards: [
        for (final c in current.draw.cards)
          PresetCard(cardId: c.cardId, reversed: c.reversed),
      ],
    );
    state = QuestionState.editing(_current);
    await begin();
  }

  void _takeHandoff() {
    if (!ref.mounted) return;
    final taken = ref.read(readingHandoffProvider.notifier).take();
    if (taken == null) return;
    final text = ref.read(readingSessionProvider)?.question ?? _current.text;
    final draft = _draft = _current.copyWith(
      text: text,
      check: QuestionPrecheck.check(text, maxChars: _current.maxChars),
    );
    if (taken is ReadingHandoffRegion) _regionBlocked = true;
    state = switch (taken) {
      ReadingHandoffDeclined(:final safety, :final draw)
          when safety.canRephrase =>
        QuestionState.rephrase(draft, safety: safety, draw: draw),
      ReadingHandoffDeclined(:final safety) => QuestionState.refused(
        draft,
        category: safety.category,
        safety: safety,
      ),
      ReadingHandoffPaused(:final freePaused) => QuestionState.readingsPaused(
        draft,
        freePaused: freePaused,
      ),
      ReadingHandoffConsent() => QuestionState.consentRequired(draft),
      ReadingHandoffRegion() => QuestionState.aiUnavailableRegion(draft),
    };
  }
}

/// S07 (`questionControllerProvider(args)`).
final NotifierProviderFamily<QuestionController, QuestionState, QuestionArgs>
questionControllerProvider = NotifierProvider.autoDispose.family(
  QuestionController.new,
);
