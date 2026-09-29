import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../fakes/builders/builders.dart';
import 'contract_support.dart';

/// What the `ReadingRepository` contract needs besides the port.
abstract interface class ReadingRepositoryHarness {
  /// The repository under test (empty journal, a Worker that delivers).
  ReadingRepository get subject;

  /// Makes the next Worker call fail with [failure] (transport level).
  void failNextWorkerCall(Failure failure);

  /// Moves the device clock forward by [by].
  void advance(Duration by);
}

/// The `ReadingRepository` contract (02 §5, §9.3, RC42, RC50, RC51).
void runReadingRepositoryContract(ReadingRepositoryHarness Function() create) {
  group('ReadingRepository contract', () {
    late ReadingRepositoryHarness harness;
    late ReadingRepository readings;
    final spread = aSpread().build();

    setUp(() {
      harness = create();
      readings = harness.subject;
    });

    Reading pendingReading() => aReading().pending().build();

    test('get of an unknown reading is null', () async {
      expect(expectOk(await readings.get(kTestReadingId)), isNull);
    });

    test('hold reserves a credit for the reading ID', () async {
      final hold = expectOk(
        await readings.hold(kTestReadingId, spread, locale: 'en'),
      );
      expect(hold.readingId, kTestReadingId);
      expect(hold.expiresAt.isAfter(hold.balance.serverTime), isTrue);
      final renewed = expectOk(
        await readings.hold(kTestReadingId, spread, locale: 'en'),
      );
      expect(renewed.readingId, kTestReadingId);
    });

    test('submit stores and returns the delivered reading', () async {
      final pending = pendingReading();
      final delivered = expectOk(await readings.submit(pending));
      expect(delivered.id, pending.id);
      expect(delivered.draw, pending.draw);
      expect(
        delivered.status,
        anyOf(isA<ReadingStatusComplete>(), isA<ReadingStatusRefused>()),
      );
      expect(expectOk(await readings.get(pending.id)), delivered);
      expect(expectOk(await readings.pending()), isEmpty);
    });

    test('a transport failure leaves the reading pending to resume', () async {
      harness.failNextWorkerCall(const Failure.network());
      final pending = pendingReading();
      expect(expectErr(await readings.submit(pending)), isA<NetworkFailure>());
      final stored = expectOk(await readings.pending());
      expect([for (final r in stored) r.id], [pending.id]);
      expect(stored.single.draw, pending.draw);

      final resumed = expectOk(await readings.resume(pending.id));
      expect(resumed.status, isNot(isA<ReadingStatusPending>()));
      expect(expectOk(await readings.pending()), isEmpty);
    });

    test('ack marks the delivery acknowledged', () async {
      final delivered = expectOk(await readings.submit(pendingReading()));
      expectOk(await readings.ack(delivered.id));
      final stored = expectOk(await readings.get(delivered.id));
      expect(stored!.deliveryAcked, isTrue);
    });

    test('a failed ack is queued and flushed later', () async {
      final delivered = expectOk(await readings.submit(pendingReading()));
      harness.failNextWorkerCall(const Failure.network());
      expect(
        expectErr(await readings.ack(delivered.id)),
        isA<NetworkFailure>(),
      );
      expect(expectOk(await readings.flushPendingAcks()), 1);
      expect(expectOk(await readings.flushPendingAcks()), 0);
      expect(expectOk(await readings.get(delivered.id))!.deliveryAcked, isTrue);
    });

    test('saveClassic stores a Classic reading without the Worker', () async {
      final classic = aReading().classic().build();
      harness.failNextWorkerCall(const Failure.network());
      expect(expectOk(await readings.saveClassic(classic)), classic);
      expect(expectOk(await readings.get(classic.id)), classic);
    });

    test('note, favourite, rating and reported are stored', () async {
      final classic = aReading().classic().build();
      await readings.saveClassic(classic);
      expectOk(await readings.setNote(classic.id, 'Trust the process'));
      expectOk(await readings.setFavourite(classic.id, favourite: true));
      expectOk(
        await readings.setRating(
          classic.id,
          Rating.down,
          reason: RatingReason.tooGeneric,
        ),
      );
      expectOk(await readings.markReported(classic.id));
      final stored = expectOk(await readings.get(classic.id))!;
      expect(stored.note, 'Trust the process');
      expect(stored.favourite, isTrue);
      expect(stored.rating, Rating.down);
      expect(stored.ratingReason, RatingReason.tooGeneric);
      expect(stored.reported, isTrue);
      expect(stored.updatedAt.isBefore(classic.updatedAt), isFalse);

      expectOk(await readings.setNote(classic.id, null));
      expectOk(await readings.setRating(classic.id, null));
      final cleared = expectOk(await readings.get(classic.id))!;
      expect(cleared.note, isNull);
      expect(cleared.rating, isNull);
    });

    test('watch follows a reading until it is deleted', () async {
      final classic = aReading().classic().build();
      final seen = <Reading?>[];
      final sub = readings.watch(classic.id).listen(seen.add);
      await settle();
      await readings.saveClassic(classic);
      await settle();
      expectOk(await readings.delete(classic.id));
      await settle();
      await sub.cancel();
      expect(seen, [null, classic, null]);
      expect(expectOk(await readings.get(classic.id)), isNull);
    });

    test('undoDelete restores a reading within the undo window', () async {
      final classic = aReading().classic().withNote('keep me').build();
      expect(expectOk(await readings.undoDelete(classic.id)), isFalse);
      await readings.saveClassic(classic);
      expectOk(await readings.delete(classic.id));
      harness.advance(
        ReadingRepository.undoWindow - const Duration(seconds: 1),
      );
      expect(expectOk(await readings.undoDelete(classic.id)), isTrue);
      expect(expectOk(await readings.get(classic.id)), classic);
      expect(expectOk(await readings.undoDelete(classic.id)), isFalse);
    });

    test('undoDelete after the undo window restores nothing', () async {
      final classic = aReading().classic().build();
      await readings.saveClassic(classic);
      expectOk(await readings.delete(classic.id));
      harness.advance(ReadingRepository.undoWindow);
      expect(expectOk(await readings.undoDelete(classic.id)), isFalse);
      expect(expectOk(await readings.get(classic.id)), isNull);
    });
  });
}
