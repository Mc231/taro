import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/api/dto/balance_dto.dart';
import 'package:taro/data/api/dto/install_dtos.dart';
import 'package:taro/data/api/dto/json_support.dart';
import 'package:taro/data/api/dto/reading_dtos.dart';
import 'package:taro/data/api/dto/store_dtos.dart';
import 'package:taro/data/api/worker_models.dart';
import 'package:taro_core/taro_core.dart';

import 'support/worker_client_harness.dart';

final _now = DateTime.utc(2026, 9, 26, 10);

void main() {
  group('json support', () {
    test('instants must be zoned and come back in UTC', () {
      expect(
        parseUtcInstant('2026-09-26T12:00:00+02:00'),
        DateTime.utc(2026, 9, 26, 10),
      );
      expect(
        () => parseUtcInstant('2026-09-26T10:00:00'),
        throwsFormatException,
      );
      expect(() => parseUtcInstant('soon'), throwsFormatException);
      expect(
        formatUtcInstant(DateTime.utc(2026, 9, 26, 9, 10, 2)),
        '2026-09-26T09:10:02Z',
      );
      expect(
        formatUtcInstant(DateTime.utc(2026, 9, 26, 9, 10, 2, 5)),
        '2026-09-26T09:10:02.005Z',
      );
      const converter = UtcInstantConverter();
      expect(
        converter.toJson(converter.fromJson('2026-09-26T10:00:00Z')),
        '2026-09-26T10:00:00Z',
      );
      const nullable = NullableUtcInstantConverter();
      expect(nullable.fromJson(null), isNull);
      expect(nullable.toJson(null), isNull);
      expect(nullable.toJson(_now), '2026-09-26T10:00:00Z');
    });

    test('local dates and wire enums are checked', () {
      expect(checkLocalDate('2026-09-26'), '2026-09-26');
      expect(() => checkLocalDate('26.09.2026'), throwsFormatException);
      expect(optWireEnum({'a': 1}, null, 'f'), isNull);
      expect(wireEnum({'a': 1}, 'a', 'f'), 1);
      expect(() => wireEnum({'a': 1}, 'b', 'f'), throwsFormatException);
    });
  });

  group('BalanceDto → CreditBalance (RC6, RC67)', () {
    test('maps every field and agrees with CreditBalance.fromDto', () {
      final json = {
        ...balanceJson(ledgerVersion: 12, paid: -2),
        'canRead': false,
        'canReadReason': 'dailyLimit',
        'nextSource': 'none',
        'purchasesAllowed': false,
        'purchasesBlockedReason': 'refundDebt',
        'free': {
          ...(balanceJson()['free'] as Map<String, dynamic>),
          'paused': true,
        },
      };
      final balance = BalanceDto.fromJson(json).toDomain(syncedAt: _now);
      expect(balance, CreditBalance.fromDto(json, syncedAt: _now));
      expect(balance.canReadReason, CanReadReason.dailyLimit);
      expect(balance.nextSource, isNull);
      expect(balance.purchasesBlockedReason, PurchasesBlockedReason.refundDebt);
      expect(balance.free.paused, isTrue);
      expect(balance.paidBlocked, isFalse);
    });

    test('the RC67 order holds on mapped responses', () {
      CreditBalance at(int version, String serverTime) => BalanceDto.fromJson(
        balanceJson(ledgerVersion: version, serverTime: serverTime),
      ).toDomain(syncedAt: _now);
      final cached = at(5, '2026-09-26T10:00:00Z');
      expect(at(6, '2026-09-26T09:00:00Z').shouldReplace(cached), isTrue);
      expect(at(5, '2026-09-26T10:00:01Z').shouldReplace(cached), isTrue);
      expect(at(5, '2026-09-26T10:00:00Z').shouldReplace(cached), isFalse);
      expect(at(4, '2026-09-26T11:00:00Z').isAcceptableOver(cached), isFalse);
    });

    test('an unknown enum or local date is a FormatException', () {
      expect(
        () => BalanceDto.fromJson({
          ...balanceJson(),
          'canReadReason': 'sleepy',
        }).toDomain(syncedAt: _now),
        throwsFormatException,
      );
      expect(
        () => BalanceDto.fromJson({
          ...balanceJson(),
          'free': {
            ...(balanceJson()['free'] as Map<String, dynamic>),
            'localDate': 'today',
          },
        }).toDomain(syncedAt: _now),
        throwsFormatException,
      );
    });
  });

  group('install DTOs', () {
    test('RegistrationAttestationDto.fromBlob per attestation type', () {
      expect(
        RegistrationAttestationDto.fromBlob(
          const AttestationBlob(
            type: AttestationType.playIntegrity,
            challenge: 'c',
            payload: 'tok',
          ),
        ).toJson(),
        {'type': 'play_integrity', 'challenge': 'c', 'integrityToken': 'tok'},
      );
      expect(
        RegistrationAttestationDto.fromBlob(
          const AttestationBlob(type: AttestationType.none, challenge: 'c'),
          pow: '42',
        ).toJson(),
        {
          'type': 'none',
          'challenge': 'c',
          'reason': 'unsupported',
          'pow': '42',
        },
      );
      expect(
        RegistrationAttestationDto.fromBlob(
          const AttestationBlob(
            type: AttestationType.appAttest,
            challenge: 'c',
            payload: 'obj',
            keyId: 'kid',
          ),
          previousKeyAssertion: 'prev',
        ).toJson(),
        {
          'type': 'app_attest',
          'challenge': 'c',
          'keyId': 'kid',
          'attestationObject': 'obj',
          'previousKeyAssertion': 'prev',
        },
      );
    });

    test('an unknown trust is a FormatException; toString hides the token', () {
      final dto = InstallTokenDto.fromJson({
        ...fixture('installs.token.response'),
        'trust': 'medium',
      });
      expect(dto.toTrust, throwsFormatException);
      expect(dto.toString(), isNot(contains('eyJ')));
      final reg = RegistrationResponseDto.fromJson(
        fixture('installs.register_android.response'),
      );
      expect(reg.toString(), isNot(contains('eyJ')));
      expect(reg.purchaseBinding.toDomain().playAccountId, isNotNull);
    });
  });

  group('reading DTOs', () {
    test('HoldDto with an unknown chargeSource is a FormatException', () {
      final dto = HoldDto.fromJson({
        'clientReadingId': 'r',
        'chargeSource': 'none',
        'expiresAt': '2026-09-26T10:15:00Z',
        'balance': balanceJson(),
      });
      expect(() => dto.toDomain(syncedAt: _now), throwsFormatException);
    });

    test('the wire reading round-trips through the domain (RC30)', () {
      final wire = ReadingWireDto.fromJson(wireReading());
      final content = wire.toDomain();
      final cards = [
        DrawnCard(
          positionId: const PositionId('focus'),
          cardId: CardId.parse('major_16'),
          reversed: false,
        ),
      ];
      expect(ReadingWireDto.fromDomain(content, cards).toJson(), wireReading());
      expect(
        () => ReadingWireDto.fromDomain(content, const []),
        throwsArgumentError,
      );
    });

    test('SafetyDto: unknown category → other, default messageKey', () {
      final safety = SafetyDto.fromJson({
        'category': 'astrology',
        'canRephrase': false,
      }).toDomain();
      expect(safety.category, RefusalCategory.other);
      expect(safety.messageKey, 'refusalGeneric');
      expect(safety.crisisResources, isEmpty);
    });

    test('a crisis resource without a contact channel is rejected', () {
      expect(
        () => CrisisResourceDto.fromJson({
          'name': 'Nobody',
          'verifiedAt': '2026-09-01T00:00:00Z',
        }).toDomain(),
        throwsFormatException,
      );
    });

    test('a crisis resource verifiedAt is a calendar date (03 §9.5)', () {
      final dated = CrisisResourceDto.fromJson({
        'name': 'Samaritans',
        'phone': '116 123',
        'verifiedAt': '2026-10-05',
      }).toDomain();
      expect(dated.verifiedAt, DateTime.utc(2026, 10, 5));
      expect(dated.isVerified, isTrue);
      final instant = CrisisResourceDto.fromJson({
        'name': 'Samaritans',
        'phone': '116 123',
        'verifiedAt': '2026-10-05T08:00:00Z',
      }).toDomain();
      expect(instant.verifiedAt, DateTime.utc(2026, 10, 5, 8));
      const converter = NullableVerifiedDateConverter();
      expect(converter.fromJson(null), isNull);
      expect(() => converter.fromJson('05.10.2026'), throwsFormatException);
      expect(converter.toJson(null), isNull);
      expect(converter.toJson(DateTime.utc(2026, 10, 5, 8)), '2026-10-05');
    });

    test('ReadingResponseDto with an unknown status or missing safety', () {
      expect(
        () => ReadingResponseDto.fromJson({
          'status': 'pondering',
          'balance': balanceJson(),
        }).toDomain(syncedAt: _now),
        throwsFormatException,
      );
      expect(
        () => ReadingResponseDto.fromJson({
          'status': 'declined',
          'balance': balanceJson(),
        }).toDomain(syncedAt: _now),
        throwsFormatException,
      );
    });

    test('a report without a reading omits it', () {
      final dto = ReportRequestDto.fromDomain(
        const ReadingReport(
          readingId: ReadingId('r'),
          reason: ReportReason.other,
          locale: 'en',
          idempotencyKey: 'k',
        ),
      );
      expect(dto.toJson(), {'reason': 'other', 'locale': 'en'});
    });
  });

  group('ReadingOutcome.status', () {
    final balance = BalanceDto.fromJson(balanceJson()).toDomain(syncedAt: _now);

    test('maps each outcome to the local status (02 §4)', () {
      expect(
        ReadingOutcome.inProgress(
          workerStatus: 'held',
          balance: balance,
        ).status,
        const ReadingStatus.pending(),
      );
      expect(
        ReadingOutcome.failed(workerStatus: 'failed', balance: balance).status,
        const ReadingStatus.failed(Failure.aiUnavailable(), refunded: true),
      );
      expect(
        ReadingOutcome.failed(
          workerStatus: 'expired_hold',
          balance: balance,
        ).status,
        const ReadingStatus.failed(Failure.aiUnavailable(), refunded: true),
      );
      expect(
        ReadingOutcome.failed(
          workerStatus: 'no_credit',
          balance: balance,
        ).status,
        const ReadingStatus.failed(Failure.holdConflict()),
      );
      expect(
        ReadingOutcome.failed(
          workerStatus: 'expired_refunded',
          balance: balance,
        ).status,
        ReadingStatus.failed(
          Failure.readingExpiredRefunded(balance: balance),
          refunded: true,
        ),
      );
    });
  });

  group('store DTOs', () {
    test('VerifyPurchaseRequestDto sends only the platform fields', () {
      const android = StorePurchase(
        txnKey: 'h',
        productId: ProductId('com.vshyrochuk.taro.readings_10'),
        platform: StorePlatform.android,
        transactionId: 'ignored',
        purchaseToken: 'tok',
        orderId: 'GPA.1',
      );
      final dto = VerifyPurchaseRequestDto.fromDomain(
        android,
        transferToken: 'tt1.x',
      );
      expect(dto.toJson(), {
        'platform': 'android',
        'productId': 'com.vshyrochuk.taro.readings_10',
        'purchaseToken': 'tok',
        'orderId': 'GPA.1',
        'transferToken': 'tt1.x',
      });
      expect(dto.toString(), isNot(contains('tok')));
    });

    test(
      'a grant without a balance or with an unknown status is malformed',
      () {
        expect(
          () => VerifyPurchaseResponseDto.fromJson({
            'status': 'granted',
          }).toDomain(syncedAt: _now),
          throwsFormatException,
        );
        expect(
          () => VerifyPurchaseResponseDto.fromJson({
            'status': 'maybe',
          }).toDomain(syncedAt: _now),
          throwsFormatException,
        );
      },
    );

    test('an unknown reward state is a FormatException', () {
      expect(
        () => RewardIntentStatusDto.fromJson({
          'status': 'paused',
          'amount': 1,
        }).toDomain(syncedAt: _now),
        throwsFormatException,
      );
    });
  });
}
