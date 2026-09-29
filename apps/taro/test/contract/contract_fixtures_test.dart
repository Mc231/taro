// Client side of the Worker contract fixtures (06 QA15, RC38): every file in
// test/contract/fixtures/ (copied by `melos run contract:sync`) is decoded
// into its DTO and mapped to the domain, responses are checked against the
// Worker's OpenAPI schemas, and every request fixture is re-encoded from
// domain inputs byte-for-byte and validated strictly against its schema.
//
// Phase 8 routes (holds, readings, ack, report) have no fixtures yet; their
// client calls are covered with scripted HTTP in test/data/api/. The fixtures
// follow in Phase 8, and an unknown fixture name fails this test until a
// decoder is added below.
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' show Headers;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/api/api_error_mapper.dart';
import 'package:taro/data/api/dto/balance_dto.dart';
import 'package:taro/data/api/dto/error_envelope_dto.dart';
import 'package:taro/data/api/dto/install_dtos.dart';
import 'package:taro/data/api/dto/store_dtos.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../packages/taro_core/test/fakes/fakes.dart';
import 'support/openapi_schema.dart';

final DateTime _now = DateTime.utc(2026, 9, 26, 10);

Map<String, dynamic> _read(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

/// HTTP status of each error fixture (GLOSSARY §5).
const Map<String, int> _errorStatus = {
  'ATTESTATION_FAILED': 403,
  'ATTESTATION_REQUIRED': 401,
  'IDEMPOTENCY_KEY_REQUIRED': 400,
  'IDEMPOTENCY_KEY_REUSED': 422,
  'INTERNAL': 500,
  'NOT_FOUND': 404,
  'PRODUCT_UNKNOWN': 422,
  'PURCHASE_ALREADY_CLAIMED': 409,
  'PURCHASE_INVALID': 422,
  'RATE_LIMITED': 429,
  'REQUEST_IN_PROGRESS': 409,
  'REWARDED_DAILY_CAP': 409,
  'REWARDED_DISABLED': 403,
  'TIMEZONE_CHANGE_TOO_SOON': 409,
  'TOKEN_EXPIRED': 401,
  'UNAUTHENTICATED': 401,
  'UPGRADE_REQUIRED': 426,
  'VALIDATION_FAILED': 400,
};

/// `Failure.code` of a wire code where they differ (GLOSSARY §16.1).
const Map<String, String> _failureCode = {
  'ATTESTATION_REQUIRED': 'ATTESTATION_FAILED',
  'TOKEN_EXPIRED': 'UNAUTHENTICATED',
};

/// Domain inputs that must re-encode to each request fixture.
final Map<String, (String, Map<String, dynamic> Function())> _requests = {
  'installs.register.request': (
    'RegisterRequest',
    () => RegisterRequestDto(
      installId: 'c0a80101-0000-4000-8000-000000000001',
      installSecret: 'BwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwc',
      platform: AppPlatform.ios.name,
      appVersion: '1.2.0+14',
      locale: 'de',
      timezone: 'Europe/Berlin',
      attestation: RegistrationAttestationDto.fromBlob(
        const AttestationBlob(
          type: AttestationType.appAttest,
          challenge: 'CAiRGTO560_yKaXk2z5XFAAAAABqt5jMD571xG5G_pOucnLBULbWbQ',
          payload: 'b2JqZWN0',
          keyId: 'a2V5LWlk',
        ),
      ),
    ).toJson(),
  ),
  'installs.register_android.request': (
    'RegisterRequest',
    () => RegisterRequestDto(
      installId: 'c0a80101-0000-4000-8000-000000000002',
      installSecret: 'BwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwc',
      platform: AppPlatform.android.name,
      appVersion: '1.2.0+14',
      locale: 'de',
      timezone: 'Europe/Berlin',
      deviceKey: 'CQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQk',
      attestation: RegistrationAttestationDto.fromBlob(
        const AttestationBlob(
          type: AttestationType.playIntegrity,
          challenge: 'QgKCBhojWbYqO8o9CSQ-_gAAAABqt5jMrplLLebiirGfd7bLVxmUgA',
          payload: 'integrity.token',
        ),
      ),
    ).toJson(),
  ),
  'purchases.verify.ios.request': (
    'VerifyPurchaseRequest',
    () => VerifyPurchaseRequestDto.fromDomain(
      const StorePurchase(
        txnKey: '2000000100000020',
        productId: ProductId('com.vshyrochuk.taro.readings_3'),
        platform: StorePlatform.ios,
        transactionId: '2000000100000020',
      ),
    ).toJson(),
  ),
  'purchases.verify.android.request': (
    'VerifyPurchaseRequest',
    () => VerifyPurchaseRequestDto.fromDomain(
      const StorePurchase(
        txnKey: 'sha256-of-token',
        productId: ProductId('com.vshyrochuk.taro.readings_10'),
        platform: StorePlatform.android,
        purchaseToken: 'fixture-purchase-token-pending',
        orderId: 'GPA.3300-0000-0000-00001',
      ),
    ).toJson(),
  ),
  'rewards.intent.request': (
    'RewardIntentRequest',
    () => const RewardIntentRequestDto(
      adUnitId: 'ca-app-pub-3940256099942544/1712485313',
    ).toJson(),
  ),
  'timezone.request': (
    'TimezoneRequest',
    () => const TimezoneRequestDto(timezone: 'America/New_York').toJson(),
  ),
};

/// Decodes a response fixture and returns its OpenAPI schema name.
String _decodeResponse(String name, Map<String, dynamic> json) {
  final mapper = ApiErrorMapper(FakeClock.utc(_now));
  switch (name) {
    case 'balance.response' ||
        'balance.low_trust.response' ||
        'timezone.response':
      final balance = BalanceDto.fromJson(json).toDomain(syncedAt: _now);
      expect(balance, CreditBalance.fromDto(json, syncedAt: _now));
      return 'BalanceDto';
    case 'config.response':
      final clamped = <String>[];
      final config = RemoteConfig.fromJson(json, onClamped: clamped.add);
      expect(clamped, isEmpty, reason: 'fixture values are in range');
      expect(config.version, json['version']);
      return 'PublicConfigDto';
    case 'installs.challenge.response':
      expect(ChallengeDto.fromJson(json).powBits, greaterThan(0));
      return 'AttestChallenge';
    case 'installs.register.response' ||
        'installs.register_android.response' ||
        'installs.reregister.response':
      final dto = RegistrationResponseDto.fromJson(json);
      expect(dto.toSessionToken().expiresAt.isUtc, isTrue);
      expect(dto.toTrust(), isA<Trust>());
      dto.balance.toDomain(syncedAt: _now);
      RemoteConfig.fromJson(dto.config);
      final binding = dto.purchaseBinding.toDomain();
      expect(
        binding.appleAccountToken ?? binding.playAccountId,
        isNotNull,
      );
      return 'RegistrationResponse';
    case 'installs.token.response':
      final dto = InstallTokenDto.fromJson(json);
      expect(dto.toTrust(), Trust.high);
      expect(dto.toSessionToken().token, isNotEmpty);
      return 'InstallTokenResponse';
    case 'purchases.verify.granted.response' ||
        'purchases.verify.already_granted.response':
      final grant = VerifyPurchaseResponseDto.fromJson(
        json,
      ).toDomain(syncedAt: _now);
      expect(grant.balance, isNotNull);
      expect(grant.productId, isNotNull);
      return 'VerifyPurchaseGranted';
    case 'purchases.verify.pending.response':
      expect(
        VerifyPurchaseResponseDto.fromJson(
          json,
        ).toDomain(syncedAt: _now).status,
        GrantStatus.pending,
      );
      return 'VerifyPurchasePending';
    case 'rewards.intent.response':
      final intent = RewardIntentDto.fromJson(json);
      expect(intent.customData, intent.intentId, reason: 'RC56');
      expect(intent.userId, intent.intentId, reason: 'RC56');
      intent.toDomain();
      return 'RewardIntent';
    case 'rewards.intent.status_issued.response' ||
        'rewards.intent.status_granted.response':
      RewardIntentStatusDto.fromJson(json).toDomain(syncedAt: _now);
      return 'RewardIntentStatus';
  }
  if (name.startsWith('errors.')) {
    final envelope = ErrorEnvelopeDto.fromJson(json).error;
    final code = envelope.code;
    expect(name, 'errors.${code.toLowerCase()}', reason: 'one file per code');
    expect(ApiErrorMapper.knownCodes, contains(code));
    final status = _errorStatus[code];
    expect(status, isNotNull, reason: 'add $code to _errorStatus');
    final failure = mapper.fromResponse(status!, jsonEncode(json), Headers());
    expect(failure.code, _failureCode[code] ?? code);
    return 'ErrorEnvelope';
  }
  fail('No decoder for fixture "$name": add one to contract_fixtures_test');
}

void main() {
  final openApi = OpenApiDocument.load();
  final files =
      Directory('test/contract/fixtures')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('the fixture tree is present', () {
    expect(files.length, greaterThanOrEqualTo(39));
  });

  for (final file in files) {
    final name = file.uri.pathSegments.last.replaceFirst(
      RegExp(r'\.json$'),
      '',
    );
    test(name, () {
      final json = _read(file);
      if (name.endsWith('.request')) {
        final entry = _requests[name];
        if (entry == null) {
          fail('No encoder for request fixture "$name"');
        }
        final (schema, encode) = entry;
        final encoded = encode();
        expect(encoded, json, reason: 'the client encodes the fixture');
        expect(openApi.validate(schema, encoded), isEmpty);
        return;
      }
      final schema = _decodeResponse(name, json);
      expect(openApi.validate(schema, json, strict: false), isEmpty);
    });
  }

  group('OpenApiDocument validator', () {
    test('rejects wrong types, enums, formats, patterns and extras', () {
      final bad = {
        'installId': 'not-a-uuid',
        'installSecret': 'short',
        'platform': 'web',
        'appVersion': 3,
        'locale': 'xx',
        'timezone': '',
        'attestation': {'type': 'app_attest', 'challenge': 'c'},
        'extra': true,
      };
      final problems = openApi.validate('RegisterRequest', bad);
      expect(problems, hasLength(greaterThanOrEqualTo(7)));
      expect(problems.join('\n'), contains('extra is not declared'));
      expect(problems.join('\n'), contains('oneOf'));
      expect(
        openApi.validate('RewardIntentRequest', {'adUnitId': 'x' * 200}),
        isNotEmpty,
      );
      expect(
        openApi.validate('AttestChallenge', {
          'challenge': 'c',
          'expiresAt': 'noon',
          'powBits': 1,
        }),
        isNotEmpty,
      );
      expect(
        openApi.validate('BalanceDto', {
          ...fixture('balance.response'),
          'free': {
            ...(fixture('balance.response')['free'] as Map<String, dynamic>),
            'localDate': '26/09',
          },
        }, strict: false),
        isNotEmpty,
      );
      expect(() => openApi.validate('Nope', {}), throwsArgumentError);
    });

    test(
      'the transferToken field of 02 §6.3 is not in the Worker schema yet',
      () {
        final withTransfer = VerifyPurchaseRequestDto.fromDomain(
          const StorePurchase(
            txnKey: '1',
            productId: ProductId('com.vshyrochuk.taro.readings_3'),
            platform: StorePlatform.ios,
            transactionId: '1',
          ),
          transferToken: 'tt1.x',
        ).toJson();
        expect(
          openApi.validate('VerifyPurchaseRequest', withTransfer),
          isNotEmpty,
          reason: 'flip this when the Worker declares transferToken (RC84)',
        );
      },
    );
  });
}

Map<String, dynamic> fixture(String name) =>
    _read(File('test/contract/fixtures/$name.json'));
