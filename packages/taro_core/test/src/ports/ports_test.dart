import 'package:taro_core/src/analytics/analytics.dart';
import 'package:taro_core/src/model/models.dart';
import 'package:taro_core/src/ports/ports.dart';
import 'package:taro_core/src/result/result_barrel.dart';
import 'package:test/test.dart';

import '../model/model_fixtures.dart';

void main() {
  group('SessionToken', () {
    final token = SessionToken(
      token: 'jwt',
      expiresAt: DateTime.utc(2026, 10, 3, 12),
    );

    test('refreshes within 24 h of expiry', () {
      expect(token.needsRefreshAt(DateTime.utc(2026, 10, 2, 11, 59)), isFalse);
      expect(token.needsRefreshAt(DateTime.utc(2026, 10, 2, 12)), isTrue);
      expect(token.needsRefreshAt(DateTime.utc(2026, 10, 4)), isTrue);
    });

    test('has value equality', () {
      expect(
        token,
        SessionToken(token: 'jwt', expiresAt: DateTime.utc(2026, 10, 3, 12)),
      );
      expect(token.copyWith(token: 'other'), isNot(token));
    });
  });

  group('ReadingHold', () {
    // Fixture balance: serverTime 09:12:44Z, synced at device 09:12:45Z,
    // so the server runs one second behind the device.
    ReadingHold holdExpiring(DateTime expiresAt) => ReadingHold(
      readingId: const ReadingId('0c6e2b1e-1111-4222-8333-444455556666'),
      chargeSource: ChargeSource.free,
      expiresAt: expiresAt,
      balance: balance(),
    );

    test('estimates server time from the balance sample', () {
      final hold = holdExpiring(DateTime.utc(2026, 9, 26, 9, 27, 44));
      expect(
        hold.serverNowAt(DateTime.utc(2026, 9, 26, 9, 13, 45)),
        DateTime.utc(2026, 9, 26, 9, 13, 44),
      );
    });

    test('needs renewal below 120 s left by server time', () {
      final hold = holdExpiring(DateTime.utc(2026, 9, 26, 9, 20));
      // Server 09:17:59 -> 121 s left.
      expect(hold.needsRenewalAt(DateTime.utc(2026, 9, 26, 9, 18)), isFalse);
      // Server 09:18:00 -> exactly 120 s left.
      expect(hold.needsRenewalAt(DateTime.utc(2026, 9, 26, 9, 18, 1)), isFalse);
      // Server 09:18:01 -> 119 s left.
      expect(hold.needsRenewalAt(DateTime.utc(2026, 9, 26, 9, 18, 2)), isTrue);
    });

    test('expires at expiresAt by server time', () {
      final hold = holdExpiring(DateTime.utc(2026, 9, 26, 9, 20));
      expect(hold.isExpiredAt(DateTime.utc(2026, 9, 26, 9, 20)), isFalse);
      expect(hold.isExpiredAt(DateTime.utc(2026, 9, 26, 9, 20, 1)), isTrue);
    });
  });

  group('OutboxEntry', () {
    final purchase = StorePurchase(
      txnKey: '2000000712345678',
      productId: TaroProducts.readings3.id,
      platform: StorePlatform.ios,
      transactionId: '2000000712345678',
    );
    OutboxEntry entry(OutboxStatus status) => OutboxEntry(
      purchase: purchase,
      idempotencyKey: 'key',
      status: status,
      createdAt: DateTime.utc(2026, 9, 26),
      updatedAt: DateTime.utc(2026, 9, 26),
    );

    test('exposes the transaction key', () {
      expect(entry(OutboxStatus.granted).txnKey, '2000000712345678');
      expect(purchase.isRestored, isFalse);
    });

    test('is open until finished or rejected', () {
      expect(
        {for (final s in OutboxStatus.values) s: entry(s).isOpen},
        {
          OutboxStatus.awaitingVerification: true,
          OutboxStatus.granted: true,
          OutboxStatus.finished: false,
          OutboxStatus.rejected: false,
        },
      );
      expect(entry(OutboxStatus.granted).attempts, 0);
    });
  });

  group('JournalItem', () {
    test('sorts by the creation instant of either kind', () {
      final reading = completeReading();
      final card = dailyCard();
      expect(JournalItem.reading(reading).createdAt, reading.createdAt);
      expect(JournalItem.dailyCard(card).createdAt, card.createdAt);
    });

    test('query defaults list everything', () {
      const query = JournalQuery();
      expect(query.favouritesOnly, isFalse);
      expect(query.includeDailyCards, isTrue);
      expect(query.spreadId, isNull);
      expect(
        JournalSnapshot(readings: const [], dailyCards: [dailyCard()]),
        JournalSnapshot(readings: const [], dailyCards: [dailyCard()]),
      );
    });
  });

  group('AdRequestPolicy', () {
    test('needs the SDK when any format is enabled', () {
      for (final banners in [false, true]) {
        for (final rewarded in [false, true]) {
          expect(
            AdRequestPolicy(
              bannersEnabled: banners,
              rewardedEnabled: rewarded,
            ).needsSdk,
            banners || rewarded,
          );
        }
      }
    });
  });

  group('AnalyticsConsent', () {
    test('allDenied denies every signal', () {
      expect(
        AnalyticsConsent.allDenied(),
        const AnalyticsConsent(
          analyticsStorage: false,
          adStorage: false,
          adUserData: false,
          adPersonalization: false,
        ),
      );
    });

    test('allGranted grants every signal', () {
      expect(
        AnalyticsConsent.allGranted(),
        const AnalyticsConsent(
          analyticsStorage: true,
          adStorage: true,
          adUserData: true,
          adPersonalization: true,
        ),
      );
    });
  });

  group('wire enums', () {
    test('GrantStatus', () {
      expect(GrantStatus.values.map((s) => s.wire), [
        'granted',
        'already_granted',
        'pending',
      ]);
    });

    test('AttestationType', () {
      expect(AttestationType.values.map((t) => t.wire), [
        'app_attest',
        'play_integrity',
        'none',
      ]);
    });

    test('RewardIntentState names match the wire', () {
      expect(RewardIntentState.values.map((s) => s.name), [
        'issued',
        'granted',
        'cancelled',
        'expired',
        'rejected',
      ]);
    });
  });

  group('sealed unions expose a factory per case', () {
    test('IapEvent', () {
      final id = TaroProducts.readings10.id;
      const grant = CreditGrant(credits: 10, isFirstPurchase: true);
      final events = <IapEvent>[
        IapEvent.purchased(id, grant: grant),
        IapEvent.pending(id),
        const IapEvent.cancelled(),
        const IapEvent.failed(Failure.purchaseCancelled()),
        IapEvent.restored({TaroProducts.removeAds.id}),
        const IapEvent.entitlementChanged(Entitlement.unknown),
      ];
      expect(
        events.map((e) => e.runtimeType.toString()),
        [
          'IapPurchased',
          'IapPending',
          'IapCancelled',
          'IapFailed',
          'IapRestored',
          'IapEntitlementChanged',
        ],
      );
      expect((events.first as IapPurchased).grant?.credits, 10);
    });

    test('PurchaseOutcome', () {
      const outcomes = <PurchaseOutcome>[
        PurchaseOutcome.granted(credits: 3, isFirstPurchase: false),
        PurchaseOutcome.alreadyGranted(),
        PurchaseOutcome.pending(),
        PurchaseOutcome.cancelled(),
        PurchaseOutcome.failed(Failure.purchase(wireCode: 'PURCHASE_INVALID')),
        PurchaseOutcome.verificationDelayed(),
        PurchaseOutcome.notAvailable(),
        PurchaseOutcome.alreadyOwned(),
      ];
      expect(outcomes.toSet(), hasLength(8));
      expect(
        outcomes.first,
        const PurchaseOutcome.granted(credits: 3, isFirstPurchase: false),
      );
    });

    test('StoreBuyResult', () {
      final purchase = StorePurchase(
        txnKey: 'k',
        productId: TaroProducts.removeAds.id,
        platform: StorePlatform.android,
        purchaseToken: 'token',
        orderId: 'GPA.1',
        isRestored: true,
      );
      final results = <StoreBuyResult>[
        StoreBuyResult.purchased(purchase),
        const StoreBuyResult.pending(),
        const StoreBuyResult.cancelled(),
        const StoreBuyResult.alreadyOwned(),
      ];
      expect(results.toSet(), hasLength(4));
      expect((results.first as StoreBuyPurchased).purchase.isRestored, isTrue);
    });

    test('SyncStatus', () {
      final statuses = <SyncStatus>[
        const SyncStatus.syncing(),
        SyncStatus.synced(at: DateTime.utc(2026, 9, 26)),
        const SyncStatus.stale(),
        const SyncStatus.unavailable(failure: Failure.network()),
      ];
      expect(statuses.toSet(), hasLength(4));
      expect((statuses[2] as SyncStatusStale).lastSyncedAt, isNull);
    });
  });

  group('value types', () {
    test('GrantResult defaults for a pending response', () {
      const result = GrantResult(status: GrantStatus.pending);
      expect(result.creditsGranted, 0);
      expect(result.isFirstPurchase, isFalse);
      expect(result.balance, isNull);
    });

    test('RewardIntent and RewardStatus compare by value', () {
      final expires = DateTime.utc(2026, 9, 26, 9, 30);
      expect(
        RewardIntent(
          intentId: const IntentId('q8Zp'),
          amount: 1,
          expiresAt: expires,
        ),
        RewardIntent(
          intentId: const IntentId('q8Zp'),
          amount: 1,
          expiresAt: expires,
        ),
      );
      expect(
        const RewardStatus(state: RewardIntentState.issued, amount: 1),
        isNot(const RewardStatus(state: RewardIntentState.granted, amount: 1)),
      );
    });

    test('store, attestation and report values compare by value', () {
      expect(
        StoreProduct(
          id: TaroProducts.readings3.id,
          title: '3 readings',
          price: r'$2.99',
          rawPrice: 2.99,
          currencyCode: 'USD',
        ).currencyCode,
        'USD',
      );
      expect(
        const AttestationBlob(type: AttestationType.none, challenge: 'c'),
        const AttestationBlob(type: AttestationType.none, challenge: 'c'),
      );
      expect(const AssertionBlob(header: 'none').header, 'none');
      expect(const DeviceSignal(deviceKey: 'k').deviceCheckToken, isNull);
      expect(
        const ReadingReport(
          readingId: ReadingId('r'),
          reason: ReportReason.harmfulAdvice,
          locale: 'de',
          idempotencyKey: 'k',
        ).reason.wire,
        'harmful_advice',
      );
    });
  });

  group('in-core adapters', () {
    test('SystemClock returns UTC and local instants', () {
      const clock = SystemClock();
      expect(clock.now().isUtc, isTrue);
      expect(clock.nowLocal().isUtc, isFalse);
    });

    test('SecureRandomSource stays in range', () {
      final random = SecureRandomSource();
      for (var i = 0; i < 100; i++) {
        expect(random.nextInt(78), inInclusiveRange(0, 77));
        expect(random.nextBool(), isA<bool>());
      }
    });
  });
}
