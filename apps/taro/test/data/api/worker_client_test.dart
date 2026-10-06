import 'dart:io';

import 'package:dio/dio.dart' show DioExceptionType;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/api/api_timeouts.dart';
import 'package:taro/data/api/dto/install_dtos.dart';
import 'package:taro/data/api/dto/reading_dtos.dart';
import 'package:taro/data/api/dto/store_dtos.dart';
import 'package:taro/data/api/worker_models.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contract_support.dart';
import 'support/worker_client_harness.dart';

const _readingId = ReadingId('0c6e0000-0000-4000-8000-000000000001');

Reading _pending() => Reading(
  id: _readingId,
  createdAt: DateTime.utc(2026, 9, 26, 9, 10, 2),
  updatedAt: DateTime.utc(2026, 9, 26, 9, 10, 2),
  localDate: '2026-09-26',
  draw: Draw(
    spreadId: const SpreadId('single'),
    spreadVersion: 1,
    cards: [
      DrawnCard(
        positionId: const PositionId('focus'),
        cardId: CardId.parse('major_16'),
        reversed: false,
      ),
    ],
    drawnAt: DateTime.utc(2026, 9, 26, 9, 10, 2),
  ),
  status: const ReadingStatus.pending(),
  contentLocale: 'de',
  question: 'How can I approach the change at work?',
);

void main() {
  late WorkerClientHarness h;

  setUp(() => h = WorkerClientHarness());

  group('identity', () {
    test('challenge decodes the fixture on a public route', () async {
      h.adapter.reply(200, json: fixture('installs.challenge.response'));
      final challenge = expectOk(await h.client.challenge());
      expect(challenge.powBits, 20);
      expect(challenge.expiresAt, DateTime.utc(2026, 9, 26, 10, 5));
      expect(h.last.route, 'POST /v1/attest/challenge');
      expect(h.last.header('authorization'), isNull);
      expect(h.last.body, isEmpty);
    });

    test('register sends the body once, persists the token and maps '
        'everything', () async {
      h = WorkerClientHarness(noToken: true);
      h.adapter.reply(201, json: fixture('installs.register.response'));
      final body = RegisterRequestDto(
        installId: 'c0a80101-0000-4000-8000-000000000001',
        installSecret: 'BwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwc',
        platform: 'ios',
        appVersion: '1.2.0+14',
        locale: 'de',
        timezone: 'Europe/Berlin',
        attestation: RegistrationAttestationDto.fromBlob(
          const AttestationBlob(
            type: AttestationType.appAttest,
            challenge: 'c',
            payload: 'b2JqZWN0',
            keyId: 'a2V5LWlk',
          ),
        ),
      );
      final reg = expectOk(
        await h.client.register(body, idempotencyKey: 'idem-reg-1'),
      );
      expect(reg.trust, Trust.high);
      expect(reg.purchaseBinding.appleAccountToken, isNotNull);
      expect(reg.balance.ledgerVersion, 0);
      expect(reg.config.version, 1);
      expect(h.tokens.token, reg.token);
      expect(reg.toString(), isNot(contains(reg.token.token)));
      expect(h.last.header('idempotency-key'), 'idem-reg-1');
      expect(h.last.header('authorization'), isNull);
      expect(h.last.header('x-taro-attestation'), isNull);
      expect(h.last.json, body.toJson());
      expect(body.toString(), isNot(contains('BwcH')));
      for (final record in h.logger.records) {
        expect(record.message, isNot(contains('BwcH')));
      }
    });

    test('register fails with StorageFailure when the token cannot be '
        'stored', () async {
      h.adapter.reply(201, json: fixture('installs.register.response'));
      h.tokens.failNext(const Failure.storage(), on: 'write');
      const body = RegisterRequestDto(
        installId: 'i',
        installSecret: 's',
        platform: 'ios',
        appVersion: '1',
        locale: 'de',
        timezone: 'UTC',
        attestation: RegistrationAttestationDto(
          type: 'none',
          challenge: 'c',
        ),
      );
      expect(
        expectErr(await h.client.register(body, idempotencyKey: 'k')),
        const Failure.storage(),
      );
    });

    test('refreshToken attests, persists and is single-flight', () async {
      h.adapter.reply(200, json: fixture('installs.token.response'));
      final results = await Future.wait([
        h.client.refreshToken(),
        h.client.refreshToken(),
      ]);
      expect(h.requests, hasLength(1));
      final grant = expectOk(results.first);
      expect(expectOk(results.last), same(grant));
      expect(grant.trust, Trust.high);
      expect(h.tokens.token, grant.token);
      expect(grant.toString(), isNot(contains(grant.token.token)));
      expect(h.last.header('authorization'), 'Bearer token-1');
      expect(h.last.header('x-taro-attestation'), 'aa1.assertion-1');
      expect(h.last.body, isEmpty);

      h.adapter.reply(200, json: fixture('installs.token.response'));
      expectOk(await h.client.refreshSessionToken());
      expect(h.requests, hasLength(2));
    });

    test('updateTimezone returns the new balance; 409 keeps the server '
        'boundary', () async {
      h.adapter.reply(200, json: fixture('timezone.response'));
      final balance = expectOk(
        await h.client.updateTimezone(
          'America/New_York',
          idempotencyKey: 'tz-1',
        ),
      );
      expect(balance.free.timezone, 'America/New_York');
      expect(h.last.route, 'PUT /v1/installs/me/timezone');
      expect(h.last.json, {'timezone': 'America/New_York'});
      expect(h.last.header('idempotency-key'), 'tz-1');

      h.adapter.reply(409, json: fixture('errors.timezone_change_too_soon'));
      expect(
        expectErr(await h.client.updateTimezone('UTC', idempotencyKey: 'tz-2')),
        Failure.timezoneChangeRejected(
          allowedAfter: DateTime.utc(2026, 9, 27, 10),
        ),
      );
    });

    test('deleteInstall accepts 204 with the action key', () async {
      h.adapter.reply(204);
      expectOk(await h.client.deleteInstall(idempotencyKey: 'del-1'));
      expect(h.last.route, 'DELETE /v1/installs/me');
      expect(h.last.header('idempotency-key'), 'del-1');
    });
  });

  group('config and balance', () {
    test(
      'fetchConfig parses 200 with its ETag and sends If-None-Match',
      () async {
        h.adapter.reply(
          200,
          json: fixture('config.response'),
          headers: {'ETag': '"v1"'},
        );
        final fetched = expectOk(await h.client.fetchConfig(etag: '"v0"'));
        expect(fetched, isA<ConfigFetched>());
        fetched as ConfigFetched;
        expect(fetched.etag, '"v1"');
        expect(fetched.config.version, 1);
        expect(fetched.config.fetchedAt, kHarnessNow);
        expect(fetched.json['version'], 1);
        expect(h.last.header('if-none-match'), '"v0"');
        expect(h.last.header('authorization'), isNull);
      },
    );

    test('fetchConfig maps 304 to notModified and omits a null ETag', () async {
      h.adapter.reply(304);
      expect(
        expectOk(await h.client.fetchConfig()),
        isA<ConfigNotModified>(),
      );
      expect(h.last.header('if-none-match'), isNull);
    });

    test('fetchConfig logs clamped values', () async {
      h.adapter.reply(200, json: {'version': 2, 'readings.freeDaily': 99});
      final fetched = expectOk(await h.client.fetchConfig()) as ConfigFetched;
      expect(fetched.config.readingsFreeDaily, 5);
      expect(h.logger.logged('config_value_clamped'), isTrue);
    });

    test('fetchBalance equals CreditBalance.fromDto and moves the server '
        'clock', () async {
      h.adapter.reply(
        200,
        json: balanceJson(serverTime: '2026-09-26T10:00:30Z'),
      );
      final balance = expectOk(await h.client.fetchBalance());
      expect(
        balance,
        CreditBalance.fromDto(
          balanceJson(serverTime: '2026-09-26T10:00:30Z'),
          syncedAt: kHarnessNow,
        ),
      );
      expect(h.client.serverClock.current.offset, const Duration(seconds: 30));
      expect(h.last.header('authorization'), 'Bearer token-1');
    });
  });

  group('readings', () {
    test(
      'createHold keys on clientReadingId with consent and attestation',
      () async {
        h.adapter.reply(
          201,
          json: {
            'clientReadingId': _readingId.value,
            'chargeSource': 'free',
            'expiresAt': '2026-09-26T10:15:00Z',
            'balance': balanceJson(ledgerVersion: 8),
          },
        );
        const spread = SpreadDefinition(
          id: SpreadId('three_ppf'),
          version: 1,
          positions: [],
        );
        final hold = expectOk(
          await h.client.createHold(
            HoldRequestDto.fromDomain(_readingId, spread, locale: 'de'),
          ),
        );
        expect(hold.readingId, _readingId);
        expect(hold.chargeSource, ChargeSource.free);
        expect(hold.balance.ledgerVersion, 8);
        expect(hold.needsRenewalAt(kHarnessNow), isFalse);
        expect(h.last.json, {
          'clientReadingId': _readingId.value,
          'spread': {'id': 'three_ppf', 'version': 1},
          'locale': 'de',
        });
        expect(h.last.header('idempotency-key'), _readingId.value);
        expect(h.last.header('x-taro-ai-consent'), '1');
        expect(h.last.header('x-taro-attestation'), 'aa1.assertion-1');
      },
    );

    test('createReading maps completed to ReadingContent (RC30)', () async {
      h.adapter.reply(
        200,
        json: {
          'readingId': 'w-1',
          'status': 'completed',
          'chargeSource': 'free',
          'promptVersion': 'v1',
          'reading': wireReading(),
          'balance': balanceJson(ledgerVersion: 9),
        },
      );
      final outcome = expectOk(
        await h.client.createReading(
          CreateReadingRequestDto.fromDomain(_pending()),
        ),
      );
      outcome as ReadingCompleted;
      expect(outcome.content.summary, 'A sudden change.');
      expect(
        outcome.content.textFor(const PositionId('focus')),
        'Let the old structure fall.',
      );
      expect(outcome.chargeSource, ChargeSource.free);
      expect(outcome.promptVersion, 'v1');
      expect(outcome.workerReadingId, 'w-1');
      expect(outcome.status, const ReadingStatus.complete());
      expect(h.last.json, {
        'clientReadingId': _readingId.value,
        'spread': {'id': 'single', 'version': 1},
        'cards': [
          {'positionId': 'focus', 'cardId': 'major_16', 'reversed': false},
        ],
        'question': 'How can I approach the change at work?',
        'locale': 'de',
        'drawnAt': '2026-09-26T09:10:02Z',
      });
      expect(h.last.options.receiveTimeout, const Duration(seconds: 60));
      expect(h.last.header('idempotency-key'), _readingId.value);
      for (final record in h.logger.records) {
        expect(record.message, isNot(contains('change at work')));
      }
      expect(
        CreateReadingRequestDto.fromDomain(_pending()).toString(),
        isNot(contains('change at work')),
      );
    });

    test('createReading maps declined to refused(SafetyInfo) (RC27)', () async {
      h.adapter.reply(
        200,
        json: {
          'readingId': 'w-2',
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
                'url': 'https://www.telefonseelsorge.de',
                'hours': '24/7',
                'languages': ['de'],
                'verifiedAt': '2026-09-01T00:00:00Z',
              },
            ],
          },
          'balance': balanceJson(),
        },
      );
      final outcome = expectOk(
        await h.client.createReading(
          CreateReadingRequestDto.fromDomain(_pending()),
        ),
      );
      outcome as ReadingDeclined;
      expect(outcome.safety.category, RefusalCategory.selfHarm);
      expect(outcome.safety.crisisResources.single.phone, '0800 111 0 111');
      expect(outcome.status, ReadingStatus.refused(safety: outcome.safety));
    });

    test('409 HOLD_CONFLICT and 410 READING_EXPIRED_REFUNDED map to their '
        'failures', () async {
      h.adapter.error(409, 'HOLD_CONFLICT');
      expect(
        expectErr(
          await h.client.createReading(
            CreateReadingRequestDto.fromDomain(_pending()),
          ),
        ),
        const Failure.holdConflict(),
      );
      h.adapter.error(
        410,
        'READING_EXPIRED_REFUNDED',
        details: {'balance': balanceJson(ledgerVersion: 11)},
      );
      final failure = expectErr(await h.client.fetchReading(_readingId));
      failure as ReadingExpiredRefundedFailure;
      expect(failure.balance!.ledgerVersion, 11);
      expect(h.last.route, 'GET /v1/readings/${_readingId.value}');
    });

    test('fetchReading maps every readings.status', () async {
      final cases = <String, Object>{
        'held': isA<ReadingInProgress>(),
        'generating': isA<ReadingInProgress>(),
        'failed': isA<ReadingAttemptFailed>(),
        'no_credit': isA<ReadingAttemptFailed>(),
        'expired_hold': isA<ReadingAttemptFailed>(),
        'expired_refunded': isA<ReadingAttemptFailed>(),
      };
      for (final entry in cases.entries) {
        h.adapter.reply(
          200,
          json: {
            'status': entry.key,
            'attempt': 2,
            'balance': balanceJson(),
          },
        );
        final outcome = expectOk(await h.client.fetchReading(_readingId));
        expect(outcome, entry.value, reason: entry.key);
        expect(outcome.attempt, 2);
      }
      h.adapter.reply(
        200,
        json: {
          'status': 'completed',
          'attempt': 1,
          'reading': wireReading(),
          'balance': balanceJson(),
        },
      );
      final done = expectOk(await h.client.fetchReading(_readingId));
      expect(done, isA<ReadingCompleted>());
      expect((done as ReadingCompleted).chargeSource, isNull);
      h.adapter.reply(
        200,
        json: {
          'status': 'declined',
          'safety': {'category': 'legal', 'canRephrase': true},
          'balance': balanceJson(),
        },
      );
      final declined = expectOk(await h.client.fetchReading(_readingId));
      declined as ReadingDeclined;
      expect(declined.safety.messageKey, 'safetyDeclinedLegal');
      expect(declined.attempt, 1);
    });

    test('fetchReading with an unknown status or a missing reading is a '
        'ServerFailure', () async {
      h.adapter.reply(
        200,
        json: {'status': 'mystery', 'balance': balanceJson()},
      );
      expect(
        expectErr(await h.client.fetchReading(_readingId)),
        isA<ServerFailure>(),
      );
      h.adapter.reply(
        200,
        json: {'status': 'completed', 'balance': balanceJson()},
      );
      expect(
        expectErr(await h.client.fetchReading(_readingId)),
        const Failure.server(status: 200),
      );
      expect(h.logger.logged('unreadable 200 body'), isTrue);
    });

    test('ackReading posts without body or key', () async {
      h.adapter.reply(204);
      expectOk(await h.client.ackReading(_readingId));
      expect(h.last.route, 'POST /v1/readings/${_readingId.value}/ack');
      expect(h.last.body, isEmpty);
      expect(h.last.header('idempotency-key'), isNull);
      expect(h.last.header('x-taro-attestation'), isNull);
    });

    test('reportReading sends the wire reading with the drawn cards', () async {
      h.adapter.reply(201, json: {'reportId': 'rep-1', 'status': 'received'});
      final pending = _pending();
      const report = ReadingReport(
        readingId: _readingId,
        reason: ReportReason.harmfulAdvice,
        locale: 'de',
        idempotencyKey: 'rep-key',
        note: 'too direct',
        reading: ReadingContent(
          title: 'The Tower',
          summary: 'A sudden change.',
          positions: [
            PositionText(
              positionId: PositionId('focus'),
              text: 'Let the old structure fall.',
            ),
          ],
          synthesis: 'Change clears the ground.',
          reflectionPrompts: ['What can you release?'],
        ),
      );
      final response = expectOk(
        await h.client.reportReading(
          _readingId,
          ReportRequestDto.fromDomain(report, cards: pending.cards),
          idempotencyKey: report.idempotencyKey,
        ),
      );
      expect(response.reportId, 'rep-1');
      expect(response.status, 'received');
      expect(h.last.json, {
        'reason': 'harmful_advice',
        'note': 'too direct',
        'reading': wireReading(),
        'locale': 'de',
      });
      expect(h.last.header('idempotency-key'), 'rep-key');
      expect(
        ReportRequestDto.fromDomain(report, cards: pending.cards).toString(),
        isNot(contains('direct')),
      );
    });

    test(
      'a timed-out reading is handed to polling after one attempt',
      () async {
        h.adapter.fail(DioExceptionType.receiveTimeout);
        expect(
          expectErr(
            await h.client.createReading(
              CreateReadingRequestDto.fromDomain(_pending()),
            ),
          ),
          const Failure.timeout(),
        );
        expect(h.requests, hasLength(1));
        expect(h.sleeps, isEmpty);
        h.adapter.reply(
          200,
          json: {
            'status': 'generating',
            'attempt': 1,
            'balance': balanceJson(),
          },
        );
        h.adapter.reply(
          200,
          json: {
            'status': 'completed',
            'attempt': 1,
            'reading': wireReading(),
            'balance': balanceJson(),
          },
        );
        ReadingOutcome? outcome;
        for (final delay in ApiTimeouts.readingPollDelays) {
          h.clock.advance(delay);
          outcome = expectOk(await h.client.fetchReading(_readingId));
          if (outcome is! ReadingInProgress) break;
        }
        expect(outcome, isA<ReadingCompleted>());
        expect(h.requests.map((r) => r.route), [
          'POST /v1/readings',
          'GET /v1/readings/${_readingId.value}',
          'GET /v1/readings/${_readingId.value}',
        ]);
      },
    );
  });

  group('store and rewards', () {
    const ios = StorePurchase(
      txnKey: '2000000100000020',
      productId: ProductId('com.vshyrochuk.taro.readings_3'),
      platform: StorePlatform.ios,
      transactionId: '2000000100000020',
    );

    test(
      'verifyPurchase maps granted, already_granted and 202 pending',
      () async {
        final body = VerifyPurchaseRequestDto.fromDomain(ios);
        h.adapter.reply(
          200,
          json: fixture('purchases.verify.granted.response'),
        );
        final granted = expectOk(
          await h.client.verifyPurchase(body, idempotencyKey: 'outbox-1'),
        );
        expect(granted.status, GrantStatus.granted);
        expect(granted.creditsGranted, 3);
        expect(granted.balance!.paid, 3);
        expect(h.last.header('idempotency-key'), 'outbox-1');
        expect(h.last.json, fixture('purchases.verify.ios.request'));

        h.adapter.reply(
          200,
          json: fixture('purchases.verify.already_granted.response'),
        );
        expect(
          expectOk(
            await h.client.verifyPurchase(body, idempotencyKey: 'outbox-1'),
          ).status,
          GrantStatus.alreadyGranted,
        );

        h.adapter.reply(
          202,
          json: fixture('purchases.verify.pending.response'),
        );
        final pending = expectOk(
          await h.client.verifyPurchase(body, idempotencyKey: 'outbox-1'),
        );
        expect(pending.status, GrantStatus.pending);
        expect(pending.balance, isNull);
      },
    );

    test('verifyPurchase maps 409 claimed and 422 invalid', () async {
      final body = VerifyPurchaseRequestDto.fromDomain(ios);
      h.adapter.reply(409, json: fixture('errors.purchase_already_claimed'));
      final claimed = expectErr(
        await h.client.verifyPurchase(body, idempotencyKey: 'k'),
      );
      claimed as PurchaseAlreadyClaimedFailure;
      expect(claimed.transferEligible, isTrue);
      expect(claimed.transferToken, startsWith('tt1.'));
      h.adapter.reply(422, json: fixture('errors.purchase_invalid'));
      expect(
        expectErr(await h.client.verifyPurchase(body, idempotencyKey: 'k')),
        const Failure.purchase(
          wireCode: 'PURCHASE_INVALID',
          reason: 'not_found',
        ),
      );
    });

    test('reward intent, status and cancel', () async {
      h.adapter.reply(201, json: fixture('rewards.intent.response'));
      final intent = expectOk(
        await h.client.createRewardIntent(
          'ca-app-pub-5769204800499735/4059850229',
          idempotencyKey: 'tap-1',
        ),
      );
      expect(intent.intentId, const IntentId('rwc0a8f0220001'));
      expect(h.last.json, fixture('rewards.intent.request'));
      expect(h.last.header('x-taro-attestation'), 'aa1.assertion-1');
      expect(h.last.header('x-taro-ai-consent'), isNull);

      h.adapter.reply(
        200,
        json: fixture('rewards.intent.status_issued.response'),
      );
      expect(
        expectOk(await h.client.fetchRewardStatus(intent.intentId)).state,
        RewardIntentState.issued,
      );
      h.adapter.reply(
        200,
        json: fixture('rewards.intent.status_granted.response'),
      );
      final granted = expectOk(
        await h.client.fetchRewardStatus(intent.intentId),
      );
      expect(granted.state, RewardIntentState.granted);
      expect(granted.balance!.bonus, 1);
      expect(h.last.route, 'GET /v1/rewards/intents/rwc0a8f0220001');

      h.adapter.reply(204);
      expectOk(await h.client.cancelRewardIntent(intent.intentId));
      expect(h.last.route, 'POST /v1/rewards/intents/rwc0a8f0220001/cancel');
    });
  });

  group('never throws', () {
    test('a non-object body is a ServerFailure', () async {
      h.adapter.reply(200, raw: '[1, 2]');
      expect(
        expectErr(await h.client.fetchBalance()),
        const Failure.server(status: 200),
      );
      h.adapter.reply(200, raw: '{not json');
      expect(expectErr(await h.client.fetchBalance()), isA<ServerFailure>());
    });

    test('socket errors are NetworkFailure, anything else '
        'UnexpectedFailure', () async {
      h.adapter.throwError(const SocketException('down'));
      expect(expectErr(await h.client.fetchConfig()), const Failure.network());
      h.adapter.throwBug(StateError('boom'));
      expect(expectErr(await h.client.fetchConfig()), isA<UnexpectedFailure>());
    });
  });
}
