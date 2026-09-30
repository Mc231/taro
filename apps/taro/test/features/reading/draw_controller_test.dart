import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/features/reading/controller/draw_controller.dart';
import 'package:taro/features/reading/controller/draw_state.dart';
import 'package:taro/features/reading/controller/reading_session.dart';
import 'package:taro_core/taro_core.dart';

import '../feature_test_support.dart';

/// Holds `submit` open until [release] (the Worker is still writing).
final class GatedReadingRepository implements ReadingRepository {
  GatedReadingRepository(this.inner);

  final FakeReadingRepository inner;
  Completer<void>? _gate = Completer<void>();

  void release() {
    _gate?.complete();
    _gate = null;
  }

  @override
  Future<Result<Reading>> submit(Reading pending) async {
    await _gate?.future;
    return inner.submit(pending);
  }

  @override
  Future<Result<ReadingHold>> hold(
    ReadingId readingId,
    SpreadDefinition spread, {
    required String locale,
  }) => inner.hold(readingId, spread, locale: locale);

  @override
  Future<Result<Reading>> resume(ReadingId id) => inner.resume(id);

  @override
  Future<Result<void>> ack(ReadingId id) => inner.ack(id);

  @override
  Future<Result<int>> flushPendingAcks() => inner.flushPendingAcks();

  @override
  Future<Result<Reading>> saveClassic(Reading reading) =>
      inner.saveClassic(reading);

  @override
  Future<Result<Reading?>> get(ReadingId id) => inner.get(id);

  @override
  Future<Result<List<Reading>>> pending() => inner.pending();

  @override
  Stream<Reading?> watch(ReadingId id) => inner.watch(id);

  @override
  Future<Result<void>> setNote(ReadingId id, String? note) =>
      inner.setNote(id, note);

  @override
  Future<Result<void>> setFavourite(ReadingId id, {required bool favourite}) =>
      inner.setFavourite(id, favourite: favourite);

  @override
  Future<Result<void>> setRating(
    ReadingId id,
    Rating? rating, {
    RatingReason? reason,
  }) => inner.setRating(id, rating, reason: reason);

  @override
  Future<Result<void>> markReported(ReadingId id) => inner.markReported(id);

  @override
  Future<Result<void>> delete(ReadingId id) => inner.delete(id);

  @override
  Future<Result<bool>> undoDelete(ReadingId id) => inner.undoDelete(id);
}

SpreadDefinition spreadOf(String id) =>
    allSpreads().firstWhere((s) => s.id == SpreadId(id));

ReadingSession aiSession({
  String spread = 'three_ppf',
  List<PresetCard> preset = const [],
  String? question = 'What now?',
}) => ReadingSession(
  spread: spreadOf(spread),
  source: ReadingFlowSource.home,
  locale: 'en',
  question: question,
  presetCards: preset,
  hold: aReadingHold(),
);

ReadingSession classicSession() => ReadingSession(
  spread: spreadOf('three_ppf'),
  source: ReadingFlowSource.home,
  locale: 'en',
  classicReason: ClassicReadingReason.noConsent,
);

void main() {
  late TaroFakes fakes;

  (ProviderContainer, StateLog<DrawState>, DrawController) openWith(
    ReadingSession? session, {
    List<Override> extra = const [],
  }) {
    final container = fakes.container(extra: extra);
    if (session != null) {
      container.read(readingSessionProvider.notifier).start(session);
    }
    final log = StateLog(container, drawControllerProvider);
    return (container, log, container.read(drawControllerProvider.notifier));
  }

  Future<(ProviderContainer, StateLog<DrawState>, DrawController)> ready(
    ReadingSession session, {
    List<Override> extra = const [],
  }) async {
    final opened = openWith(session, extra: extra);
    await pumpEventQueue();
    opened.$3.finishShuffle();
    return opened;
  }

  List<ReadingFailureKind> failures() => [
    for (final e in eventsOf<ReadingFailedEvent>(fakes)) e.error,
  ];

  setUp(() => fakes = aiReadyFakes());

  test('no session is unavailable', () {
    final (_, log, _) = openWith(null);
    expect(log.last, isA<DrawUnavailable>());
  });

  group('AI reading', () {
    test('preparing → shuffling → picking → revealing → completed', () async {
      final (_, log, controller) = openWith(aiSession());
      expect(log.last, isA<DrawPreparing>());
      await pumpEventQueue();
      final shuffling = log.last as DrawShuffling;
      expect(shuffling.view.cardCount, 3);
      expect(shuffling.view.readingId, kTestReadingId);
      controller.finishShuffle();
      expect(log.last, isA<DrawPicking>());
      await controller.pick();
      await controller.pick();
      expect((log.last as DrawPicking).view.placed, 2);
      await controller.pick();
      expect(log.last, isA<DrawRevealing>());
      await pumpEventQueue();
      await controller.reveal();
      await controller.reveal();
      expect((log.last as DrawRevealing).view.revealed, 2);
      await controller.reveal();
      await pumpEventQueue();
      final done = log.last as DrawCompleted;
      expect(done.reading.status, isA<ReadingStatusComplete>());
      expect(done.reading.id, kTestReadingId);
      expect(
        fakes.readings.calls.indexOf('submit'),
        lessThan(fakes.readings.calls.indexOf('ack')),
      );
      expect(fakes.readings.acked, [kTestReadingId]);
      final drawn = eventsOf<DrawCompletedEvent>(fakes).single;
      expect(drawn.autoDraw, isFalse);
      expect(
        eventsOf<ReadingGeneratedEvent>(fakes).single.creditType,
        CreditType.free,
      );
      expect(eventsOf<FreeReadingUsedEvent>(fakes), hasLength(1));
      expect(fakes.readings.submitted.single.draw, done.view.draw);
    });

    test(
      '"Draw for me" and "Reveal all"; a paid reading is consumed',
      () async {
        final (_, log, controller) = openWith(
          aiSession().copyWith(
            hold: aReadingHold(chargeSource: ChargeSource.paid),
          ),
        );
        await pumpEventQueue();
        await controller.drawForMe();
        expect(eventsOf<DrawCompletedEvent>(fakes).single.autoDraw, isTrue);
        await pumpEventQueue();
        await controller.revealAll();
        await pumpEventQueue();
        expect(log.last, isA<DrawCompleted>());
        expect(
          eventsOf<ReadingCreditConsumedEvent>(fakes).single.bucket,
          ChargeSource.paid,
        );
      },
    );

    test('actions out of turn are ignored', () async {
      final (_, log, controller) = openWith(aiSession());
      await pumpEventQueue();
      await controller.pick();
      await controller.reveal();
      await controller.revealAll();
      await controller.retry();
      await controller.resumeAfterHoldLost();
      expect(log.last, isA<DrawShuffling>());
      controller
        ..finishShuffle()
        ..finishShuffle();
      await controller.drawForMe();
      await controller.drawForMe();
      await controller.pick();
      expect(eventsOf<DrawCompletedEvent>(fakes), hasLength(1));
    });

    test('reduced motion is a view variant', () async {
      fakes.journal.putSettings(const UserSettings(reduceMotion: true));
      final (_, log, _) = openWith(aiSession());
      await pumpEventQueue();
      expect((log.last as DrawShuffling).view.reducedMotion, isTrue);
    });

    test('the daily card preset is drawn as is (Reflect deeper)', () async {
      const preset = [PresetCard(cardId: CardId('major_17'), reversed: true)];
      final (_, log, _) = openWith(aiSession(spread: 'single', preset: preset));
      await pumpEventQueue();
      final card = (log.last as DrawShuffling).view.draw.cards.single;
      expect(card.cardId, const CardId('major_17'));
      expect(card.reversed, isTrue);
    });

    test('a preset that does not fit the spread is ignored', () async {
      const preset = [PresetCard(cardId: CardId('major_17'), reversed: true)];
      final (_, log, _) = openWith(aiSession(preset: preset));
      await pumpEventQueue();
      expect((log.last as DrawShuffling).view.cardCount, 3);
    });

    test('an unreadable deck is failed; nothing is drawn', () async {
      fakes.content.failNext(const Failure.storage(), on: 'deck');
      final (_, log, _) = openWith(aiSession());
      await pumpEventQueue();
      expect((log.last as DrawFailed).failure, isA<StorageFailure>());
    });

    test('a lapsed hold that cannot be renewed is failed', () async {
      fakes.clock.advance(const Duration(minutes: 11));
      fakes.readings.failNextWorkerCall(
        const Failure.insufficientCredits(reason: InsufficientReason.noCredits),
      );
      final (_, log, _) = openWith(aiSession());
      await pumpEventQueue();
      expect(log.last, isA<DrawFailed>());
    });

    test('a session without a hold is failed', () async {
      final (_, log, _) = openWith(aiSession().copyWith(hold: null));
      await pumpEventQueue();
      expect(
        (log.last as DrawFailed).failure,
        isA<HoldConflictFailure>(),
      );
    });
  });

  group('waiting for the Worker', () {
    testWidgets(
      'awaitingReading → slowReading (20 s) → timeoutPolling (60 s)',
      (tester) async {
        final gated = GatedReadingRepository(fakes.readings);
        fakes.readingsPort = gated;
        final (_, log, controller) = openWith(aiSession());
        await tester.pump();
        await controller.drawForMe();
        await tester.pump();
        await controller.revealAll();
        expect(log.last, isA<DrawAwaitingReading>());
        await tester.pump(const Duration(seconds: 21));
        expect(log.last, isA<DrawSlowReading>());
        await tester.pump(const Duration(seconds: 40));
        expect(log.last, isA<DrawTimeoutPolling>());
        gated.release();
        await tester.pump();
        await tester.pump();
        expect(log.last, isA<DrawCompleted>());
      },
    );

    testWidgets('a slow Worker shows slowReading when the reveal ends late', (
      tester,
    ) async {
      final gated = GatedReadingRepository(fakes.readings);
      fakes.readingsPort = gated;
      final (_, log, controller) = openWith(aiSession());
      await tester.pump();
      await controller.drawForMe();
      await tester.pump(const Duration(seconds: 25));
      expect(log.last, isA<DrawRevealing>());
      await controller.revealAll();
      expect(log.last, isA<DrawSlowReading>());
      await tester.pump(const Duration(seconds: 40));
      await controller.revealAll();
      expect(log.last, isA<DrawTimeoutPolling>());
      gated.release();
      await tester.pump();
    });
  });

  group('failures', () {
    Future<(StateLog<DrawState>, DrawController)> failAtSubmit(
      Failure failure,
    ) async {
      final (_, log, controller) = await ready(aiSession());
      fakes.readings.failNextWorkerCall(failure);
      await controller.drawForMe();
      await pumpEventQueue();
      await controller.revealAll();
      await pumpEventQueue();
      return (log, controller);
    }

    test('network → generationFailed; Try again reuses cards and ID', () async {
      final (log, controller) = await failAtSubmit(const Failure.network());
      final failed = log.last as DrawGenerationFailed;
      expect(failed.failure, isA<NetworkFailure>());
      expect(failures(), [ReadingFailureKind.network]);
      expect(eventsOf<ReadingFailedEvent>(fakes).single.refunded, isFalse);
      await controller.retry();
      await pumpEventQueue();
      final done = log.last as DrawCompleted;
      expect(done.reading.draw, failed.view.draw);
      expect(fakes.readings.holds.map((h) => h.$1).toSet(), {kTestReadingId});
      expect(
        fakes.readings.submitted.map((r) => r.id).toSet(),
        {kTestReadingId},
      );
    });

    test('timeout → generationFailed(timeout)', () async {
      final (log, _) = await failAtSubmit(const Failure.timeout());
      expect(log.last, isA<DrawGenerationFailed>());
      expect(failures(), [ReadingFailureKind.timeout]);
    });

    test('503 AI_UNAVAILABLE → generationFailed, refunded; retry', () async {
      final (log, controller) = await failAtSubmit(
        const Failure.aiUnavailable(),
      );
      expect(failures(), [ReadingFailureKind.server]);
      expect(eventsOf<ReadingFailedEvent>(fakes).single.refunded, isTrue);
      await controller.retry();
      await pumpEventQueue();
      expect(log.last, isA<DrawCompleted>());
    });

    test('410 → deliveryExpired; Try again with the same cards', () async {
      final (log, controller) = await failAtSubmit(
        const Failure.readingExpiredRefunded(),
      );
      expect(log.last, isA<DrawDeliveryExpired>());
      expect(failures(), [ReadingFailureKind.deliveryExpired]);
      await controller.retry();
      await pumpEventQueue();
      expect(log.last, isA<DrawCompleted>());
    });

    test('a reading left pending by the Worker is generationFailed', () async {
      final (_, log, controller) = await ready(aiSession());
      fakes.readings.stayPendingNext();
      await controller.drawForMe();
      await pumpEventQueue();
      await controller.revealAll();
      await pumpEventQueue();
      expect(
        (log.last as DrawGenerationFailed).failure,
        isA<TimeoutFailure>(),
      );
    });

    test(
      'the renewal fails offline → generationFailed; retry renews',
      () async {
        final (_, log, controller) = await ready(aiSession());
        fakes.clock.advance(const Duration(minutes: 9));
        fakes.readings.failNextWorkerCall(const Failure.network());
        await controller.drawForMe();
        await pumpEventQueue();
        final failed = log.last as DrawGenerationFailed;
        expect(failed.view.revealed, 0);
        await controller.retry();
        await pumpEventQueue();
        expect(log.last, isA<DrawRevealing>());
        await controller.revealAll();
        await pumpEventQueue();
        expect(log.last, isA<DrawCompleted>());
      },
    );

    test('a failed retry fails again', () async {
      final (log, controller) = await failAtSubmit(const Failure.network());
      fakes.readings.failNextWorkerCall(const Failure.network());
      await controller.retry();
      await pumpEventQueue();
      expect(log.last, isA<DrawGenerationFailed>());
    });
  });

  group('holdLost (RC48, RC50)', () {
    test(
      'the renewal returns 402: cards face-down, then resubmitted',
      () async {
        final (_, log, controller) = await ready(aiSession());
        fakes.clock.advance(const Duration(minutes: 9));
        fakes.readings.failNextWorkerCall(
          const Failure.insufficientCredits(
            reason: InsufficientReason.noCredits,
          ),
        );
        await controller.drawForMe();
        await pumpEventQueue();
        final lost = log.last as DrawHoldLost;
        expect(lost.view.revealed, 0);
        expect(failures(), [ReadingFailureKind.holdLost]);
        expect(fakes.readings.submitted, isEmpty);

        await controller.resumeAfterHoldLost();
        await pumpEventQueue();
        expect(log.last, isA<DrawRevealing>());
        await controller.revealAll();
        await pumpEventQueue();
        final done = log.last as DrawCompleted;
        expect(done.reading.draw, lost.view.draw);
        expect(fakes.readings.holds.map((h) => h.$1).toSet(), {kTestReadingId});
      },
    );

    test('a 409 from the submit interrupts the reveal', () async {
      final (_, log, controller) = await ready(aiSession());
      fakes.readings.failNextWorkerCall(const Failure.holdConflict());
      await controller.drawForMe();
      await pumpEventQueue();
      expect(log.last, isA<DrawHoldLost>());
    });

    test('a new hold still refused stays holdLost', () async {
      final (_, log, controller) = await ready(aiSession());
      fakes.readings.failNextWorkerCall(const Failure.holdConflict());
      await controller.drawForMe();
      await pumpEventQueue();
      fakes.readings.failNextWorkerCall(
        const Failure.insufficientCredits(reason: InsufficientReason.noCredits),
      );
      await controller.resumeAfterHoldLost();
      expect(log.last, isA<DrawHoldLost>());
    });
  });

  group('declined and handed back', () {
    Future<(ProviderContainer, StateLog<DrawState>)> declined(
      SafetyInfo? safety,
    ) async {
      final (container, log, controller) = await ready(aiSession());
      fakes.readings.refuseNext(safety: safety);
      await controller.drawForMe();
      await pumpEventQueue();
      await controller.revealAll();
      await pumpEventQueue();
      return (container, log);
    }

    test('crisis → S27 at once, even mid-reveal', () async {
      final (_, log, controller) = await ready(aiSession());
      fakes.readings.refuseNext(
        safety: const SafetyInfo(
          category: RefusalCategory.selfHarm,
          messageKey: 'safetyDeclinedSelfHarm',
          canRephrase: false,
        ),
      );
      await controller.drawForMe();
      await pumpEventQueue();
      final crisis = log.last as DrawCrisis;
      expect(crisis.safety.category, RefusalCategory.selfHarm);
      final refused = eventsOf<ReadingRefusedEvent>(fakes).single;
      expect(refused.category, RefusalCategory.selfHarm);
    });

    test('declined with canRephrase goes back to S07', () async {
      final (container, log) = await declined(
        const SafetyInfo(
          category: RefusalCategory.health,
          messageKey: 'safetyDeclinedHealth',
          canRephrase: true,
        ),
      );
      expect(log.last, isA<DrawReturnedToQuestion>());
      expect(
        container.read(readingHandoffProvider),
        isA<ReadingHandoffDeclined>(),
      );
    });

    test('a decline without details is refused(other)', () async {
      final (container, _) = await declined(null);
      final handoff = container.read(readingHandoffProvider)!;
      expect(
        (handoff as ReadingHandoffDeclined).safety.category,
        RefusalCategory.other,
      );
    });

    for (final (failure, kind) in [
      (
        const Failure.readingsPaused(reason: PausedReason.freeStop),
        ReadingHandoffPaused,
      ),
      (const Failure.aiConsentRequired(), ReadingHandoffConsent),
      (const Failure.aiUnavailableRegion(), ReadingHandoffRegion),
    ]) {
      test('${failure.code} is handed back to S07', () async {
        final (container, log, controller) = await ready(aiSession());
        fakes.readings.failNextWorkerCall(failure);
        await controller.drawForMe();
        await pumpEventQueue();
        await controller.revealAll();
        await pumpEventQueue();
        expect(log.last, isA<DrawReturnedToQuestion>());
        expect(container.read(readingHandoffProvider).runtimeType, kind);
      });
    }
  });

  group('Classic reading (F8)', () {
    test('no hold, no Worker call; saved as classic', () async {
      final (_, log, controller) = await ready(classicSession());
      await controller.drawForMe();
      expect(log.last, isA<DrawRevealing>());
      await controller.revealAll();
      await pumpEventQueue();
      final done = log.last as DrawCompleted;
      expect(done.view.classic, isTrue);
      expect(done.reading.status, isA<ReadingStatusClassic>());
      expect(fakes.readings.holds, isEmpty);
      expect(fakes.readings.submitted, isEmpty);
      expect(
        eventsOf<ClassicReadingCompletedEvent>(fakes).single.reason,
        ClassicReadingReason.noConsent,
      );
    });

    test('a Classic preset is drawn as is', () async {
      final session = classicSession().copyWith(
        spread: spreadOf('single'),
        presetCards: const [
          PresetCard(cardId: CardId('cups_03'), reversed: false),
        ],
      );
      final (_, log, _) = openWith(session);
      await pumpEventQueue();
      expect(
        (log.last as DrawShuffling).view.draw.cards.single.cardId,
        const CardId('cups_03'),
      );
    });

    test('a failed save is failed with the cards kept', () async {
      final (_, log, controller) = await ready(classicSession());
      fakes.readings.failNext(const Failure.storage(), on: 'saveClassic');
      await controller.drawForMe();
      await controller.revealAll();
      await pumpEventQueue();
      expect((log.last as DrawFailed).view, isNotNull);
    });
  });

  group('resume (Journal "Finish reading")', () {
    ReadingSession resumeSession() => ReadingSession(
      spread: spreadOf('three_ppf'),
      source: ReadingFlowSource.journalRetry,
      locale: 'en',
      resumeReadingId: kTestReadingId,
    );

    test('a pending reading is fetched and shown', () async {
      fakes.journal.putReading(
        aReading().withStatus(const ReadingStatus.pending()).build(),
      );
      final (_, log, _) = openWith(resumeSession());
      await pumpEventQueue();
      expect(log.last, isA<DrawCompleted>());
      expect(fakes.readings.calls, contains('resume'));
    });

    test('a still-pending reading is retried with the same cards', () async {
      fakes.journal.putReading(
        aReading().withStatus(const ReadingStatus.pending()).build(),
      );
      fakes.readings.stayPendingNext();
      final (_, log, _) = openWith(resumeSession());
      await pumpEventQueue();
      expect(log.last, isA<DrawCompleted>());
      expect(fakes.readings.holds.single.$1, kTestReadingId);
    });

    test('an expired reading is deliveryExpired', () async {
      fakes.journal.putReading(
        aReading().withStatus(const ReadingStatus.pending()).build(),
      );
      fakes.readings.failNextWorkerCall(
        const Failure.readingExpiredRefunded(),
      );
      final (_, log, _) = openWith(resumeSession());
      await pumpEventQueue();
      expect(log.last, isA<DrawDeliveryExpired>());
    });

    test('a failed reading is retried', () async {
      fakes.journal.putReading(
        aReading()
            .withStatus(const ReadingStatus.failed(Failure.aiUnavailable()))
            .build(),
      );
      final (_, log, _) = openWith(resumeSession());
      await pumpEventQueue();
      expect(log.last, isA<DrawCompleted>());
    });

    test('a missing reading is failed', () async {
      final (_, log, _) = openWith(resumeSession());
      await pumpEventQueue();
      expect(log.last, isA<DrawFailed>());
    });
  });
}
