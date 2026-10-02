import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/share_reading_use_case.dart';
import 'package:taro/features/reading/controller/classic_reading_controller.dart';
import 'package:taro/features/reading/controller/reading_result_controller.dart';
import 'package:taro/features/reading/controller/reading_session.dart';
import 'package:taro/features/reading/controller/report_reading_controller.dart';
import 'package:taro/features/reading/controller/spread_picker_controller.dart';
import 'package:taro_core/taro_core.dart';

import '../feature_test_support.dart';

const _copy = ShareCopy(
  disclaimerLine: 'For reflection only.',
  questionLabel: 'My question',
  reversedLabel: 'Reversed',
  fallbackTitle: 'Past · Present · Future',
);

void main() {
  late TaroFakes fakes;

  setUp(() => fakes = aiReadyFakes());

  group('ReadingSessionController', () {
    test(
      'resume starts a journal-retry session for a pending reading',
      () async {
        fakes.journal.putReading(
          aReading().withStatus(const ReadingStatus.pending()).build(),
        );
        final container = fakes.container();
        final ok = await container
            .read(readingSessionProvider.notifier)
            .resume(kTestReadingId);
        expect(ok, isTrue);
        final session = container.read(readingSessionProvider)!;
        expect(session.resumeReadingId, kTestReadingId);
        expect(session.source, ReadingFlowSource.journalRetry);
        expect(
          eventsOf<ReadingFlowStartedEvent>(fakes).single.source,
          ReadingFlowSource.journalRetry,
        );
        container.read(readingSessionProvider.notifier).clear();
        expect(container.read(readingSessionProvider), isNull);
      },
    );

    test(
      'resume refuses missing, complete and unknown-spread readings',
      () async {
        final container = fakes.container();
        final sessions = container.read(readingSessionProvider.notifier);
        expect(await sessions.resume(kTestReadingId), isFalse);
        fakes.journal.putReading(aReading().build());
        expect(await sessions.resume(kTestReadingId), isFalse);
        fakes.journal.putReading(
          aReading().withStatus(const ReadingStatus.pending()).build(),
        );
        fakes.content.bundledSpreads = [];
        expect(await sessions.resume(kTestReadingId), isFalse);
      },
    );

    test('the handoff is taken once', () {
      final container = fakes.container();
      final handoffs = container.read(readingHandoffProvider.notifier)
        ..post(const ReadingHandoff.consentRequired());
      expect(handoffs.take(), isA<ReadingHandoffConsent>());
      expect(handoffs.take(), isNull);
    });
  });

  group('SpreadPickerController (S06)', () {
    test('lists the spreads, hiding those disabled by config', () async {
      final container = fakes.container();
      final log = StateLog(container, spreadPickerControllerProvider);
      expect(log.last, isA<SpreadPickerLoading>());
      await pumpEventQueue();
      expect((log.last as SpreadPickerContent).spreads, hasLength(6));
      fakes.config.current = aRemoteConfig().withSpreadsEnabled([
        'single',
        'three_ppf',
      ]).build();
      await pumpEventQueue();
      final ids = (log.last as SpreadPickerContent).spreads.map((s) => s.id);
      expect(ids, [const SpreadId('single'), const SpreadId('three_ppf')]);
    });

    test('failed, then retry', () async {
      fakes.content.failNext(const Failure.storage(), on: 'spreads');
      final container = fakes.container();
      final log = StateLog(container, spreadPickerControllerProvider);
      await pumpEventQueue();
      expect(log.last, isA<SpreadPickerFailed>());
      await container.read(spreadPickerControllerProvider.notifier).retry();
      expect(log.last, isA<SpreadPickerContent>());
    });

    test(
      'a bundled spread marked disabled is hidden, unknown ones last',
      () async {
        fakes.content.bundledSpreads = [
          aSpread('celtic_cross').build().copyWith(enabled: false),
          aSpread('single').build(),
          aSpread().build().copyWith(id: const SpreadId('extra')),
        ];
        fakes.config.current = aRemoteConfig()
            .withSpreadsEnabled(['single'])
            .build()
            .copyWith(
              spreadsEnabled: const [SpreadId('extra'), SpreadId('single')],
            );
        final container = fakes.container();
        final log = StateLog(container, spreadPickerControllerProvider);
        await pumpEventQueue();
        expect(
          (log.last as SpreadPickerContent).spreads.map((s) => s.id),
          [const SpreadId('single'), const SpreadId('extra')],
        );
      },
    );
  });

  group('ReadingResultController (S09)', () {
    const args = ReadingResultArgs(id: kTestReadingId);

    test('loadingFromStorage → content; reading_viewed once', () async {
      fakes.journal.putReading(aReading().build());
      final container = fakes.container();
      final log = StateLog(container, readingResultControllerProvider(args));
      expect(log.last, isA<ReadingResultLoadingFromStorage>());
      await pumpEventQueue();
      final content = log.last as ReadingResultContent;
      expect(content.view.cardTexts, hasLength(3));
      expect(content.view.canReport, isTrue);
      expect(content.view.reported, isFalse);
      expect(
        eventsOf<ReadingViewedEvent>(fakes).single.origin,
        ReadingViewOrigin.fresh,
      );
    });

    test('👍 → ratingGiven, review policy fed; 👎 keeps its reason', () async {
      fakes.journal.putReading(aReading().build());
      final container = fakes.container();
      final log = StateLog(container, readingResultControllerProvider(args));
      await pumpEventQueue();
      final controller = container.read(
        readingResultControllerProvider(args).notifier,
      );
      await controller.rate(Rating.up, reason: RatingReason.tone);
      await pumpEventQueue();
      expect(log.last, isA<ReadingResultRatingGiven>());
      expect(fakes.review.triggers, [ReviewTrigger.positiveRating]);
      expect(eventsOf<ReadingRatedEvent>(fakes).single.reason, isNull);
      await controller.rate(Rating.down, reason: RatingReason.tone);
      await pumpEventQueue();
      final rated = (log.last as ReadingResultRatingGiven).view.reading;
      expect(rated.ratingReason, RatingReason.tone);
      expect(fakes.review.triggers, hasLength(1));
      expect(eventsOf<ReadingViewedEvent>(fakes), hasLength(1));
    });

    test('a Classic reading never feeds the review prompt', () async {
      fakes.journal.putReading(
        aReading().withStatus(const ReadingStatus.classic()).build(),
      );
      final container = fakes.container();
      StateLog(container, readingResultControllerProvider(args));
      await pumpEventQueue();
      await container
          .read(readingResultControllerProvider(args).notifier)
          .rate(Rating.up);
      expect(fakes.review.triggers, isEmpty);
    });

    test('favourite and reflection prompt', () async {
      fakes.journal.putReading(aReading().build());
      final container = fakes.container();
      StateLog(container, readingResultControllerProvider(args));
      await pumpEventQueue();
      final controller = container.read(
        readingResultControllerProvider(args).notifier,
      );
      await controller.toggleFavourite();
      expect(fakes.journal.readings[kTestReadingId]!.favourite, isTrue);
      expect(eventsOf<JournalFavouriteToggledEvent>(fakes).single.on, isTrue);
      await controller.useReflectionPrompt();
      expect(eventsOf<ReflectionPromptUsedEvent>(fakes), hasLength(1));
    });

    test('share: sharing, then back; the question only when asked', () async {
      fakes.journal.putReading(aReading().build());
      final container = fakes.container();
      final log = StateLog(container, readingResultControllerProvider(args));
      await pumpEventQueue();
      final controller = container.read(
        readingResultControllerProvider(args).notifier,
      );
      final shared = await controller.share(_copy, includeQuestion: false);
      expect(shared.isOk, isTrue);
      expect(log.states.whereType<ReadingResultSharing>(), isNotEmpty);
      expect(log.last, isA<ReadingResultContent>());
      final text = utf8.decode(fakes.files.shared.single.bytes);
      expect(text, isNot(contains(kTestQuestion)));
      expect(text, contains('For reflection only.'));
      expect(
        eventsOf<ReadingSharedEvent>(fakes).single.includeQuestion,
        isFalse,
      );
      await controller.share(_copy, includeQuestion: true);
      expect(
        utf8.decode(fakes.files.shared.last.bytes),
        contains('My question: $kTestQuestion'),
      );
    });

    test('a failed share logs nothing', () async {
      fakes.journal.putReading(aReading().build());
      fakes.files.failNext(const Failure.storage(), on: 'share');
      final container = fakes.container();
      StateLog(container, readingResultControllerProvider(args));
      await pumpEventQueue();
      final shared = await container
          .read(readingResultControllerProvider(args).notifier)
          .share(_copy, includeQuestion: false);
      expect(shared.isOk, isFalse);
      expect(eventsOf<ReadingSharedEvent>(fakes), isEmpty);
    });

    test('actions before the reading loads do nothing', () async {
      final container = fakes.container();
      final log = StateLog(container, readingResultControllerProvider(args));
      await pumpEventQueue();
      expect(log.last, isA<ReadingResultNotFound>());
      final controller = container.read(
        readingResultControllerProvider(args).notifier,
      );
      expect((await controller.rate(Rating.up)).isOk, isTrue);
      expect((await controller.toggleFavourite()).isOk, isTrue);
      await controller.useReflectionPrompt();
      expect(
        (await controller.share(_copy, includeQuestion: true)).isOk,
        isTrue,
      );
      expect(fakes.analytics.events, isEmpty);
    });

    test('a reported reading cannot be reported again', () async {
      fakes.journal.putReading(aReading().build().copyWith(reported: true));
      final container = fakes.container();
      final log = StateLog(container, readingResultControllerProvider(args));
      await pumpEventQueue();
      final view = (log.last as ReadingResultContent).view;
      expect(view.canReport, isFalse);
      expect(view.reported, isTrue);
    });

    test('missing card text is failed', () async {
      fakes.journal.putReading(aReading().build());
      fakes.content.failNext(const Failure.storage(), on: 'cardText');
      final container = fakes.container();
      final log = StateLog(container, readingResultControllerProvider(args));
      await pumpEventQueue();
      expect(log.last, isA<ReadingResultFailed>());
    });
  });

  group('ShareReadingUseCase (PR19)', () {
    test('card names, summary, excerpt and the disclaimer', () async {
      final useCase = ShareReadingUseCase(
        content: fakes.content,
        share: (_) async => const Result.ok(null),
      );
      final draw = aDraw();
      final reading = aReading()
          .withDraw(
            draw.copyWith(
              cards: [
                draw.cards.first.copyWith(reversed: true),
                ...draw.cards.skip(1),
              ],
            ),
          )
          .withContent(
            aReadingContent(draw: draw).copyWith(synthesis: 'word ' * 100),
          )
          .build();
      final text = (await useCase.buildText(
        reading,
        _copy,
        locale: 'en',
        includeQuestion: false,
      )).valueOrNull!;
      final name = aCardText(draw.cards.first.cardId).name;
      expect(text, contains('$name (Reversed)'));
      expect(text, contains(reading.content!.summary));
      expect(text, contains('…'));
      expect(text.endsWith('For reflection only.'), isTrue);
      expect(text, isNot(contains(kTestQuestion)));
    });

    test(
      'a Classic reading uses the fallback title; short text kept',
      () async {
        final useCase = ShareReadingUseCase(
          content: fakes.content,
          share: (_) async => const Result.ok(null),
        );
        final classic = aReading()
            .withStatus(const ReadingStatus.classic())
            .withContent(null)
            .build();
        final text = (await useCase.buildText(
          classic,
          _copy,
          locale: 'en',
          includeQuestion: true,
        )).valueOrNull!;
        expect(text.startsWith(_copy.fallbackTitle), isTrue);
        final short = aReading()
            .withContent(aReadingContent().copyWith(synthesis: 'Short.'))
            .build();
        expect(
          (await useCase.buildText(
            short,
            _copy,
            locale: 'en',
            includeQuestion: false,
          )).valueOrNull,
          contains('Short.'),
        );
        final unbroken = aReading()
            .withContent(aReadingContent().copyWith(synthesis: 'x' * 400))
            .build();
        expect(
          (await useCase.buildText(
            unbroken,
            _copy,
            locale: 'en',
            includeQuestion: false,
          )).valueOrNull,
          contains('${'x' * 280}…'),
        );
        final emoji = aReading()
            .withContent(
              aReadingContent().copyWith(synthesis: '${'x' * 279}🙂 tail'),
            )
            .build();
        expect(
          (await useCase.buildText(
            emoji,
            _copy,
            locale: 'en',
            includeQuestion: false,
          )).valueOrNull,
          contains('${'x' * 279}…'),
        );
        final blank = aReading()
            .withContent(aReadingContent().copyWith(synthesis: '  '))
            .build();
        expect(
          (await useCase.buildText(
            blank,
            _copy,
            locale: 'en',
            includeQuestion: false,
          )).isOk,
          isTrue,
        );
      },
    );

    test('an unreadable card text fails', () async {
      fakes.content.failNext(const Failure.storage(), on: 'cardText');
      final useCase = ShareReadingUseCase(
        content: fakes.content,
        share: (_) async => const Result.ok(null),
      );
      final result = await useCase(
        aReading().build(),
        _copy,
        locale: 'en',
        includeQuestion: false,
      );
      expect(result.isOk, isFalse);
    });
  });

  group('ClassicReadingController (S32)', () {
    test('per position: card text and slot; AI offered when allowed', () async {
      fakes.journal.putReading(
        aReading().withStatus(const ReadingStatus.classic()).build(),
      );
      final container = fakes.container();
      final log = StateLog(
        container,
        classicReadingControllerProvider(kTestReadingId),
      );
      expect(log.last, isA<ClassicReadingLoadingFromStorage>());
      await pumpEventQueue();
      final view = (log.last as ClassicReadingContent).view;
      expect(view.positions, hasLength(3));
      final first = view.positions.first;
      expect(first.position, isNotNull);
      expect(first.short, first.text.short(reversed: first.card.reversed));
      expect(
        first.meaning,
        first.text.meaning(reversed: first.card.reversed),
      );
      expect(view.aiAvailable, isTrue);
      expect(fakes.readings.holds, isEmpty);
    });

    test('no AI offer when the gate would not allow one', () async {
      fakes = TaroFakes();
      fakes.journal.putReading(
        aReading().withStatus(const ReadingStatus.classic()).build(),
      );
      final container = fakes.container();
      final log = StateLog(
        container,
        classicReadingControllerProvider(kTestReadingId),
      );
      await pumpEventQueue();
      expect((log.last as ClassicReadingContent).view.aiAvailable, isFalse);
    });

    test('an unknown spread still shows the cards', () async {
      fakes.journal.putReading(
        aReading().withStatus(const ReadingStatus.classic()).build(),
      );
      fakes.content.bundledSpreads = [];
      final container = fakes.container();
      final log = StateLog(
        container,
        classicReadingControllerProvider(kTestReadingId),
      );
      await pumpEventQueue();
      final view = (log.last as ClassicReadingContent).view;
      expect(view.positions.first.position, isNull);
    });

    test('notFound and failed', () async {
      final container = fakes.container();
      final log = StateLog(
        container,
        classicReadingControllerProvider(kTestReadingId),
      );
      await pumpEventQueue();
      expect(log.last, isA<ClassicReadingNotFound>());

      fakes.readings.failNext(const Failure.storage(), on: 'get');
      final other = fakes.container();
      final failed = StateLog(
        other,
        classicReadingControllerProvider(kTestReadingId),
      );
      await pumpEventQueue();
      expect(failed.last, isA<ClassicReadingFailed>());

      fakes.journal.putReading(aReading().build());
      fakes.content.failNext(const Failure.storage(), on: 'cardText');
      final third = fakes.container();
      final text = StateLog(
        third,
        classicReadingControllerProvider(kTestReadingId),
      );
      await pumpEventQueue();
      expect(text.last, isA<ClassicReadingFailed>());
    });
  });

  group('ReportReadingController (S33)', () {
    test('editing → submitting → submitted; reported flag set', () async {
      fakes.journal.putReading(aReading().build());
      final container = fakes.container();
      final log = StateLog(
        container,
        reportReadingControllerProvider(kTestReadingId),
      );
      await pumpEventQueue();
      final controller = container.read(
        reportReadingControllerProvider(kTestReadingId).notifier,
      );
      expect((log.last as ReportReadingEditing).draft.canSend, isFalse);
      await controller.submit();
      expect(log.last, isA<ReportReadingEditing>());
      controller
        ..selectReason(ReportReason.harmfulAdvice)
        ..updateNote('x' * 600);
      expect((log.last as ReportReadingEditing).draft.note.length, 500);
      await controller.submit();
      expect(log.states.whereType<ReportReadingSubmitting>(), hasLength(1));
      expect(log.last, isA<ReportReadingSubmitted>());
      expect(fakes.journal.readings[kTestReadingId]!.reported, isTrue);
      final event = eventsOf<ReadingReportedEvent>(fakes).single;
      expect(event.reason, ReportReason.harmfulAdvice);
      expect(event.spread, AnalyticsSpread.threePpf);
      controller.selectReason(ReportReason.other);
      expect(log.last, isA<ReportReadingSubmitted>());
    });

    test('alreadyReported', () async {
      fakes.journal.putReading(aReading().build().copyWith(reported: true));
      final container = fakes.container();
      final log = StateLog(
        container,
        reportReadingControllerProvider(kTestReadingId),
      );
      await pumpEventQueue();
      expect(log.last, isA<ReportReadingAlreadyReported>());
    });

    test('offline disables Send and follows connectivity', () async {
      fakes.journal.putReading(aReading().build());
      fakes.connectivity.setOnline(online: false);
      final container = fakes.container();
      final log = StateLog(
        container,
        reportReadingControllerProvider(kTestReadingId),
      );
      await pumpEventQueue();
      final controller = container.read(
        reportReadingControllerProvider(kTestReadingId).notifier,
      )..selectReason(ReportReason.offensive);
      expect(log.last, isA<ReportReadingOffline>());
      await controller.submit();
      expect(fakes.reports.reports, isEmpty);
      fakes.connectivity.setOnline(online: true);
      await pumpEventQueue();
      expect(log.last, isA<ReportReadingEditing>());
      fakes.connectivity.setOnline(online: false);
      await pumpEventQueue();
      expect(log.last, isA<ReportReadingOffline>());
    });

    test('rateLimited, network, failed then retry', () async {
      fakes.journal.putReading(aReading().build());
      final container = fakes.container();
      final log = StateLog(
        container,
        reportReadingControllerProvider(kTestReadingId),
      );
      await pumpEventQueue();
      final controller = container.read(
        reportReadingControllerProvider(kTestReadingId).notifier,
      )..selectReason(ReportReason.sexual);
      fakes.reports.failNext(
        const Failure.rateLimited(reason: RateLimitReason.reportLimit),
      );
      await controller.submit();
      expect(log.last, isA<ReportReadingRateLimited>());

      controller.selectReason(ReportReason.hateful);
      fakes.reports.failNext(const Failure.network());
      await controller.submit();
      expect(log.last, isA<ReportReadingFailed>());

      controller.selectReason(ReportReason.hateful);
      fakes.reports.failNext(const Failure.server(status: 500));
      await controller.submit();
      expect(log.last, isA<ReportReadingFailed>());
      await controller.submit();
      expect(log.last, isA<ReportReadingSubmitted>());
    });

    test('a vanished reading still reports with an unknown spread', () async {
      fakes.journal.putReading(aReading().build());
      final container = fakes.container();
      StateLog(container, reportReadingControllerProvider(kTestReadingId));
      fakes.readings.failNext(const Failure.storage(), on: 'get');
      await pumpEventQueue();
      final controller = container.read(
        reportReadingControllerProvider(kTestReadingId).notifier,
      )..selectReason(ReportReason.other);
      await controller.submit();
      expect(
        eventsOf<ReadingReportedEvent>(fakes).single.spread,
        AnalyticsSpread.unknown,
      );
    });
  });
}
