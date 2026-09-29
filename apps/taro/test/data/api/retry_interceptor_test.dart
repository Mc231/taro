import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/api/api_timeouts.dart';
import 'package:taro/data/api/dto/store_dtos.dart';
import 'package:taro/data/api/interceptors/retry_interceptor.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contract_support.dart';
import 'support/worker_client_harness.dart';

const _ms = Duration(milliseconds: 1);

VerifyPurchaseRequestDto _verify() => const VerifyPurchaseRequestDto(
  platform: 'ios',
  productId: 'com.vshyrochuk.taro.readings_3',
  transactionId: '1',
);

void main() {
  late WorkerClientHarness h;

  setUp(() => h = WorkerClientHarness());

  group('retried (GET or Idempotency-Key)', () {
    final transient = <String, void Function(WorkerClientHarness)>{
      'connection error': (h) => h.adapter.fail(
        DioExceptionType.connectionError,
      ),
      'connect timeout': (h) =>
          h.adapter.fail(DioExceptionType.connectionTimeout),
      'send timeout': (h) => h.adapter.fail(DioExceptionType.sendTimeout),
      'receive timeout (GET)': (h) =>
          h.adapter.fail(DioExceptionType.receiveTimeout),
      '408': (h) => h.adapter.reply(408),
      '502': (h) => h.adapter.reply(502, raw: '<html>bad gateway</html>'),
      '503 AI_UNAVAILABLE': (h) => h.adapter.error(503, 'AI_UNAVAILABLE'),
      '504': (h) => h.adapter.reply(504),
    };
    for (final entry in transient.entries) {
      test('${entry.key} → retried with backoff', () async {
        entry.value(h);
        h.adapter.reply(200, json: balanceJson());
        expectOk(await h.client.fetchBalance());
        expect(h.requests, hasLength(2));
        expect(h.sleeps, [_ms * 500]);
        expect(h.clock.now(), kHarnessNow.add(_ms * 500));
      });
    }

    test('backoff doubles and stops after 3 attempts', () async {
      h.adapter.replyTimes(3, 503, json: _envelope('AI_UNAVAILABLE'));
      expect(
        expectErr(await h.client.fetchBalance()),
        const Failure.aiUnavailable(),
      );
      expect(h.requests, hasLength(ApiTimeouts.maxAttempts));
      expect(h.sleeps, [_ms * 500, _ms * 1000]);
    });

    test('an idempotent POST is retried with the same key', () async {
      h.adapter
        ..fail(DioExceptionType.connectionError)
        ..reply(200, json: fixture('purchases.verify.granted.response'));
      expectOk(await h.client.verifyPurchase(_verify(), idempotencyKey: 'k1'));
      expect(h.requests.map((r) => r.header('idempotency-key')), ['k1', 'k1']);
    });

    test('429 burst waits for Retry-After ≤ 30 s', () async {
      h.adapter
        ..error(
          429,
          'RATE_LIMITED',
          details: {'reason': 'burst'},
          headers: {'Retry-After': '2'},
        )
        ..reply(200, json: balanceJson());
      expectOk(await h.client.fetchBalance());
      expect(h.sleeps, [const Duration(seconds: 2)]);
    });

    test('429 burst without Retry-After uses the backoff; the envelope '
        'retryAfterSec also counts', () async {
      h.adapter
        ..error(429, 'RATE_LIMITED')
        ..error(
          429,
          'RATE_LIMITED',
          details: {'reason': 'burst'},
          retryAfterSec: 4,
        )
        ..reply(200, json: balanceJson());
      expectOk(await h.client.fetchBalance());
      expect(h.sleeps, [_ms * 500, const Duration(seconds: 4)]);
    });

    test('409 REQUEST_IN_PROGRESS honours Retry-After', () async {
      h.adapter
        ..reply(409, json: fixture('errors.request_in_progress'))
        ..reply(200, json: fixture('purchases.verify.granted.response'));
      expectOk(await h.client.verifyPurchase(_verify(), idempotencyKey: 'k'));
      expect(h.sleeps, [const Duration(seconds: 3)]);
    });
  });

  group('not retried', () {
    test('429 with Retry-After > 30 s fails with RateLimitedFailure', () async {
      h.adapter.reply(
        429,
        json: fixture('errors.rate_limited'),
        headers: {'Retry-After': '60'},
      );
      expect(
        expectErr(await h.client.fetchBalance()),
        const Failure.rateLimited(
          reason: RateLimitReason.burst,
          retryAfter: Duration(seconds: 60),
        ),
      );
      expect(h.requests, hasLength(1));
    });

    final business = <String, (int, String, Map<String, Object?>?)>{
      '429 dailyLimit': (429, 'RATE_LIMITED', {'reason': 'dailyLimit'}),
      '503 READINGS_DISABLED': (503, 'READINGS_DISABLED', null),
      '503 AI_BUDGET_EXHAUSTED': (503, 'AI_BUDGET_EXHAUSTED', {'tier': 'hard'}),
      '500 INTERNAL': (500, 'INTERNAL', null),
      '400 VALIDATION_FAILED': (400, 'VALIDATION_FAILED', null),
      '402 INSUFFICIENT_CREDITS': (402, 'INSUFFICIENT_CREDITS', null),
      '409 HOLD_CONFLICT': (409, 'HOLD_CONFLICT', null),
      '422 PURCHASE_INVALID': (422, 'PURCHASE_INVALID', null),
    };
    for (final entry in business.entries) {
      test(entry.key, () async {
        final (status, code, details) = entry.value;
        h.adapter.error(status, code, details: details, retryAfterSec: 1);
        expectErr(
          await h.client.verifyPurchase(_verify(), idempotencyKey: 'k'),
        );
        expect(h.requests, hasLength(1));
        expect(h.sleeps, isEmpty);
      });
    }

    test('a POST without Idempotency-Key (ack) is never re-sent', () async {
      h.adapter.fail(DioExceptionType.connectionError);
      expect(
        expectErr(await h.client.ackReading(const ReadingId('r'))),
        const Failure.network(),
      );
      expect(h.requests, hasLength(1));
    });

    test('a cancelled request is not retried', () async {
      h.adapter.fail(DioExceptionType.cancel);
      expect(expectErr(await h.client.fetchBalance()), const Failure.network());
      expect(h.requests, hasLength(1));
    });
  });

  group('backoffFor', () {
    RetryInterceptor withJitter(int value) => RetryInterceptor(
      dio: Dio(),
      random: FixedRandomSource(value),
      sleep: (_) async {},
    );

    test('±30 % jitter around 0.5 s × 2ⁿ', () {
      expect(withJitter(0).backoffFor(1), _ms * 350);
      expect(withJitter(600).backoffFor(1), _ms * 650);
      expect(withJitter(300).backoffFor(2), _ms * 1000);
      expect(withJitter(300).backoffFor(0), _ms * 500);
    });

    test('capped at 8 s', () {
      expect(withJitter(600).backoffFor(5), ApiTimeouts.backoffCap);
      expect(withJitter(300).backoffFor(10), ApiTimeouts.backoffCap);
    });

    test('isReplayable: GET or an Idempotency-Key', () {
      expect(RetryInterceptor.isReplayable(RequestOptions()), isTrue);
      expect(
        RetryInterceptor.isReplayable(RequestOptions(method: 'POST')),
        isFalse,
      );
      expect(
        RetryInterceptor.isReplayable(
          RequestOptions(method: 'POST', headers: {'Idempotency-Key': 'k'}),
        ),
        isTrue,
      );
    });

    test('realSleep waits', () async {
      await realSleep(Duration.zero);
    });
  });
}

Map<String, Object?> _envelope(String code) => {
  'error': {
    'code': code,
    'message': code,
    'requestId': 'r',
    'retryable': true,
    'retryAfterSec': null,
  },
};
