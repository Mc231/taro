import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/api/api_error_mapper.dart';
import 'package:taro/data/api/dto/error_envelope_dto.dart';
import 'package:taro/data/api/request_context.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import 'support/worker_client_harness.dart';

final _mapper = ApiErrorMapper(FakeClock.utc(kHarnessNow));

Failure _map(
  int status,
  String code, {
  Map<String, Object?>? details,
  int? retryAfterSec,
  Map<String, List<String>> headers = const {},
}) => _mapper.fromResponse(
  status,
  jsonEncode({
    'error': {
      'code': code,
      'message': 'm',
      'requestId': 'req-1',
      'retryable': false,
      'retryAfterSec': retryAfterSec,
      'details': ?details,
    },
  }),
  Headers.fromMap(headers),
);

void main() {
  group('every GLOSSARY §5 code', () {
    final table = <String, (int, Map<String, Object?>?, Failure)>{
      'VALIDATION_FAILED': (
        400,
        null,
        const Failure.contract(wireCode: 'VALIDATION_FAILED'),
      ),
      'IDEMPOTENCY_KEY_REQUIRED': (
        400,
        null,
        const Failure.contract(wireCode: 'IDEMPOTENCY_KEY_REQUIRED'),
      ),
      'UNAUTHENTICATED': (401, null, const Failure.sessionExpired()),
      'TOKEN_EXPIRED': (401, null, const Failure.sessionExpired()),
      'ATTESTATION_REQUIRED': (
        401,
        null,
        const Failure.attestation(kind: AttestationFailureKind.rejected),
      ),
      'INSUFFICIENT_CREDITS': (
        402,
        {'reason': 'lowTrustCap', 'freeResetsAt': '2026-09-26T22:00:00Z'},
        Failure.insufficientCredits(
          reason: InsufficientReason.lowTrustCap,
          freeResetsAt: DateTime.utc(2026, 9, 26, 22),
        ),
      ),
      'ATTESTATION_FAILED': (
        403,
        null,
        const Failure.attestation(kind: AttestationFailureKind.rejected),
      ),
      'REWARDED_DISABLED': (
        403,
        null,
        const Failure.rewardUnavailable(
          reason: RewardUnavailableReason.disabled,
        ),
      ),
      'AI_UNAVAILABLE_REGION': (403, null, const Failure.aiUnavailableRegion()),
      'NOT_FOUND': (404, null, const Failure.contract(wireCode: 'NOT_FOUND')),
      'REQUEST_IN_PROGRESS': (409, null, const Failure.requestInProgress()),
      'HOLD_CONFLICT': (409, null, const Failure.holdConflict()),
      'PURCHASE_ALREADY_CLAIMED': (
        409,
        {'transferEligible': false},
        const Failure.purchaseAlreadyClaimed(transferEligible: false),
      ),
      'REWARDED_DAILY_CAP': (
        409,
        {'reason': 'cap'},
        const Failure.rewardUnavailable(reason: RewardUnavailableReason.cap),
      ),
      'TIMEZONE_CHANGE_TOO_SOON': (
        409,
        {'allowedAfter': '2026-09-27T10:00:00Z'},
        Failure.timezoneChangeRejected(
          allowedAfter: DateTime.utc(2026, 9, 27, 10),
        ),
      ),
      'READING_EXPIRED_REFUNDED': (
        410,
        null,
        const Failure.readingExpiredRefunded(),
      ),
      'AI_CONSENT_REQUIRED': (
        412,
        {'requiredVersion': 2},
        const Failure.aiConsentRequired(requiredVersion: 2),
      ),
      'IDEMPOTENCY_KEY_REUSED': (
        422,
        null,
        const Failure.contract(wireCode: 'IDEMPOTENCY_KEY_REUSED'),
      ),
      'PURCHASE_INVALID': (
        422,
        {'reason': 'sandbox_cap'},
        const Failure.purchase(
          wireCode: 'PURCHASE_INVALID',
          reason: 'sandbox_cap',
        ),
      ),
      'PRODUCT_UNKNOWN': (
        422,
        null,
        const Failure.purchase(wireCode: 'PRODUCT_UNKNOWN'),
      ),
      'SPREAD_INVALID': (
        422,
        {'reason': 'disabled'},
        const Failure.contract(wireCode: 'SPREAD_INVALID'),
      ),
      'UPGRADE_REQUIRED': (400, null, const Failure.upgradeRequired()),
      'RATE_LIMITED': (
        429,
        {'reason': 'reportLimit'},
        const Failure.rateLimited(reason: RateLimitReason.reportLimit),
      ),
      'PURCHASE_PENDING': (202, null, const Failure.purchasePending()),
      'INTERNAL': (
        500,
        null,
        const Failure.server(
          status: 500,
          wireCode: 'INTERNAL',
          requestId: 'req-1',
        ),
      ),
      'AI_UNAVAILABLE': (503, null, const Failure.aiUnavailable()),
      'AI_BUDGET_EXHAUSTED': (
        503,
        {'tier': 'freeStop'},
        const Failure.readingsPaused(reason: PausedReason.freeStop),
      ),
      'READINGS_DISABLED': (
        503,
        null,
        const Failure.readingsPaused(reason: PausedReason.disabled),
      ),
    };

    test('the table covers every known code', () {
      expect(table.keys.toSet(), ApiErrorMapper.knownCodes);
    });

    for (final entry in table.entries) {
      test(entry.key, () {
        final (status, details, failure) = entry.value;
        expect(_map(status, entry.key, details: details), failure);
      });
    }

    test('the OpenAPI ErrorEnvelope enum is a subset of the known codes', () {
      final openApi =
          jsonDecode(
                File('../../worker/openapi/openapi.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final schemas =
          (openApi['components'] as Map<String, dynamic>)['schemas']
              as Map<String, dynamic>;
      final envelope = schemas['ErrorEnvelope'] as Map<String, dynamic>;
      final error =
          (envelope['properties'] as Map<String, dynamic>)['error']
              as Map<String, dynamic>;
      final code =
          (error['properties'] as Map<String, dynamic>)['code']
              as Map<String, dynamic>;
      final codes = (code['enum'] as List<dynamic>).cast<String>();
      expect(ApiErrorMapper.knownCodes, containsAll(codes));
    });
  });

  group('details', () {
    test('defaults when details are missing or mistyped', () {
      expect(
        _map(402, 'INSUFFICIENT_CREDITS', details: {'reason': 7}),
        const Failure.insufficientCredits(reason: InsufficientReason.noCredits),
      );
      expect(
        _map(429, 'RATE_LIMITED'),
        const Failure.rateLimited(reason: RateLimitReason.burst),
      );
      expect(
        _map(409, 'REWARDED_DAILY_CAP', details: {'availableAt': 'soon'}),
        const Failure.rewardUnavailable(reason: RewardUnavailableReason.cap),
      );
      expect(
        _map(412, 'AI_CONSENT_REQUIRED', details: {'requiredVersion': '2'}),
        const Failure.aiConsentRequired(),
      );
      expect(
        _map(503, 'AI_BUDGET_EXHAUSTED'),
        const Failure.readingsPaused(reason: PausedReason.budgetHard),
      );
    });

    test('REWARDED_DAILY_CAP cooldown carries availableAt', () {
      expect(
        _map(
          409,
          'REWARDED_DAILY_CAP',
          details: {
            'reason': 'cooldown',
            'availableAt': '2026-09-26T10:05:00Z',
          },
        ),
        Failure.rewardUnavailable(
          reason: RewardUnavailableReason.cooldown,
          availableAt: DateTime.utc(2026, 9, 26, 10, 5),
        ),
      );
    });

    test('balances in details are mapped; a malformed one is dropped', () {
      final ok = _map(
        402,
        'INSUFFICIENT_CREDITS',
        details: {'reason': 'freePaused', 'balance': balanceJson(bonus: 2)},
      );
      ok as InsufficientCreditsFailure;
      expect(ok.reason, InsufficientReason.freePaused);
      expect(ok.balance!.bonus, 2);
      expect(ok.balance!.syncedAt, kHarnessNow);
      expect(
        _map(
          410,
          'READING_EXPIRED_REFUNDED',
          details: {
            'balance': {'x': 1},
          },
        ),
        const Failure.readingExpiredRefunded(),
      );
    });

    test(
      'TIMEZONE_CHANGE_TOO_SOON without allowedAfter is a ServerFailure',
      () {
        expect(
          _map(409, 'TIMEZONE_CHANGE_TOO_SOON'),
          const Failure.server(
            status: 409,
            wireCode: 'TIMEZONE_CHANGE_TOO_SOON',
            requestId: 'req-1',
          ),
        );
      },
    );

    test('Retry-After: header first, then retryAfterSec', () {
      expect(
        _map(
          503,
          'READINGS_DISABLED',
          retryAfterSec: 50,
          headers: {
            'retry-after': ['10'],
          },
        ),
        const Failure.readingsPaused(
          reason: PausedReason.disabled,
          retryAfter: Duration(seconds: 10),
        ),
      );
      expect(
        _map(429, 'RATE_LIMITED', retryAfterSec: 50),
        const Failure.rateLimited(
          reason: RateLimitReason.burst,
          retryAfter: Duration(seconds: 50),
        ),
      );
      expect(
        ApiErrorMapper.retryAfter(
          Headers.fromMap({
            'retry-after': ['-1'],
          }),
          null,
        ),
        isNull,
      );
    });
  });

  group('unparseable and special statuses', () {
    test('an unknown code keeps its wire code', () {
      expect(
        _map(418, 'TEAPOT'),
        const Failure.server(
          status: 418,
          wireCode: 'TEAPOT',
          requestId: 'req-1',
        ),
      );
    });

    test('426 is UpgradeRequired even without an envelope', () {
      expect(
        _mapper.fromResponse(426, 'nope', Headers()),
        const Failure.upgradeRequired(),
      );
      expect(
        _map(426, 'UPGRADE_REQUIRED', details: {'storeUrl': 'https://s'}),
        const Failure.upgradeRequired(storeUrl: 'https://s'),
      );
    });

    test(
      'a non-envelope body is a ServerFailure with the header request ID',
      () {
        expect(
          _mapper.fromResponse(
            502,
            '<html/>',
            Headers.fromMap({
              'x-request-id': ['hdr-1'],
            }),
          ),
          const Failure.server(status: 502, requestId: 'hdr-1'),
        );
        expect(
          _mapper.fromResponse(500, {'error': 'flat'}, Headers()),
          const Failure.server(status: 500),
        );
        expect(
          _mapper.fromResponse(500, null, Headers()),
          isA<ServerFailure>(),
        );
      },
    );

    test('parseEnvelope accepts a decoded map', () {
      expect(
        ApiErrorMapper.parseEnvelope({
          'error': {'code': 'X'},
        }),
        isA<ApiErrorDto>(),
      );
      expect(ApiErrorMapper.parseEnvelope(42), isNull);
    });
  });

  group('transport', () {
    final options = RequestOptions(path: '/v1/balance');
    DioException ex(DioExceptionType type, [Object? error]) =>
        DioException(requestOptions: options, type: type, error: error);

    test('timeouts, connection problems and unknown errors', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ]) {
        expect(_mapper.fromDioException(ex(type)), const Failure.timeout());
      }
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.badCertificate,
        DioExceptionType.cancel,
      ]) {
        expect(_mapper.fromDioException(ex(type)), const Failure.network());
      }
      expect(
        _mapper.fromDioException(
          ex(DioExceptionType.unknown, const HttpException('x')),
        ),
        const Failure.network(),
      );
      expect(
        _mapper.fromDioException(
          ex(DioExceptionType.unknown, const TlsException('x')),
        ),
        const Failure.network(),
      );
      final unexpected = _mapper.fromDioException(ex(DioExceptionType.unknown));
      expect(unexpected, isA<UnexpectedFailure>());
    });

    test('a carried failure passes through', () {
      expect(
        _mapper.fromDioException(
          failureException(options, const Failure.storage()),
        ),
        const Failure.storage(),
      );
    });
  });
}
