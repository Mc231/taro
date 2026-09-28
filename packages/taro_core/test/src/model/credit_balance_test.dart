import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'model_fixtures.dart';

void main() {
  group('CreditBalance.fromDto', () {
    test('maps the 03 §5.1 example', () {
      final b = balance();
      expect(b.free.limit, 1);
      expect(b.free.remaining, 1);
      expect(b.free.localDate, '2026-09-26');
      expect(b.free.resetsAt, DateTime.utc(2026, 9, 26, 22));
      expect(b.free.timezone, 'Europe/Berlin');
      expect(b.free.paused, isFalse);
      expect(b.bonus, 2);
      expect(b.paid, 5);
      expect(b.canRead, isTrue);
      expect(b.canReadReason, isNull);
      expect(b.nextSource, ChargeSource.free);
      expect(b.rewarded.dailyCap, 3);
      expect(b.rewarded.cooldownEndsAt, isNull);
      expect(b.purchasesAllowed, isTrue);
      expect(b.purchasesBlockedReason, isNull);
      expect(b.ledgerVersion, 412);
      expect(b.serverTime, DateTime.utc(2026, 9, 26, 9, 12, 44));
      expect(b.syncedAt, syncedAt);
    });

    test('maps blocked, paused and debt states', () {
      final dto = balanceDto(paid: -2)
        ..['canRead'] = false
        ..['canReadReason'] = 'readingsPaused'
        ..['nextSource'] = 'none'
        ..['paidBlocked'] = true
        ..['purchasesAllowed'] = false
        ..['purchasesBlockedReason'] = 'refundDebt';
      (dto['free']! as Map<String, Object?>).remove('paused');
      (dto['rewarded']! as Map<String, Object?>)['cooldownEndsAt'] =
          '2026-09-26T09:17:44Z';
      final b = CreditBalance.fromDto(dto, syncedAt: syncedAt);
      expect(b.canReadReason, CanReadReason.readingsPaused);
      expect(b.nextSource, isNull);
      expect(b.paidBlocked, isTrue);
      expect(b.purchasesBlockedReason, PurchasesBlockedReason.refundDebt);
      expect(b.free.paused, isFalse);
      expect(b.rewarded.cooldownEndsAt, DateTime.utc(2026, 9, 26, 9, 17, 44));
    });

    test('accepts integral doubles', () {
      final dto = balanceDto()..['bonus'] = 2.0;
      expect(CreditBalance.fromDto(dto, syncedAt: syncedAt).bonus, 2);
    });

    final bad = <String, void Function(Map<String, Object?>)>{
      'missing bonus': (d) => d.remove('bonus'),
      'fractional paid': (d) => d['paid'] = 1.5,
      'string canRead': (d) => d['canRead'] = 'yes',
      'unknown canReadReason': (d) => d['canReadReason'] = 'tired',
      'unknown nextSource': (d) => d['nextSource'] = 'gift',
      'bad serverTime': (d) => d['serverTime'] = 'noon',
      'free not an object': (d) => d['free'] = 3,
      'bad localDate': (d) =>
          (d['free']! as Map<String, Object?>)['localDate'] = '26/09/2026',
      'paused not bool': (d) =>
          (d['free']! as Map<String, Object?>)['paused'] = 'no',
    };
    for (final MapEntry(key: name, value: mutate) in bad.entries) {
      test('rejects $name', () {
        final dto = balanceDto();
        mutate(dto);
        expect(
          () => CreditBalance.fromDto(dto, syncedAt: syncedAt),
          throwsFormatException,
        );
      });
    }

    test('toDto round trips', () {
      final b = balance();
      expect(b.toDto(), balanceDto());
      expect(CreditBalance.fromDto(b.toDto(), syncedAt: syncedAt), b);
      final cooling = b.copyWith(
        rewarded: b.rewarded.copyWith(
          cooldownEndsAt: DateTime.utc(2026, 9, 26, 10),
        ),
        canReadReason: CanReadReason.dailyLimit,
        purchasesBlockedReason: PurchasesBlockedReason.storeDisabled,
      );
      expect(
        CreditBalance.fromDto(cooling.toDto(), syncedAt: syncedAt),
        cooling,
      );
    });
  });

  group('display', () {
    test('total and displayPaid', () {
      expect(balance().displayPaid, 5);
      expect(balance().total, 1 + 2 + 5);
      final debt = balance(paid: -3);
      expect(debt.displayPaid, 0);
      expect(debt.total, 1 + 2);
    });
  });

  group('isStaleAt', () {
    const staleAfter = Duration(seconds: 300);
    final b = balance();

    test('fresh within staleAfter and before the reset', () {
      expect(b.isStaleAt(syncedAt.add(staleAfter), staleAfter), isFalse);
    });

    test('stale after staleAfter', () {
      expect(
        b.isStaleAt(
          syncedAt.add(staleAfter + const Duration(seconds: 1)),
          staleAfter,
        ),
        isTrue,
      );
    });

    test('stale at and after free.resetsAt', () {
      const long = Duration(days: 1);
      expect(b.isStaleAt(b.free.resetsAt, long), isTrue);
      expect(
        b.isStaleAt(b.free.resetsAt.subtract(const Duration(seconds: 1)), long),
        isFalse,
      );
    });
  });

  group('RC67 replacement rule', () {
    final cached = balance();
    final table = <String, (CreditBalance, bool, bool)>{
      'greater version': (balance(ledgerVersion: 413), true, true),
      'equal version, newer serverTime': (
        balance(serverTime: '2026-09-26T09:12:45Z'),
        true,
        true,
      ),
      'equal version, same serverTime': (balance(), false, true),
      'equal version, older serverTime': (
        balance(serverTime: '2026-09-26T09:12:43Z'),
        false,
        true,
      ),
      'older version, newer serverTime': (
        balance(ledgerVersion: 411, serverTime: '2026-09-27T00:00:00Z'),
        false,
        false,
      ),
    };
    for (final MapEntry(key: name, value: row) in table.entries) {
      test(name, () {
        expect(row.$1.shouldReplace(cached), row.$2);
        expect(row.$1.isAcceptableOver(cached), row.$3);
      });
    }
  });

  test('value equality and copyWith of parts', () {
    expect(balance(), balance());
    expect(balance().copyWith(bonus: 9), isNot(balance()));
    expect(balance().free.copyWith(used: 1).used, 1);
    expect(balance().rewarded.copyWith(available: false).available, isFalse);
  });

  test('failures carry the balance (02 §3)', () {
    final b = balance();
    final f = Failure.insufficientCredits(
      reason: InsufficientReason.noCredits,
      balance: b,
    );
    expect((f as InsufficientCreditsFailure).balance, b);
    final expired = Failure.readingExpiredRefunded(balance: b);
    expect((expired as ReadingExpiredRefundedFailure).balance, b);
  });
}
