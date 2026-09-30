import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:taro/services/review/in_app_review_prompter.dart';
import 'package:taro/services/review/no_op_review_prompter.dart';
import 'package:taro/services/review/review_prompt_ledger.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';

final class _Review extends Fake implements InAppReview {
  bool available = true;
  int requests = 0;
  Exception? error;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async {
    if (error != null) throw error!;
    requests++;
  }
}

/// A ledger that cannot read or write.
final class _BrokenLedger implements ReviewPromptLedger {
  _BrokenLedger({this.readable = false});

  final bool readable;

  @override
  Future<ReviewPromptState?> read() async =>
      readable ? const ReviewPromptState(positiveRatings: 9) : null;

  @override
  Future<bool> write(ReviewPromptState state) async => false;
}

void main() {
  const up = ReviewTrigger.positiveRating;
  late _Review review;
  late FakeClock clock;
  late FakeRemoteConfigRepository config;
  late InMemoryReviewPromptLedger ledger;
  late CapturingLogger logger;

  setUp(() {
    review = _Review();
    clock = FakeClock();
    config = FakeRemoteConfigRepository();
    ledger = InMemoryReviewPromptLedger();
    logger = CapturingLogger();
  });

  InAppReviewPrompter prompter({ReviewPromptLedger? store}) =>
      InAppReviewPrompter(
        clock: clock,
        config: config,
        ledger: store ?? ledger,
        logger: logger,
        review: review,
      );

  Future<void> rate(InAppReviewPrompter p, int times) async {
    for (var i = 0; i < times; i++) {
      await p.maybePrompt(up);
    }
  }

  group('InAppReviewPrompter', () {
    runReviewPrompterContract(
      () => InAppReviewPrompter(
        clock: FakeClock(),
        config: FakeRemoteConfigRepository(),
        ledger: InMemoryReviewPromptLedger(),
        logger: CapturingLogger(),
        review: _Review(),
      ),
    );

    test('prompts on the 3rd positive rating, not before', () async {
      final p = prompter();
      await rate(p, 2);
      expect(review.requests, 0);
      expect(ledger.state.positiveRatings, 2);
      await rate(p, 1);
      expect(review.requests, 1);
      expect(ledger.state, ReviewPromptState(lastPromptAt: clock.now()));
    });

    test('follows review.promptAfterPositiveReadings', () async {
      config.current = RemoteConfig.defaults.copyWith(
        reviewPromptAfterPositiveReadings: 1,
      );
      await rate(prompter(), 1);
      expect(review.requests, 1);
    });

    test('at most once per 120 days', () async {
      final p = prompter();
      await rate(p, 3);
      clock.advance(const Duration(days: 60));
      await rate(p, 5);
      expect(review.requests, 1);
      clock.advance(const Duration(days: 59, hours: 23));
      await rate(p, 1);
      expect(review.requests, 1);
      clock.advance(const Duration(hours: 1));
      await rate(p, 1);
      expect(review.requests, 2);
    });

    test('never after a refusal', () async {
      final p = prompter();
      await p.recordRefusal();
      await p.recordRefusal();
      await rate(p, 10);
      expect(review.requests, 0);
      expect(ledger.state.refused, isTrue);
    });

    test('an unavailable store keeps counting without prompting', () async {
      review.available = false;
      final p = prompter();
      await rate(p, 4);
      expect(review.requests, 0);
      expect(ledger.state.positiveRatings, 4);
      expect(ledger.state.lastPromptAt, isNull);
      review.available = true;
      await rate(p, 1);
      expect(review.requests, 1);
    });

    test('a platform error is logged and counts as prompted', () async {
      review.error = PlatformException(code: 'review');
      await rate(prompter(), 3);
      expect(logger.messages, ['review request failed']);
      expect(ledger.state.lastPromptAt, clock.now());
    });

    test('an unreadable ledger never prompts', () async {
      final p = prompter(store: _BrokenLedger());
      await rate(p, 5);
      await p.recordRefusal();
      expect(review.requests, 0);
    });

    test('an unwritable ledger never prompts', () async {
      await rate(prompter(store: _BrokenLedger(readable: true)), 1);
      expect(review.requests, 0);
    });

    test('concurrent triggers are counted one by one', () async {
      final p = prompter();
      await Future.wait([for (var i = 0; i < 3; i++) p.maybePrompt(up)]);
      expect(review.requests, 1);
    });

    test('defaults to the plugin singleton', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      expect(
        InAppReviewPrompter(
          clock: clock,
          config: config,
          ledger: ledger,
          logger: logger,
        ),
        isA<ReviewPrompter>(),
      );
    });
  });

  group('NoOpReviewPrompter', () {
    runReviewPrompterContract(NoOpReviewPrompter.new);
  });

  group('ReviewPromptState', () {
    test('round-trips through JSON', () {
      final state = ReviewPromptState(
        positiveRatings: 2,
        lastPromptAt: DateTime.utc(2026, 1, 2, 3),
        refused: true,
      );
      expect(ReviewPromptState.fromJson(state.toJson()), state);
      expect(
        ReviewPromptState.fromJson(const ReviewPromptState().toJson()),
        const ReviewPromptState(),
      );
      expect(
        state.hashCode,
        ReviewPromptState.fromJson(state.toJson()).hashCode,
      );
    });
  });

  group('SecureStoreReviewPromptLedger', () {
    late InMemorySecureStore store;
    late SecureStoreReviewPromptLedger secure;

    setUp(() {
      store = InMemorySecureStore();
      secure = SecureStoreReviewPromptLedger(store);
    });

    test('starts fresh and persists under taro.review_prompt', () async {
      expect(await secure.read(), const ReviewPromptState());
      final state = ReviewPromptState(
        positiveRatings: 1,
        lastPromptAt: DateTime.utc(2026),
      );
      expect(await secure.write(state), isTrue);
      expect(await secure.read(), state);
      expect(
        expectOk(await store.read(SecureStoreReviewPromptLedger.key)),
        contains('positiveRatings'),
      );
    });

    test('a corrupt value starts over', () async {
      for (final raw in ['{', '[1]', '{"positiveRatings":"x"}']) {
        await store.write(SecureStoreReviewPromptLedger.key, raw);
        expect(await secure.read(), const ReviewPromptState());
      }
    });

    test('storage errors read as null and write as false', () async {
      store
        ..failNext(const Failure.storage(), on: 'read')
        ..failNext(const Failure.storage(), on: 'write');
      expect(await secure.read(), isNull);
      expect(await secure.write(const ReviewPromptState()), isFalse);
    });
  });
}
