import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/api/api_timeouts.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro/data/repositories/reading_repository_impl.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import '../api/support/scripted_http_adapter.dart';
import 'support/fake_worker_server.dart';

final class _ContractHarness implements ReadingRepositoryHarness {
  _ContractHarness() : h = RepositoryHarness() {
    subject = ReadingRepositoryImpl(
      journal: h.journal,
      device: h.device,
      client: h.client,
      balance: h.balance,
      clock: h.clock,
      logger: h.logger,
      sleep: h.sleep,
    );
  }

  final RepositoryHarness h;

  @override
  late final ReadingRepositoryImpl subject;

  @override
  void failNextWorkerCall(Failure failure) => h.server.failNext(failure);

  @override
  void advance(Duration by) => h.clock.advance(by);
}

ResponseBody _stateReply(
  RecordedRequest r,
  FakeWorkerServer server,
  String status, {
  Map<String, dynamic>? reading,
}) => ScriptedHttpAdapter.response(
  200,
  json: {
    'status': status,
    'attempt': 2,
    'reading': ?reading,
    'balance': server.balance(),
  },
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  runReadingRepositoryContract(_ContractHarness.new);

  group('ReadingRepositoryImpl', () {
    late RepositoryHarness h;
    late FakeWorkerServer server;
    late ReadingRepositoryImpl repo;
    final spread = aSpread().build();
    Reading pendingReading() => aReading().pending().build();

    setUp(() {
      h = RepositoryHarness();
      server = h.server;
      repo = ReadingRepositoryImpl(
        journal: h.journal,
        device: h.device,
        client: h.client,
        balance: h.balance,
        clock: h.clock,
        logger: h.logger,
        sleep: h.sleep,
      );
    });
    tearDown(() => h.close());

    Future<Reading?> stored(ReadingId id) async => expectOk(await repo.get(id));

    Future<List<String>> queuedAcks() async => [
      for (final row in await h.device.pendingAcksDao.all()) row.readingId,
    ];

    test('hold sends the spread and applies the returned balance', () async {
      final hold = expectOk(
        await repo.hold(kTestReadingId, spread, locale: 'de'),
      );
      final sent = server.sent('POST /v1/readings/holds').single;
      expect(sent.header('Idempotency-Key'), kTestReadingId.value);
      expect(sent.json, {
        'clientReadingId': kTestReadingId.value,
        'spread': {'id': spread.id.value, 'version': spread.version},
        'locale': 'de',
      });
      expect(hold.chargeSource, ChargeSource.free);
      expect(h.balance.applied, [hold.balance]);
    });

    test('a hold failure is returned and applies nothing', () async {
      server.onNext(
        'POST /v1/readings/holds',
        (_) => ScriptedHttpAdapter.response(
          402,
          json: ScriptedHttpAdapter.envelope(
            'INSUFFICIENT_CREDITS',
            details: {'reason': 'no_credits'},
          ),
        ),
      );
      expect(
        expectErr(await repo.hold(kTestReadingId, spread, locale: 'en')),
        isA<InsufficientCreditsFailure>(),
      );
      expect(h.balance.applied, isEmpty);
    });

    test('renewHold keeps a fresh hold and renews one near expiry', () async {
      final hold = expectOk(
        await repo.hold(kTestReadingId, spread, locale: 'en'),
      );
      expect(expectOk(await repo.renewHold(hold, spread, locale: 'en')), hold);
      expect(server.holds[kTestReadingId.value], 1);

      h.clock.advance(const Duration(minutes: 14));
      final renewed = expectOk(
        await repo.renewHold(hold, spread, locale: 'en'),
      );
      expect(server.holds[kTestReadingId.value], 2);
      expect(renewed.expiresAt.isAfter(hold.expiresAt), isTrue);
    });

    test('a renewal 402 keeps the stored draw face-down (RC48)', () async {
      final hold = expectOk(
        await repo.hold(kTestReadingId, spread, locale: 'en'),
      );
      final pending = pendingReading();
      server.failNext(const Failure.network());
      await repo.submit(pending);
      h.clock.advance(const Duration(minutes: 14));
      server.onNext(
        'POST /v1/readings/holds',
        (_) => ScriptedHttpAdapter.response(
          402,
          json: ScriptedHttpAdapter.envelope('INSUFFICIENT_CREDITS'),
        ),
      );
      expect(
        (await repo.renewHold(hold, spread, locale: 'en')).isErr,
        isTrue,
      );
      final kept = (await stored(pending.id))!;
      expect(kept.status, const ReadingStatus.pending());
      expect(kept.draw, pending.draw);
    });

    test('submit persists pending before the network call (PR6)', () async {
      final pending = pendingReading().copyWith(deliveryAcked: true);
      Reading? atCall;
      server.onNext('POST /v1/readings', (r) async {
        atCall = await stored(pending.id);
        return ScriptedHttpAdapter.response(
          200,
          json: {
            'readingId': 'srv',
            'status': 'completed',
            'chargeSource': 'paid',
            'promptVersion': 'v7',
            'reading': wireReadingFor(r.json! as Map<String, dynamic>),
            'balance': server.balance(),
          },
        );
      });
      h.clock.advance(const Duration(seconds: 3));
      final delivered = expectOk(await repo.submit(pending));

      expect(atCall!.status, const ReadingStatus.pending());
      expect(atCall!.deliveryAcked, isFalse);
      final sent = server.sent('POST /v1/readings').single;
      expect(sent.header('Idempotency-Key'), pending.id.value);
      expect(sent.header('X-Taro-AI-Consent'), '1');
      expect(delivered.status, const ReadingStatus.complete());
      expect(delivered.content!.title, 'Scripted reading');
      expect(delivered.promptVersion, 'v7');
      expect(delivered.chargeSource, ChargeSource.paid);
      expect(delivered.updatedAt, h.clock.now());
      expect(delivered.deliveryAcked, isFalse);
      expect(await queuedAcks(), [pending.id.value]);
      expect(h.balance.applied, hasLength(1));
    });

    test('a declined reading is stored refused with its safety info', () async {
      final pending = pendingReading();
      server.onNext(
        'POST /v1/readings',
        (_) => ScriptedHttpAdapter.response(
          200,
          json: {
            'readingId': 'srv',
            'status': 'declined',
            'chargeSource': 'none',
            'safety': {
              'category': 'self_harm',
              'messageKey': 'safetyDeclinedSelfHarm',
              'canRephrase': false,
              'crisisResources': [
                {
                  'name': 'Telefonseelsorge',
                  'phone': '0800 111 0 111',
                  'verifiedAt': '2026-09-01T00:00:00Z',
                },
              ],
            },
            'balance': server.balance(),
          },
        ),
      );
      final refused = expectOk(await repo.submit(pending));
      final status = refused.status as ReadingStatusRefused;
      expect(status.safety!.category, RefusalCategory.selfHarm);
      expect(status.safety!.crisisResources.single.name, 'Telefonseelsorge');
      expect(refused.content, isNull);
      expect(refused.chargeSource, isNull);
      expect(await stored(pending.id), refused);
      expect(await queuedAcks(), [pending.id.value]);
    });

    group('timeout polling (02 §6.3)', () {
      void timeoutOnce() => server.onNext(
        'POST /v1/readings',
        (r) => throw DioException(
          requestOptions: r.options,
          type: DioExceptionType.receiveTimeout,
        ),
      );

      test('polls GET until the reading completes', () async {
        final pending = pendingReading();
        timeoutOnce();
        server
          ..onNext(
            'GET /v1/readings/',
            (r) => _stateReply(r, server, 'generating'),
          )
          ..onNext(
            'GET /v1/readings/',
            (r) => throw DioException(
              requestOptions: r.options,
              error: const Failure.network(),
            ),
          )
          ..onNext(
            'GET /v1/readings/',
            (r) => _stateReply(
              r,
              server,
              'completed',
              reading: wireReadingFor({
                'cards': [
                  for (final c in pending.cards) c.toJson(),
                ],
              }),
            ),
          );
        final delivered = expectOk(await repo.submit(pending));
        expect(delivered.status, const ReadingStatus.complete());
        expect(server.sent('POST /v1/readings/'), isEmpty);
        expect(server.sent('POST /v1/readings'), hasLength(1));
        expect(h.sleeps, ApiTimeouts.readingPollDelays.take(3));
        expect(h.balance.applied, hasLength(2));
      });

      test(
        'gives up after the 30 s budget, leaving the draw pending',
        () async {
          final pending = pendingReading();
          timeoutOnce();
          for (var i = 0; i < 4; i++) {
            server.onNext('GET /v1/readings/', (r) {
              h.clock.advance(const Duration(seconds: 6));
              return _stateReply(r, server, 'generating');
            });
          }
          expect(expectErr(await repo.submit(pending)), isA<TimeoutFailure>());
          expect(server.sent('GET /v1/readings/'), hasLength(3));
          expect(
            (await stored(pending.id))!.status,
            isA<ReadingStatusPending>(),
          );
          expect(
            h.logger.records.map((r) => r.message),
            contains(contains('poll budget')),
          );
        },
      );

      test('409 REQUEST_IN_PROGRESS also switches to polling', () async {
        final pending = pendingReading();
        for (var i = 0; i < ApiTimeouts.maxAttempts; i++) {
          server.onNext(
            'POST /v1/readings',
            (_) => ScriptedHttpAdapter.response(
              409,
              json: ScriptedHttpAdapter.envelope('REQUEST_IN_PROGRESS'),
              headers: {'Retry-After': '1'},
            ),
          );
        }
        // A declined state without `safety` is malformed: keep polling.
        server
          ..onNext(
            'GET /v1/readings/',
            (r) => _stateReply(r, server, 'declined'),
          )
          ..onNext(
            'GET /v1/readings/',
            (r) => _stateReply(r, server, 'failed'),
          );
        expect(
          expectErr(await repo.submit(pending)),
          isA<AiUnavailableFailure>(),
        );
        expect(
          (await stored(pending.id))!.status,
          const ReadingStatus.failed(Failure.aiUnavailable(), refunded: true),
        );
      });

      test('a 410 while polling stores the refunded failure', () async {
        final pending = pendingReading();
        timeoutOnce();
        server.onNext(
          'GET /v1/readings/',
          (_) => ScriptedHttpAdapter.response(
            410,
            json: ScriptedHttpAdapter.envelope(
              'READING_EXPIRED_REFUNDED',
              details: {'balance': server.balance()},
            ),
          ),
        );
        expect(
          expectErr(await repo.submit(pending)),
          isA<ReadingExpiredRefundedFailure>(),
        );
        expect(
          (await stored(pending.id))!.status,
          const ReadingStatus.failed(
            Failure.readingExpiredRefunded(),
            refunded: true,
          ),
        );
      });

      test('another error while polling ends the poll', () async {
        final pending = pendingReading();
        timeoutOnce();
        server.onNext(
          'GET /v1/readings/',
          (_) => ScriptedHttpAdapter.response(
            412,
            json: ScriptedHttpAdapter.envelope('AI_CONSENT_REQUIRED'),
          ),
        );
        expect(
          expectErr(await repo.submit(pending)),
          isA<AiConsentRequiredFailure>(),
        );
        expect((await stored(pending.id))!.status, isA<ReadingStatusPending>());
      });
    });

    test('409 HOLD_CONFLICT keeps the draw pending; resubmit reuses the ID '
        '(RC48, RC49)', () async {
      final pending = pendingReading();
      server.onNext(
        'POST /v1/readings',
        (_) => ScriptedHttpAdapter.response(
          409,
          json: ScriptedHttpAdapter.envelope('HOLD_CONFLICT'),
        ),
      );
      expect(expectErr(await repo.submit(pending)), isA<HoldConflictFailure>());
      final kept = (await stored(pending.id))!;
      expect(kept.status, const ReadingStatus.pending());
      expect(kept.draw, pending.draw);

      final retried = expectOk(await repo.submit(kept));
      expect(retried.status, const ReadingStatus.complete());
      final posts = server.sent('POST /v1/readings');
      expect(posts, hasLength(2));
      expect(
        posts.map((r) => r.header('Idempotency-Key')).toSet(),
        {pending.id.value},
      );
      expect(posts.first.json, posts.last.json);
    });

    test('410 READING_EXPIRED_REFUNDED → failed(refunded) and applies the '
        'refund balance', () async {
      final pending = pendingReading();
      server
        ..ledgerVersion = 9
        ..onNext(
          'POST /v1/readings',
          (_) => ScriptedHttpAdapter.response(
            410,
            json: ScriptedHttpAdapter.envelope(
              'READING_EXPIRED_REFUNDED',
              details: {'balance': server.balance()},
            ),
          ),
        );
      final failure = expectErr(await repo.submit(pending));
      expect(failure, isA<ReadingExpiredRefundedFailure>());
      final status = (await stored(pending.id))!.status as ReadingStatusFailed;
      expect(status.refunded, isTrue);
      expect(status.failure, const Failure.readingExpiredRefunded());
      expect(h.balance.applied.single.ledgerVersion, 9);
      expect(await queuedAcks(), isEmpty);
    });

    test('503 AI_UNAVAILABLE stores failed(refunded)', () async {
      final pending = pendingReading();
      for (var i = 0; i < ApiTimeouts.maxAttempts; i++) {
        server.onNext(
          'POST /v1/readings',
          (_) => ScriptedHttpAdapter.response(
            503,
            json: ScriptedHttpAdapter.envelope('AI_UNAVAILABLE'),
          ),
        );
      }
      expect(
        expectErr(await repo.submit(pending)),
        isA<AiUnavailableFailure>(),
      );
      expect(
        (await stored(pending.id))!.status,
        const ReadingStatus.failed(Failure.aiUnavailable(), refunded: true),
      );
    });

    test('a failed GET outcome of no_credit keeps it unrefunded', () async {
      final pending = pendingReading();
      server.failNext(const Failure.network());
      await repo.submit(pending);
      server.onNext(
        'GET /v1/readings/',
        (r) => _stateReply(r, server, 'no_credit'),
      );
      final resumed = expectOk(await repo.resume(pending.id));
      expect(
        resumed.status,
        const ReadingStatus.failed(Failure.holdConflict()),
      );
    });

    group('resume', () {
      test('an unknown reading is NOT_FOUND', () async {
        expect(
          expectErr(await repo.resume(kTestReadingId)),
          const Failure.contract(wireCode: 'NOT_FOUND'),
        );
      });

      test('a delivered reading is returned without a call', () async {
        final done = aReading().build();
        await repo.saveClassic(done);
        expect(expectOk(await repo.resume(done.id)), done);
        expect(server.requests, isEmpty);
      });

      test('a still-generating reading stays pending', () async {
        final pending = pendingReading();
        server.failNext(const Failure.network());
        await repo.submit(pending);
        server.onNext(
          'GET /v1/readings/',
          (r) => _stateReply(r, server, 'held'),
        );
        final resumed = expectOk(await repo.resume(pending.id));
        expect(resumed.status, const ReadingStatus.pending());
      });

      test('a 410 stores and returns the refunded failure', () async {
        final pending = pendingReading();
        server.failNext(const Failure.network());
        await repo.submit(pending);
        server.onNext(
          'GET /v1/readings/',
          (_) => ScriptedHttpAdapter.response(
            410,
            json: ScriptedHttpAdapter.envelope('READING_EXPIRED_REFUNDED'),
          ),
        );
        final resumed = expectOk(await repo.resume(pending.id));
        expect(
          resumed.status,
          const ReadingStatus.failed(
            Failure.readingExpiredRefunded(),
            refunded: true,
          ),
        );
      });

      test(
        'a transport failure is returned, the reading stays pending',
        () async {
          final pending = pendingReading();
          server
            ..failNext(const Failure.network())
            ..failNext(const Failure.network());
          await repo.submit(pending);
          expect(
            expectErr(await repo.resume(pending.id)),
            isA<NetworkFailure>(),
          );
          expect(
            (await stored(pending.id))!.status,
            isA<ReadingStatusPending>(),
          );
        },
      );

      test('a failed attempt is stored and returned as failed', () async {
        final pending = pendingReading();
        server.failNext(const Failure.network());
        await repo.submit(pending);
        server.onNext(
          'GET /v1/readings/',
          (r) => _stateReply(r, server, 'expired_refunded'),
        );
        final resumed = expectOk(await repo.resume(pending.id));
        expect(resumed.status, isA<ReadingStatusFailed>());
        expect((resumed.status as ReadingStatusFailed).refunded, isTrue);
      });
    });

    group('delivery acks (RC51)', () {
      test('ack sends no body and clears the queue', () async {
        final delivered = expectOk(await repo.submit(pendingReading()));
        expect(await queuedAcks(), [delivered.id.value]);
        expectOk(await repo.ack(delivered.id));
        final sent = server.sent('POST /v1/readings/').single;
        expect(sent.path, '/v1/readings/${delivered.id.value}/ack');
        expect(sent.body, isEmpty);
        expect(await queuedAcks(), isEmpty);
        expect(server.acked, {delivered.id.value});
      });

      test('a failed ack counts the attempt', () async {
        final delivered = expectOk(await repo.submit(pendingReading()));
        server.failNext(const Failure.timeout());
        await repo.ack(delivered.id);
        expect((await h.device.pendingAcksDao.all()).single.attempts, 1);
      });

      test(
        'flush picks up a delivered reading that was never queued',
        () async {
          final orphan = aReading().acked(acked: false).build();
          await repo.saveClassic(orphan);
          expect(expectOk(await repo.flushPendingAcks()), 1);
          expect((await stored(orphan.id))!.deliveryAcked, isTrue);
        },
      );

      test('flush stops at the first network failure', () async {
        final a = aReading().withId('a').acked(acked: false).build();
        final b = aReading().withId('b').acked(acked: false).build();
        await repo.saveClassic(a);
        await repo.saveClassic(b);
        server.failNext(const Failure.network());
        expect(expectOk(await repo.flushPendingAcks()), 0);
        expect(server.sent('POST /v1/readings/'), hasLength(1));
        expect(await queuedAcks(), hasLength(2));
      });

      test('flush drops a 404 and defers other errors', () async {
        final a = aReading().withId('a').acked(acked: false).build();
        final b = aReading()
            .withId('b')
            .createdAt(kTestNow.add(const Duration(minutes: 1)))
            .acked(acked: false)
            .build();
        await repo.saveClassic(a);
        await repo.saveClassic(b);
        server
          ..onNext(
            'POST /v1/readings/a/ack',
            (_) => ScriptedHttpAdapter.response(
              404,
              json: ScriptedHttpAdapter.envelope('NOT_FOUND'),
            ),
          )
          ..onNext(
            'POST /v1/readings/b/ack',
            (_) => ScriptedHttpAdapter.response(
              401,
              json: ScriptedHttpAdapter.envelope('UNAUTHENTICATED'),
            ),
          );
        expect(expectOk(await repo.flushPendingAcks()), 0);
        expect(await queuedAcks(), ['b']);
        expect((await stored(const ReadingId('a')))!.deliveryAcked, isTrue);
        expect((await h.device.pendingAcksDao.all()).single.attempts, 1);
      });
    });

    group('journal edits and undo (01 §7.8)', () {
      test(
        'edits set updatedAt; a rating without a reason clears it',
        () async {
          final classic = aReading().classic().build();
          await repo.saveClassic(classic);
          h.clock.advance(const Duration(hours: 1));
          await repo.setRating(classic.id, null, reason: RatingReason.tone);
          final r = (await stored(classic.id))!;
          expect(r.ratingReason, isNull);
          expect(r.updatedAt, h.clock.now());
          expectOk(
            await repo.setFavourite(
              const ReadingId('missing'),
              favourite: true,
            ),
          );
        },
      );

      test('pending lists only pending readings, oldest first', () async {
        server
          ..failNext(const Failure.network())
          ..failNext(const Failure.network());
        final first = aReading().withId('p1').pending().build();
        final second = aReading()
            .withId('p2')
            .createdAt(kTestNow.add(const Duration(minutes: 1)))
            .pending()
            .build();
        await repo.submit(second);
        await repo.submit(first);
        await repo.saveClassic(aReading().withId('c').classic().build());
        expect(
          [for (final r in expectOk(await repo.pending())) r.id.value],
          ['p1', 'p2'],
        );
      });

      test('undoDelete restores within 5 s, not after', () async {
        final classic = aReading().classic().withNote('keep me').build();
        await repo.saveClassic(classic);
        expectOk(await repo.delete(classic.id));
        expect(await stored(classic.id), isNull);
        h.clock.advance(const Duration(seconds: 4));
        expect(expectOk(await repo.undoDelete(classic.id)), isTrue);
        expect(await stored(classic.id), classic);

        expectOk(await repo.delete(classic.id));
        h.clock.advance(ReadingRepositoryImpl.undoWindow);
        expect(expectOk(await repo.undoDelete(classic.id)), isFalse);
        expect(await stored(classic.id), isNull);
        expectOk(await repo.delete(classic.id));
      });
    });

    group('storage failures', () {
      // Dropping a table makes every later query on it throw.
      Future<void> breakJournal() async {
        await h.journal.customStatement('DROP TABLE reading_cards');
        await h.journal.customStatement('DROP TABLE readings');
      }

      Future<void> breakDevice() =>
          h.device.customStatement('DROP TABLE pending_acks');

      test('a broken database is a StorageFailure, logged by type', () async {
        await breakJournal();
        expect(
          expectErr(await repo.submit(pendingReading())),
          isA<StorageFailure>(),
        );
        expect(
          expectErr(await repo.get(kTestReadingId)),
          isA<StorageFailure>(),
        );
        expect(
          expectErr(await repo.resume(kTestReadingId)),
          isA<StorageFailure>(),
        );
        expect(
          expectErr(await repo.flushPendingAcks()),
          isA<StorageFailure>(),
        );
        expect(
          h.logger.records.where((r) => r.level == LogLevel.warning),
          isNotEmpty,
        );
      });

      test('a malformed row is a StorageFailure', () async {
        await h.journal
            .into(h.journal.readings)
            .insert(
              ReadingsCompanion.insert(
                id: 'bad',
                spreadId: 'single',
                spreadVersion: 1,
                localDate: '2026-09-26',
                status: 'complete',
                contentLocale: 'en',
                contentJson: const Value('[1]'),
                drawnAt: kTestNow,
                createdAt: kTestNow,
                updatedAt: kTestNow,
              ),
            );
        expect(
          expectErr(await repo.get(const ReadingId('bad'))),
          isA<StorageFailure>(),
        );
      });

      test('a failed ack queue write is a StorageFailure', () async {
        final delivered = expectOk(await repo.submit(pendingReading()));
        await breakDevice();
        server.failNext(const Failure.network());
        expect(
          expectErr(await repo.ack(delivered.id)),
          isA<StorageFailure>(),
        );
      });

      test('a delivery that cannot be stored is a StorageFailure', () async {
        server.onNext('POST /v1/readings', (r) async {
          await breakDevice();
          return ScriptedHttpAdapter.response(
            200,
            json: {
              'readingId': 'srv',
              'status': 'completed',
              'chargeSource': 'free',
              'reading': wireReadingFor(r.json! as Map<String, dynamic>),
              'balance': server.balance(),
            },
          );
        });
        expect(
          expectErr(await repo.submit(pendingReading())),
          isA<StorageFailure>(),
        );
      });

      test('a refund that cannot be stored is a StorageFailure', () async {
        server.onNext('POST /v1/readings', (_) async {
          await breakJournal();
          return ScriptedHttpAdapter.response(
            410,
            json: ScriptedHttpAdapter.envelope('READING_EXPIRED_REFUNDED'),
          );
        });
        expect(
          expectErr(await repo.submit(pendingReading())),
          isA<StorageFailure>(),
        );
      });

      test(
        'a failed outcome that cannot be stored is a StorageFailure',
        () async {
          final pending = pendingReading();
          server.failNext(const Failure.network());
          await repo.submit(pending);
          server.onNext('GET /v1/readings/', (r) async {
            await breakJournal();
            return _stateReply(r, server, 'failed');
          });
          expect(
            expectErr(await repo.resume(pending.id)),
            isA<StorageFailure>(),
          );
        },
      );

      test(
        'a refund on resume that cannot be stored is a StorageFailure',
        () async {
          final pending = pendingReading();
          server.failNext(const Failure.network());
          await repo.submit(pending);
          server.onNext('GET /v1/readings/', (_) async {
            await breakJournal();
            return ScriptedHttpAdapter.response(
              410,
              json: ScriptedHttpAdapter.envelope('READING_EXPIRED_REFUNDED'),
            );
          });
          expect(
            expectErr(await repo.resume(pending.id)),
            isA<StorageFailure>(),
          );
        },
      );

      test('a flush that cannot mark the ack is a StorageFailure', () async {
        final delivered = expectOk(await repo.submit(pendingReading()));
        server.onNext('POST /v1/readings/', (_) async {
          await breakJournal();
          return ScriptedHttpAdapter.response(204);
        });
        expect(delivered.deliveryAcked, isFalse);
        expect(
          expectErr(await repo.flushPendingAcks()),
          isA<StorageFailure>(),
        );
      });
    });

    test('watch emits distinct values', () async {
      final classic = aReading().classic().build();
      final seen = <Reading?>[];
      final sub = repo.watch(classic.id).listen(seen.add);
      await settle();
      await repo.saveClassic(classic);
      await settle();
      await repo.saveClassic(classic);
      await settle();
      await sub.cancel();
      expect(seen, [null, classic]);
    });
  });
}
