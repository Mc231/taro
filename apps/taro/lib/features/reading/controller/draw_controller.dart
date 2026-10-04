import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/reading/controller/draw_state.dart';
import 'package:taro/features/reading/controller/reading_session.dart';
import 'package:taro_core/taro_core.dart';

/// S08 Draw ritual (01 §7.3 steps 2–6, 02 §9.3, F6, F8).
///
/// The draw is made when S08 opens, under the session's pre-draw hold
/// (RC50; none for Classic, RC20). When the last card is placed the hold is
/// renewed if it has < 120 s left (`402`/`409` → [DrawHoldLost], cards
/// face-down, RC48), then the reading is persisted `pending` and requested
/// while the user reveals (the repository persists before the network call
/// and the use case acknowledges after storing, RC51). A retry resubmits
/// the **same** cards with the same `clientReadingId` (RC49).
final class DrawController extends Notifier<DrawState> {
  /// When `awaitingReading` becomes `slowReading` (01 §8.3).
  static const Duration slowReadingAfter = Duration(seconds: 20);

  /// The client timeout after which the status is polled (RC31).
  static const Duration clientTimeout = Duration(seconds: 60);

  late ReadingSession _session;
  ReadingHold? _hold;
  DateTime? _pickStartedAt;
  DateTime? _submittedAt;
  Timer? _slowTimer;
  Timer? _pollTimer;
  bool _slow = false;
  bool _polling = false;
  Result<Reading>? _outcome;

  @override
  DrawState build() {
    final session = ref.watch(readingSessionProvider);
    ref.onDispose(_cancelTimers);
    if (session == null) return const DrawState.unavailable();
    _session = session;
    _hold = session.hold;
    _outcome = null;
    unawaited(Future.microtask(_prepare));
    return const DrawState.preparing();
  }

  ReadingSession get _s => _session;

  AnalyticsSpread get _aSpread => AnalyticsSpread.fromId(_s.spread.id);

  Future<void> _prepare() async {
    if (!ref.mounted) return;
    final session = _s;
    if (session.resumeReadingId != null) return _prepareResume(session);
    final reducedMotion =
        ref.read(settingsRepositoryProvider).current.reduceMotion ?? false;
    final drawn = await _draw(session);
    if (!ref.mounted) return;
    switch (drawn) {
      case Err(:final failure):
        state = DrawState.failed(failure: failure);
      case Ok(value: final draw):
        state = DrawState.shuffling(
          DrawView(
            spread: session.spread,
            draw: draw,
            classic: session.isClassic,
            reducedMotion: reducedMotion,
            readingId: _hold?.readingId,
            question: session.question,
          ),
        );
    }
  }

  Future<Result<Draw>> _draw(ReadingSession session) async {
    if (session.isClassic) {
      final preset = _presetDraw(session);
      if (preset != null) return Result.ok(preset);
      return ref.read(startClassicReadingProvider).draw(session.spread);
    }
    final hold = _hold;
    if (hold == null) {
      return const Result.err(Failure.holdConflict());
    }
    final fresh = await ref
        .read(requestReadingProvider)
        .ensureFresh(hold, session.spread, locale: session.locale);
    if (fresh case Err(:final failure)) return Result.err(failure);
    _hold = fresh.valueOrNull;
    final preset = _presetDraw(session);
    if (preset != null) return Result.ok(preset);
    return ref.read(drawCardsProvider).call(session.spread, hold: _hold!);
  }

  /// The preset cards on the spread positions in order, or `null` when
  /// they do not fit the spread.
  Draw? _presetDraw(ReadingSession session) {
    final positions = session.spread.positionsInOrder;
    final preset = session.presetCards;
    if (preset.isEmpty || preset.length != positions.length) return null;
    return Draw(
      spreadId: session.spread.id,
      spreadVersion: session.spread.version,
      cards: [
        for (var i = 0; i < positions.length; i++)
          DrawnCard(
            positionId: positions[i].id,
            cardId: preset[i].cardId,
            reversed: preset[i].reversed,
          ),
      ],
      drawnAt: ref.read(clockProvider).now().toUtc(),
    );
  }

  Future<void> _prepareResume(ReadingSession session) async {
    final id = session.resumeReadingId!;
    final stored = await ref.read(readingRepositoryProvider).get(id);
    if (!ref.mounted) return;
    final reading = stored.valueOrNull;
    if (reading == null) {
      state = DrawState.failed(
        failure: stored.failureOrNull ?? const Failure.storage(),
      );
      return;
    }
    final view = DrawView(
      spread: session.spread,
      draw: reading.draw,
      classic: false,
      placed: reading.cards.length,
      revealed: reading.cards.length,
      readingId: id,
      question: reading.question,
    );
    state = DrawState.awaitingReading(view);
    _submittedAt = ref.read(clockProvider).now();
    _startTimers();
    if (reading.status is ReadingStatusPending) {
      final resumed = await ref.read(resumeReadingProvider).call(id);
      if (!ref.mounted) return;
      final terminal = switch (resumed) {
        Ok(value: Reading(status: ReadingStatusComplete())) ||
        Ok(value: Reading(status: ReadingStatusRefused())) ||
        Err(failure: ReadingExpiredRefundedFailure()) ||
        Err(failure: NetworkFailure()) => true,
        _ => false,
      };
      if (terminal) return _finish(resumed);
    }
    final retried = await ref
        .read(requestReadingProvider)
        .retry(reading, session.spread);
    if (!ref.mounted) return;
    await _finish(retried);
  }

  /// The shuffle animation ended: the user picks now.
  void finishShuffle() {
    final current = state;
    if (current is! DrawShuffling) return;
    _pickStartedAt = ref.read(clockProvider).now();
    state = DrawState.picking(current.view);
  }

  /// One card was picked and flew to the next position.
  Future<void> pick() async {
    final current = state;
    if (current is! DrawPicking || current.view.allPlaced) return;
    final view = current.view.copyWith(placed: current.view.placed + 1);
    state = DrawState.picking(view);
    if (view.allPlaced) await _commit(view);
  }

  /// "Draw for me": every remaining card is placed at once.
  Future<void> drawForMe() async {
    final current = state;
    final view = switch (current) {
      DrawShuffling(:final view) || DrawPicking(:final view) => view,
      _ => null,
    };
    if (view == null || view.allPlaced) return;
    _pickStartedAt ??= ref.read(clockProvider).now();
    final placed = view.copyWith(placed: view.cardCount, autoDraw: true);
    state = DrawState.picking(placed);
    await _commit(placed);
  }

  Future<void> _commit(DrawView view) async {
    final now = ref.read(clockProvider).now();
    final cards = view.draw.cards;
    await ref
        .read(analyticsServiceProvider)
        .log(
          DrawCompletedEvent(
            spread: _aSpread,
            autoDraw: view.autoDraw,
            reversedCount: cards.where((c) => c.reversed).length,
            majorCount: cards
                .where((c) => c.cardId.value.startsWith('major_'))
                .length,
            durationMs: now.difference(_pickStartedAt ?? now).inMilliseconds,
          ),
        );
    if (!ref.mounted) return;
    if (view.classic) {
      state = DrawState.revealing(view);
      return;
    }
    final renewed = await ref
        .read(requestReadingProvider)
        .ensureFresh(_hold!, _s.spread, locale: _s.locale);
    if (!ref.mounted) return;
    switch (renewed) {
      case Err(:final failure):
        await _fail(view, failure);
      case Ok(:final value):
        _hold = value;
        state = DrawState.revealing(view);
        _submit(view);
    }
  }

  void _submit(DrawView view) {
    _outcome = null;
    _submittedAt = ref.read(clockProvider).now();
    _startTimers();
    unawaited(
      ref
          .read(requestReadingProvider)
          .submit(
            hold: _hold!,
            draw: view.draw,
            locale: _s.locale,
            question: _s.question,
          )
          .then(_arrived),
    );
  }

  void _arrived(Result<Reading> result) {
    if (!ref.mounted) return;
    _cancelTimers();
    final current = state;
    final interrupts = switch (result) {
      Err(failure: InsufficientCreditsFailure() || HoldConflictFailure()) =>
        true,
      Ok(value: Reading(status: ReadingStatusRefused(:final safety))) =>
        safety?.category.showsCrisisResources ?? false,
      _ => false,
    };
    if (current is DrawRevealing && !current.view.allRevealed && !interrupts) {
      _outcome = result;
      return;
    }
    unawaited(_finish(result));
  }

  /// One card was flipped (in position order).
  Future<void> reveal() async {
    final current = state;
    if (current is! DrawRevealing) return;
    final view = current.view.copyWith(revealed: current.view.revealed + 1);
    if (!view.allRevealed) {
      state = DrawState.revealing(view);
      return;
    }
    await _revealed(view);
  }

  /// "Reveal all".
  Future<void> revealAll() async {
    final current = state;
    if (current is! DrawRevealing) return;
    await _revealed(current.view.copyWith(revealed: current.view.cardCount));
  }

  Future<void> _revealed(DrawView view) async {
    if (view.classic) return _saveClassic(view);
    final outcome = _outcome;
    if (outcome != null) {
      _outcome = null;
      state = _waiting(view);
      return _finish(outcome);
    }
    state = _waiting(view);
  }

  DrawState _waiting(DrawView view) => _polling
      ? DrawState.timeoutPolling(view)
      : _slow
      ? DrawState.slowReading(view)
      : DrawState.awaitingReading(view);

  Future<void> _saveClassic(DrawView view) async {
    final saved = await ref
        .read(startClassicReadingProvider)
        .complete(draw: view.draw, locale: _s.locale, question: _s.question);
    if (!ref.mounted) return;
    switch (saved) {
      case Ok(value: final reading):
        await ref
            .read(analyticsServiceProvider)
            .log(
              ClassicReadingCompletedEvent(
                spread: _aSpread,
                reason: _s.classicReason!,
              ),
            );
        if (!ref.mounted) return;
        state = DrawState.completed(view, reading: reading);
      case Err(:final failure):
        state = DrawState.failed(failure: failure, view: view);
    }
  }

  Future<void> _finish(Result<Reading> result) async {
    final view = _viewOf(state);
    if (view == null) return;
    switch (result) {
      case Ok(value: final reading):
        switch (reading.status) {
          case ReadingStatusComplete():
            await _generated(view, reading);
          case ReadingStatusRefused(:final safety):
            await _declined(
              view,
              safety,
              notCharged: reading.chargeSource == null,
            );
          case ReadingStatusFailed(:final failure):
            await _fail(view, failure);
          case ReadingStatusPending() || ReadingStatusClassic():
            await _fail(view, const Failure.timeout());
        }
      case Err(:final failure):
        await _fail(view, failure);
    }
  }

  Future<void> _generated(DrawView view, Reading reading) async {
    final analytics = ref.read(analyticsServiceProvider);
    final now = ref.read(clockProvider).now();
    final source =
        reading.chargeSource ?? _hold?.chargeSource ?? ChargeSource.free;
    state = DrawState.completed(view, reading: reading);
    await analytics.log(
      ReadingGeneratedEvent(
        spread: _aSpread,
        latencyMs: now.difference(_submittedAt ?? now).inMilliseconds,
        promptVersion: _promptVersion(reading.promptVersion),
        creditType: CreditType.fromChargeSource(source),
        locale: AnalyticsLocale.fromTag(reading.contentLocale),
      ),
    );
    await analytics.log(
      source == ChargeSource.free
          ? FreeReadingUsedEvent(bucket: source)
          : ReadingCreditConsumedEvent(bucket: source),
    );
  }

  static int _promptVersion(String? version) =>
      int.tryParse(version?.replaceAll(RegExp(r'\D'), '') ?? '') ?? 0;

  Future<void> _declined(
    DrawView view,
    SafetyInfo? given, {
    required bool notCharged,
  }) async {
    final safety =
        given ??
        SafetyInfo(
          category: RefusalCategory.other,
          messageKey: RefusalCategory.other.messageKey,
          canRephrase: false,
        );
    if (safety.category.showsCrisisResources) {
      state = DrawState.crisis(view, safety: safety);
    } else {
      ref
          .read(readingHandoffProvider.notifier)
          .post(
            ReadingHandoff.declined(
              safety: safety,
              draw: view.draw,
              notCharged: notCharged,
            ),
          );
      state = DrawState.returnedToQuestion(view);
    }
    await ref
        .read(analyticsServiceProvider)
        .log(
          ReadingRefusedEvent(
            spread: _aSpread,
            category: safety.category,
            canRephrase: safety.canRephrase,
          ),
        );
  }

  Future<void> _fail(DrawView view, Failure failure) async {
    final handoff = switch (failure) {
      ReadingsPausedFailure(:final reason) => ReadingHandoff.paused(
        freePaused: reason == PausedReason.freeStop,
      ),
      AiConsentRequiredFailure() => const ReadingHandoff.consentRequired(),
      AiUnavailableRegionFailure() =>
        const ReadingHandoff.aiUnavailableRegion(),
      _ => null,
    };
    if (handoff != null) {
      ref.read(readingHandoffProvider.notifier).post(handoff);
      state = DrawState.returnedToQuestion(view);
      return;
    }
    final (next, kind, refunded) = switch (failure) {
      InsufficientCreditsFailure() || HoldConflictFailure() => (
        DrawState.holdLost(view.copyWith(revealed: 0)),
        ReadingFailureKind.holdLost,
        false,
      ),
      ReadingExpiredRefundedFailure() => (
        DrawState.deliveryExpired(view),
        ReadingFailureKind.deliveryExpired,
        true,
      ),
      NetworkFailure() => (
        DrawState.generationFailed(view, failure: failure),
        ReadingFailureKind.network,
        false,
      ),
      TimeoutFailure() => (
        DrawState.generationFailed(view, failure: failure),
        ReadingFailureKind.timeout,
        false,
      ),
      _ => (
        DrawState.generationFailed(view, failure: failure),
        ReadingFailureKind.server,
        failure is AiUnavailableFailure,
      ),
    };
    state = next;
    await ref
        .read(analyticsServiceProvider)
        .log(
          ReadingFailedEvent(spread: _aSpread, error: kind, refunded: refunded),
        );
  }

  /// **Try again** from `generationFailed` / `deliveryExpired`: the same
  /// cards and `clientReadingId`; the Worker runs a new attempt (RC49).
  Future<void> retry() async {
    final current = state;
    final view = switch (current) {
      DrawGenerationFailed(:final view) ||
      DrawDeliveryExpired(:final view) => view,
      _ => null,
    };
    if (view == null) return;
    final id = view.readingId;
    final stored = id == null
        ? null
        : (await ref.read(readingRepositoryProvider).get(id)).valueOrNull;
    if (!ref.mounted) return;
    final retryable = switch (stored?.status) {
      ReadingStatusPending() || ReadingStatusFailed() => true,
      _ => false,
    };
    if (stored == null || !retryable || !view.allRevealed) {
      return _renewAndSubmit(view);
    }
    state = DrawState.awaitingReading(view);
    _submittedAt = ref.read(clockProvider).now();
    _startTimers();
    final result = await ref
        .read(requestReadingProvider)
        .retry(stored, _s.spread);
    if (!ref.mounted) return;
    _cancelTimers();
    await _finish(result);
  }

  /// Back from S10 after a grant or purchase with the cards still
  /// face-down: the same draw is resubmitted under a new hold for the same
  /// `clientReadingId` (RC48, RC50). Nothing starts without this call.
  Future<void> resumeAfterHoldLost() async {
    final current = state;
    if (current is! DrawHoldLost) return;
    await _renewAndSubmit(current.view);
  }

  Future<void> _renewAndSubmit(DrawView view) async {
    final held = await ref
        .read(requestReadingProvider)
        .hold(_s.spread, locale: _s.locale, readingId: view.readingId);
    if (!ref.mounted) return;
    switch (held) {
      case Err(:final failure):
        await _fail(view, failure);
      case Ok(:final value):
        _hold = value;
        final next = view.copyWith(readingId: value.readingId);
        state = next.allRevealed
            ? DrawState.awaitingReading(next)
            : DrawState.revealing(next);
        _submit(next);
    }
  }

  void _startTimers() {
    _cancelTimers();
    _slow = false;
    _polling = false;
    _slowTimer = Timer(slowReadingAfter, () {
      _slow = true;
      final current = state;
      if (current is DrawAwaitingReading) {
        state = DrawState.slowReading(current.view);
      }
    });
    _pollTimer = Timer(clientTimeout, () {
      _polling = true;
      final view = switch (state) {
        DrawAwaitingReading(:final view) ||
        DrawSlowReading(:final view) => view,
        _ => null,
      };
      if (view != null) state = DrawState.timeoutPolling(view);
    });
  }

  void _cancelTimers() {
    _slowTimer?.cancel();
    _pollTimer?.cancel();
    _slowTimer = null;
    _pollTimer = null;
  }

  static DrawView? _viewOf(DrawState state) => switch (state) {
    DrawUnavailable() || DrawPreparing() => null,
    DrawFailed(:final view) => view,
    DrawShuffling(:final view) ||
    DrawPicking(:final view) ||
    DrawRevealing(:final view) ||
    DrawAwaitingReading(:final view) ||
    DrawSlowReading(:final view) ||
    DrawTimeoutPolling(:final view) ||
    DrawGenerationFailed(:final view) ||
    DrawHoldLost(:final view) ||
    DrawDeliveryExpired(:final view) ||
    DrawCrisis(:final view) ||
    DrawReturnedToQuestion(:final view) ||
    DrawCompleted(:final view) => view,
  };
}

/// S08 (`drawControllerProvider`), over the current [ReadingSession].
final NotifierProvider<DrawController, DrawState> drawControllerProvider =
    NotifierProvider.autoDispose(DrawController.new);
