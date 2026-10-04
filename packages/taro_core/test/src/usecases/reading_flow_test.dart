import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import '../../contracts/contract_support.dart';
import '../../fakes/fakes.dart';

void main() {
  late FakeClock clock;
  late FakeBalanceRepository balance;
  late FakeReadingRepository readings;
  late SequentialIdGenerator ids;
  late CapturingLogger logger;
  late FakeInstallRepository install;

  final spread = aSpread().build();

  setUp(() {
    clock = FakeClock();
    balance = FakeBalanceRepository(
      cached: aCreditBalance().withLedgerVersion(3).build(),
    );
    readings = FakeReadingRepository(clock: clock);
    ids = SequentialIdGenerator();
    logger = CapturingLogger();
    install = FakeInstallRepository();
  });

  group('RequestReading', () {
    late RequestReading request;

    setUp(() {
      request = RequestReading(
        readings: readings,
        balance: balance,
        install: install,
        ids: ids,
        clock: clock,
        logger: logger,
      );
    });

    group('hold', () {
      for (final failure in [
        const Failure.attestation(kind: AttestationFailureKind.keyInvalidated),
        const Failure.attestation(kind: AttestationFailureKind.rejected),
        const Failure.attestation(kind: AttestationFailureKind.transient),
        const Failure.sessionExpired(),
      ]) {
        test('a hold refused for the device (${failure.code}) repairs the '
            'registration and is tried once more with the same ID', () async {
          readings.failNextWorkerCall(failure);
          final hold = expectOk(await request.hold(spread, locale: 'en'));
          expect(install.calls, ['repairRegistration']);
          expect(readings.holds, hasLength(2));
          expect(readings.holds.first.$1, hold.readingId);
          expect(readings.holds.last.$1, hold.readingId);
          expect(balance.applied, hasLength(1));
          expect(
            logger.logged('reading hold refused: ', level: LogLevel.severe),
            isTrue,
          );
        });
      }

      test('the logged failure names the attestation kind only', () async {
        readings.failNextWorkerCall(
          const Failure.attestation(
            kind: AttestationFailureKind.keyInvalidated,
          ),
        );
        await request.hold(spread, locale: 'en');
        expect(
          logger.logged('ATTESTATION_FAILED(keyInvalidated)'),
          isTrue,
          reason: logger.records.map((r) => r.message).join('\n'),
        );
      });

      test('a failed repair returns the original failure without a second '
          'hold', () async {
        readings.failNextWorkerCall(
          const Failure.attestation(kind: AttestationFailureKind.rejected),
        );
        install.failNext(const Failure.network(), on: 'repairRegistration');
        expect(
          expectErr(await request.hold(spread, locale: 'en')),
          isA<AttestationFailure>(),
        );
        expect(readings.holds, hasLength(1));
        expect(balance.applied, isEmpty);
      });

      test('a hold still refused after the repair is returned and logged '
          '(no loop)', () async {
        const refused = Failure.attestation(
          kind: AttestationFailureKind.rejected,
        );
        readings
          ..failNextWorkerCall(refused)
          ..failNextWorkerCall(refused);
        expect(
          expectErr(await request.hold(spread, locale: 'en')),
          isA<AttestationFailure>(),
        );
        expect(install.calls, ['repairRegistration']);
        expect(readings.holds, hasLength(2));
        expect(logger.logged('reading hold refused after repair'), isTrue);
      });

      test('other failures never repair the registration', () async {
        readings.failNextWorkerCall(const Failure.network());
        expectErr(await request.hold(spread, locale: 'en'));
        expect(install.calls, isEmpty);
      });

      test('a new reading gets a fresh ID and applies the balance', () async {
        readings.holdBalance = aCreditBalance()
            .withFreeRemaining(0)
            .withLedgerVersion(4)
            .build();
        final hold = expectOk(await request.hold(spread, locale: 'de'));
        expect(hold.readingId.value, ids.issued.single);
        expect(readings.holds.single, (hold.readingId, spread.id, 'de'));
        expect(balance.cached?.ledgerVersion, 4);
      });

      test('renewal keeps the reading ID', () async {
        final hold = expectOk(
          await request.hold(spread, locale: 'en', readingId: kTestReadingId),
        );
        expect(hold.readingId, kTestReadingId);
        expect(ids.issued, isEmpty);
      });

      test(
        'a refused hold applies nothing (paywall before the draw)',
        () async {
          readings.failNextWorkerCall(
            const Failure.insufficientCredits(
              reason: InsufficientReason.noCredits,
            ),
          );
          expect(
            expectErr(await request.hold(spread, locale: 'en')),
            isA<InsufficientCreditsFailure>(),
          );
          expect(balance.applied, isEmpty);
        },
      );
    });

    group('ensureFresh', () {
      test('keeps a hold with enough time left', () async {
        final hold = aReadingHold();
        expect(
          expectOk(await request.ensureFresh(hold, spread, locale: 'en')),
          hold,
        );
        expect(readings.holds, isEmpty);
      });

      test('renews a hold under 120 s, same reading ID', () async {
        clock.advance(const Duration(minutes: 9));
        final renewed = expectOk(
          await request.ensureFresh(aReadingHold(), spread, locale: 'en'),
        );
        expect(renewed.readingId, kTestReadingId);
        expect(
          renewed.expiresAt,
          clock.now().add(readings.holdTtl),
        );
      });
    });

    group('submit', () {
      test('persists pending, delivers and acknowledges', () async {
        // 22:30Z is the next day in Kyiv.
        clock.setNow(DateTime.utc(2026, 9, 26, 22, 30));
        final hold = aReadingHold(chargeSource: ChargeSource.bonus);
        final draw = aDraw();
        final reading = expectOk(
          await request.submit(
            hold: hold,
            draw: draw,
            locale: 'en',
            question: '  Where next?  ',
          ),
        );
        final sent = readings.submitted.single;
        expect(sent.status, const ReadingStatus.pending());
        expect(sent.id, hold.readingId);
        expect(sent.draw, draw);
        expect(sent.question, 'Where next?');
        expect(sent.chargeSource, ChargeSource.bonus);
        expect(sent.localDate, '2026-09-27');
        expect(sent.createdAt, clock.now());
        expect(reading.status, const ReadingStatus.complete());
        expect(readings.acked, [hold.readingId]);
        expect(
          readings.journal.readings[hold.readingId]!.deliveryAcked,
          isTrue,
        );
      });

      test('a declined reading is acknowledged too', () async {
        readings.refuseNext();
        final reading = expectOk(
          await request.submit(
            hold: aReadingHold(),
            draw: aDraw(),
            locale: 'en',
          ),
        );
        expect(reading.status, isA<ReadingStatusRefused>());
        expect(readings.acked, hasLength(1));
      });

      test('a failed ack is queued and logged, not a failure', () async {
        readings.failNext(const Failure.network(), on: 'ack');
        expect(
          (await request.submit(
            hold: aReadingHold(),
            draw: aDraw(),
            locale: 'en',
          )).isOk,
          isTrue,
        );
        expect(readings.pendingAcks, [kTestReadingId]);
        expect(logger.logged('delivery ack queued'), isTrue);
      });

      test('a reading still generating is not acknowledged', () async {
        readings.stayPendingNext();
        expectOk(
          await request.submit(
            hold: aReadingHold(),
            draw: aDraw(),
            locale: 'en',
          ),
        );
        expect(readings.callCount('ack'), 0);
      });

      test('a failure is returned; the reading stays for a retry', () async {
        readings.failNextWorkerCall(const Failure.network());
        expect(
          expectErr(
            await request.submit(
              hold: aReadingHold(),
              draw: aDraw(),
              locale: 'en',
            ),
          ),
          const Failure.network(),
        );
        expect(
          readings.journal.readings[kTestReadingId]!.status,
          const ReadingStatus.pending(),
        );
        expect(readings.callCount('ack'), 0);
      });
    });

    group('retry', () {
      test('resubmits the same ID and the same draw (RC49)', () async {
        final failed = aReading()
            .failed(const Failure.aiUnavailable(), refunded: true)
            .build();
        clock.advance(const Duration(minutes: 5));
        final retried = expectOk(await request.retry(failed, spread));
        expect(readings.holds.single.$1, failed.id);
        final sent = readings.submitted.single;
        expect(sent.id, failed.id);
        expect(sent.draw, failed.draw);
        expect(sent.status, const ReadingStatus.pending());
        expect(sent.updatedAt, clock.now());
        expect(retried.status, const ReadingStatus.complete());
      });

      test('a pending reading can be retried', () async {
        final pending = aReading().pending().build();
        expectOk(await request.retry(pending, spread));
        expect(readings.submitted, hasLength(1));
      });

      test('a lost hold stops the retry', () async {
        readings.failNextWorkerCall(const Failure.holdConflict());
        expect(
          expectErr(
            await request.retry(aReading().pending().build(), spread),
          ),
          const Failure.holdConflict(),
        );
        expect(readings.submitted, isEmpty);
      });

      test('delivered and Classic readings are returned unchanged', () async {
        for (final r in [aReading().build(), aReading().classic().build()]) {
          expect(expectOk(await request.retry(r, spread)), r);
        }
        expect(readings.calls, isEmpty);
      });
    });
  });

  group('ResumeReading', () {
    late ResumeReading resume;

    setUp(() => resume = ResumeReading(readings: readings, logger: logger));

    test('resumes a pending reading and acknowledges it', () async {
      readings.journal.putReading(aReading().pending().build());
      final reading = expectOk(await resume(kTestReadingId));
      expect(reading.status, const ReadingStatus.complete());
      expect(readings.acked, [kTestReadingId]);
    });

    test('a failed resume is returned without an ack', () async {
      readings.journal.putReading(aReading().pending().build());
      readings.failNextWorkerCall(const Failure.timeout());
      expect(expectErr(await resume(kTestReadingId)), const Failure.timeout());
      expect(readings.callCount('ack'), 0);
    });

    test('resumeAll resumes each pending reading independently', () async {
      readings.journal
        ..putReading(aReading().pending().build())
        ..putReading(
          aReading()
              .withId('99999999-9999-4999-8999-999999999999')
              .pending()
              .build(),
        )
        ..putReading(
          aReading().withId('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa').build(),
        );
      readings.failNextWorkerCall(const Failure.network());
      expect(expectOk(await resume.resumeAll()), 1);
      expect(logger.logged('resume deferred: NETWORK'), isTrue);
      expect(readings.callCount('resume'), 2);
    });

    test('resumeAll fails when the journal cannot be read', () async {
      readings.failNext(const Failure.storage(), on: 'pending');
      expect(expectErr(await resume.resumeAll()), const Failure.storage());
    });
  });
}
