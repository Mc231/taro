import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/api/dto/reading_dtos.dart';
import 'package:taro/data/api/endpoints.dart';
import 'package:taro/data/api/interceptors/ai_consent_interceptor.dart';
import 'package:taro/data/api/interceptors/attestation_interceptor.dart';
import 'package:taro/data/api/request_context.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contract_support.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import 'support/worker_client_harness.dart';

const _id = ReadingId('r-1');

HoldRequestDto _hold([ReadingId id = _id]) => HoldRequestDto(
  clientReadingId: id.value,
  spread: const SpreadRefDto(id: 'single', version: 1),
  locale: 'de',
);

Map<String, dynamic> _holdResponse() => {
  'clientReadingId': _id.value,
  'chargeSource': 'free',
  'expiresAt': '2026-09-26T10:15:00Z',
  'balance': balanceJson(),
};

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('HeadersInterceptor', () {
    test('sends the common headers; flavor only when set', () async {
      final h = WorkerClientHarness(flavor: 'staging');
      h.adapter.reply(200, json: balanceJson());
      await h.client.fetchBalance();
      expect(h.last.header('x-taro-platform'), 'ios');
      expect(h.last.header('x-taro-app-version'), '1.2.0+14');
      expect(h.last.header('x-taro-locale'), 'de');
      expect(h.last.header('x-taro-flavor'), 'staging');
      expect(h.last.header('x-request-id'), 'rid-1');
      expect(h.last.header('content-type'), isNot(contains('json')));

      final prod = WorkerClientHarness(platform: AppPlatform.android)
        ..locale = 'uk';
      prod.adapter.reply(200, json: balanceJson());
      await prod.client.fetchBalance();
      expect(prod.last.header('x-taro-flavor'), isNull);
      expect(prod.last.header('x-taro-platform'), 'android');
      expect(prod.last.header('x-taro-locale'), 'uk');
    });

    test('a body is JSON; X-Request-Id is new per attempt while the '
        'Idempotency-Key is reused', () async {
      final h = WorkerClientHarness();
      h.adapter
        ..fail(DioExceptionType.connectionError)
        ..reply(201, json: _holdResponse());
      expectOk(await h.client.createHold(_hold()));
      expect(h.requests, hasLength(2));
      expect(h.requests.map((r) => r.header('x-request-id')), [
        'rid-1',
        'rid-2',
      ]);
      expect(h.requests.map((r) => r.header('idempotency-key')), [
        'r-1',
        'r-1',
      ]);
      expect(h.last.header('content-type'), 'application/json; charset=utf-8');
      expect(utf8.decode(h.requests.first.body), utf8.decode(h.last.body));
    });

    test(
      'every Date header, success or error, updates the server clock',
      () async {
        final h = WorkerClientHarness();
        h.adapter.reply(
          204,
          headers: {'Date': 'Sat, 26 Sep 2026 10:01:00 GMT'},
        );
        await h.client.ackReading(_id);
        expect(h.client.serverClock.current.offset, const Duration(minutes: 1));
        h.adapter.reply(
          404,
          json: fixture('errors.not_found'),
          headers: {'Date': 'Sat, 26 Sep 2026 09:59:00 GMT'},
        );
        await h.client.ackReading(_id);
        expect(
          h.client.serverClock.current.offset,
          const Duration(minutes: -1),
        );
        h.adapter.reply(204, headers: {'Date': 'yesterday'});
        await h.client.ackReading(_id);
        expect(
          h.client.serverClock.current.offset,
          const Duration(minutes: -1),
        );
      },
    );
  });

  group('AuthInterceptor', () {
    test('no stored token → SessionExpiredFailure without a request', () async {
      final h = WorkerClientHarness(noToken: true);
      expect(
        expectErr(await h.client.fetchBalance()),
        const Failure.sessionExpired(),
      );
      expect(h.requests, isEmpty);
      expect(h.sessionExpiredCalls, 1);
    });

    test('a token store failure is a StorageFailure', () async {
      final h = WorkerClientHarness();
      h.tokens.failNext(const Failure.storage(), on: 'read');
      expect(expectErr(await h.client.fetchBalance()), const Failure.storage());
      expect(h.requests, isEmpty);
    });

    test('TOKEN_EXPIRED → one refresh, one retry with the new token', () async {
      final h = WorkerClientHarness();
      h.adapter
        ..error(401, 'TOKEN_EXPIRED')
        ..reply(200, json: fixture('installs.token.response'))
        ..reply(200, json: balanceJson());
      expectOk(await h.client.fetchBalance());
      expect(h.requests.map((r) => r.route), [
        'GET /v1/balance',
        'POST /v1/installs/token',
        'GET /v1/balance',
      ]);
      expect(h.requests.first.header('authorization'), 'Bearer token-1');
      expect(h.requests[1].header('authorization'), 'Bearer token-1');
      expect(h.last.header('authorization'), startsWith('Bearer eyJ'));
      expect(h.sessionExpiredCalls, 0);
    });

    test('concurrent TOKEN_EXPIRED responses share a single refresh', () async {
      final h = WorkerClientHarness();
      h.adapter
        ..error(401, 'TOKEN_EXPIRED')
        ..error(401, 'TOKEN_EXPIRED')
        ..error(401, 'TOKEN_EXPIRED')
        ..reply(200, json: fixture('installs.token.response'))
        ..replyTimes(3, 200, json: balanceJson());
      final results = await Future.wait([
        h.client.fetchBalance(),
        h.client.fetchBalance(),
        h.client.fetchBalance(),
      ]);
      results.forEach(expectOk);
      expect(
        h.requests.where((r) => r.path == '/v1/installs/token'),
        hasLength(1),
      );
      expect(h.requests, hasLength(7));
    });

    test(
      'a second TOKEN_EXPIRED after the refresh is SessionExpired',
      () async {
        final h = WorkerClientHarness();
        h.adapter
          ..error(401, 'TOKEN_EXPIRED')
          ..reply(200, json: fixture('installs.token.response'))
          ..error(401, 'TOKEN_EXPIRED');
        expect(
          expectErr(await h.client.fetchBalance()),
          const Failure.sessionExpired(),
        );
        expect(h.requests, hasLength(3));
        expect(h.sessionExpiredCalls, 1);
      },
    );

    test('UNAUTHENTICATED → SessionExpired and the re-register hook', () async {
      final h = WorkerClientHarness();
      h.adapter.reply(401, json: fixture('errors.unauthenticated'));
      expect(
        expectErr(await h.client.fetchBalance()),
        const Failure.sessionExpired(),
      );
      expect(h.requests, hasLength(1));
      expect(h.sessionExpiredCalls, 1);
    });

    test('a refresh rejected with UNAUTHENTICATED → SessionExpired, '
        'notified once', () async {
      final h = WorkerClientHarness();
      h.adapter
        ..error(401, 'TOKEN_EXPIRED')
        ..error(401, 'UNAUTHENTICATED');
      expect(
        expectErr(await h.client.fetchBalance()),
        const Failure.sessionExpired(),
      );
      expect(h.sessionExpiredCalls, 1);
    });

    test('a refresh failing with 500 → SessionExpired', () async {
      final h = WorkerClientHarness();
      h.adapter
        ..error(401, 'TOKEN_EXPIRED')
        ..error(500, 'INTERNAL');
      expect(
        expectErr(await h.client.fetchBalance()),
        const Failure.sessionExpired(),
      );
      expect(h.sessionExpiredCalls, 1);
    });

    test('a refresh failing on the network keeps NetworkFailure', () async {
      final h = WorkerClientHarness();
      h.adapter
        ..error(401, 'TOKEN_EXPIRED')
        ..fail(DioExceptionType.badCertificate);
      expect(
        expectErr(await h.client.fetchBalance()),
        const Failure.network(),
      );
      expect(h.sessionExpiredCalls, 0);
    });

    test('the refresh route itself is never refreshed', () async {
      final h = WorkerClientHarness();
      h.adapter.error(401, 'TOKEN_EXPIRED');
      expect(
        expectErr(await h.client.refreshToken()),
        const Failure.sessionExpired(),
      );
      expect(h.requests, hasLength(1));
      expect(h.sessionExpiredCalls, 1);
    });

    test('other 401 codes pass through', () async {
      final h = WorkerClientHarness();
      h.adapter.reply(401, json: fixture('errors.attestation_required'));
      expect(
        expectErr(await h.client.createHold(_hold())),
        const Failure.attestation(kind: AttestationFailureKind.rejected),
      );
      expect(h.sessionExpiredCalls, 0);
    });
  });

  group('AttestationInterceptor', () {
    test('clientDataHash matches the Worker known answers', () {
      final body = utf8.encode('{"clientReadingId":"r-1"}');
      expect(
        _hex(
          AttestationInterceptor.clientDataHash(
            method: 'post',
            path: '/v1/readings/holds',
            body: body,
            idempotencyKey: 'r-1',
          ),
        ),
        '5fa3a296ce0f3e33672eb21aa0d06765631ee36ec312b3dc961cdd39bf75a103',
      );
      expect(
        _hex(
          AttestationInterceptor.clientDataHash(
            method: 'POST',
            path: '/v1/installs/token',
            body: const [],
          ),
        ),
        '819aec6f8723d5e94a20a3fc5fb756a03357bff0e45a8f35efd0c616011a3318',
      );
    });

    test(
      'asserts over the exact bytes sent, only on attested routes',
      () async {
        final h = WorkerClientHarness();
        h.adapter
          ..reply(201, json: _holdResponse())
          ..reply(200, json: balanceJson());
        expectOk(await h.client.createHold(_hold()));
        final hold = h.requests.first;
        expect(hold.header('x-taro-attestation'), 'aa1.assertion-1');
        expect(
          h.attestation.assertions.single,
          AttestationInterceptor.clientDataHash(
            method: 'POST',
            path: '/v1/readings/holds',
            body: hold.body,
            idempotencyKey: 'r-1',
          ),
        );
        expectOk(await h.client.fetchBalance());
        expect(h.last.header('x-taro-attestation'), isNull);
        expect(h.attestation.assertions, hasLength(1));
      },
    );

    test('Android sends pi1., an unsupported device sends none', () async {
      final android = WorkerClientHarness(
        attestationKind: AttestationType.playIntegrity,
        platform: AppPlatform.android,
      );
      android.adapter.reply(201, json: fixture('rewards.intent.response'));
      await android.client.createRewardIntent('unit', idempotencyKey: 't');
      expect(android.last.header('x-taro-attestation'), 'pi1.token-1');

      final none = WorkerClientHarness(attestationKind: AttestationType.none);
      none.adapter.reply(201, json: fixture('rewards.intent.response'));
      await none.client.createRewardIntent('unit', idempotencyKey: 't');
      expect(none.last.header('x-taro-attestation'), 'none');
      expect(none.attestation.assertions, isEmpty);
    });

    test('a failed assertion stops the request with its failure', () async {
      final h = WorkerClientHarness();
      h.attestation.failNext(
        const Failure.attestation(kind: AttestationFailureKind.keyInvalidated),
      );
      expect(
        expectErr(await h.client.createHold(_hold())),
        const Failure.attestation(kind: AttestationFailureKind.keyInvalidated),
      );
      expect(h.requests, isEmpty);
    });

    test('each retry carries a fresh assertion', () async {
      final h = WorkerClientHarness();
      h.adapter
        ..fail(DioExceptionType.connectionTimeout)
        ..reply(201, json: _holdResponse());
      expectOk(await h.client.createHold(_hold()));
      expect(h.requests.map((r) => r.header('x-taro-attestation')), [
        'aa1.assertion-1',
        'aa1.assertion-2',
      ]);
    });

    test('a foreign request passes untouched', () async {
      final interceptor = AttestationInterceptor(FakeAttestationService());
      final options = RequestOptions(path: '/x');
      final handler = RequestInterceptorHandler();
      await interceptor.onRequest(options, handler);
      expect(options.headers, isNot(contains('X-Taro-Attestation')));
    });
  });

  group('AiConsentInterceptor', () {
    test('adds the granted version on holds and readings only', () async {
      final h = WorkerClientHarness(
        consent: ConsentState(
          ai: AiConsent(
            decision: AiConsentDecision.granted,
            version: 3,
            at: DateTime.utc(2026),
          ),
        ),
      );
      h.adapter
        ..reply(201, json: _holdResponse())
        ..reply(200, json: balanceJson());
      await h.client.createHold(_hold());
      expect(h.requests.first.header('x-taro-ai-consent'), '3');
      await h.client.fetchBalance();
      expect(h.last.header('x-taro-ai-consent'), isNull);
    });

    test('omits the header without a granted consent → 412 maps', () async {
      final h = WorkerClientHarness(
        consent: const ConsentState(
          ai: AiConsent(decision: AiConsentDecision.declined, version: 1),
        ),
      );
      h.adapter.error(
        412,
        'AI_CONSENT_REQUIRED',
        details: {'requiredVersion': 2},
      );
      expect(
        expectErr(await h.client.createHold(_hold())),
        const Failure.aiConsentRequired(requiredVersion: 2),
      );
      expect(h.last.header('x-taro-ai-consent'), isNull);
    });

    test('removes a stale header when consent is gone', () {
      final interceptor = AiConsentInterceptor(FakeConsentStore());
      final options = RequestOptions(
        path: '/v1/readings',
        extra: requestExtra(Endpoints.createReading),
        headers: {'X-Taro-AI-Consent': '1'},
      );
      interceptor.onRequest(options, RequestInterceptorHandler());
      expect(options.headers, isNot(contains('X-Taro-AI-Consent')));
    });
  });
}
