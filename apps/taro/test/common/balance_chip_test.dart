import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/balance_chip.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../helpers/pump_app.dart';

final DateTime _now = DateTime.utc(2026, 9, 30, 8);

CreditBalance _balance({int free = 0, int bonus = 0, int paid = 0}) =>
    aCreditBalance()
        .withFreeRemaining(free)
        .withBonus(bonus)
        .withPaid(paid)
        .build();

BalanceChipView _view(
  CreditBalance? balance, {
  bool stale = false,
  SyncStatus? status,
}) => BalanceChipView.from(
  balance: balance,
  stale: stale,
  status: status ?? SyncStatus.synced(at: _now),
);

Future<TaroLocalizations> _en() =>
    TaroLocalizations.delegate.load(const Locale('en'));

Future<void> _pumpChip(
  WidgetTester tester,
  BalanceChipView view, {
  VoidCallback? onTap,
  bool today = false,
  TaroFakes? fakes,
}) => pumpTaro(
  tester,
  Center(
    child: BalanceChip(onTap: onTap, today: today),
  ),
  fakes: fakes,
  overrides: [balanceChipProvider.overrideWithValue(view)],
);

void main() {
  group('BalanceChipView.from (01 §7.1 sync states)', () {
    test('synced, syncing, stale and unavailable', () {
      final balance = _balance(free: 1);
      expect(_view(balance).sync, BalanceChipSync.synced);
      expect(
        _view(balance, status: const SyncStatus.syncing()).sync,
        BalanceChipSync.syncing,
      );
      expect(_view(balance, stale: true).sync, BalanceChipSync.stale);
      expect(
        _view(
          null,
          status: const SyncStatus.unavailable(failure: Failure.network()),
        ).sync,
        BalanceChipSync.unavailable,
      );
      expect(
        _view(
          balance,
          status: const SyncStatus.unavailable(
            failure: Failure.attestation(kind: AttestationFailureKind.rejected),
          ),
        ).sync,
        BalanceChipSync.unavailable,
      );
      // A cached balance with a network failure is only stale.
      expect(
        _view(
          balance,
          stale: true,
          status: const SyncStatus.unavailable(failure: Failure.network()),
        ).sync,
        BalanceChipSync.stale,
      );
    });

    test('pill state follows the buckets', () {
      expect(_view(_balance(free: 1)).pillState, BalancePillState.free);
      expect(
        _view(_balance(free: 1, paid: 3)).pillState,
        BalancePillState.credits,
      );
      expect(_view(_balance(bonus: 2)).pillState, BalancePillState.credits);
      expect(_view(_balance()).pillState, BalancePillState.zero);
      expect(_view(_balance(paid: -2)).pillState, BalancePillState.zero);
      expect(_view(null).pillState, BalancePillState.stale);
      expect(
        _view(_balance(free: 1), stale: true).pillState,
        BalancePillState.stale,
      );
      expect(
        _view(
          null,
          status: const SyncStatus.unavailable(failure: Failure.network()),
        ).pillState,
        BalancePillState.unverified,
      );
    });

    test('labels', () async {
      final l10n = await _en();
      expect(_view(_balance(free: 1)).label(l10n), '1 free reading');
      expect(
        _view(_balance(free: 1)).label(l10n, today: true),
        '1 free reading today',
      );
      expect(
        _view(_balance(free: 1, paid: 3)).label(l10n),
        '3 readings · 1 free today',
      );
      expect(
        _view(_balance(bonus: 1, paid: 2)).label(l10n),
        'Free reading used · 3 readings',
      );
      expect(_view(_balance()).label(l10n), 'Free reading used');
      expect(_view(null).label(l10n), 'Readings');
      expect(
        _view(
          null,
          status: const SyncStatus.unavailable(failure: Failure.network()),
        ).label(l10n),
        'Readings unavailable on this device',
      );
    });

    test('value equality', () {
      final balance = _balance(free: 1);
      expect(_view(balance), _view(balance));
      expect(_view(balance).hashCode, _view(balance).hashCode);
      expect(_view(balance), isNot(_view(balance, stale: true)));
    });
  });

  group('BalanceChip', () {
    testWidgets('free reading: taps open the options', (tester) async {
      var taps = 0;
      await _pumpChip(tester, _view(_balance(free: 1)), onTap: () => taps++);
      expect(find.text('1 free reading'), findsOneWidget);
      await tester.tap(find.byType(BalancePill));
      expect(taps, 1);
      final pill = tester.widget<BalancePill>(find.byType(BalancePill));
      expect(pill.semanticsHint, 'Shows reading options');
      expect(pill.announce, isFalse);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('S07 wording and no hint without onTap', (tester) async {
      await _pumpChip(tester, _view(_balance(free: 1)), today: true);
      expect(find.text('1 free reading today'), findsOneWidget);
      final pill = tester.widget<BalancePill>(find.byType(BalancePill));
      expect(pill.semanticsHint, isNull);
    });

    testWidgets('syncing announces the balance', (tester) async {
      await _pumpChip(
        tester,
        _view(_balance(free: 1), status: const SyncStatus.syncing()),
      );
      final pill = tester.widget<BalancePill>(find.byType(BalancePill));
      expect(pill.announce, isTrue);
    });

    testWidgets('stale shows the last known value offline', (tester) async {
      await _pumpChip(tester, _view(_balance(paid: 3), stale: true));
      expect(find.text('Free reading used · 3 readings'), findsOneWidget);
      final pill = tester.widget<BalancePill>(find.byType(BalancePill));
      expect(pill.state, BalancePillState.stale);
      expect(pill.semanticsHint, 'Last known balance, you’re offline');
    });

    testWidgets('unavailable: Retry runs a sync pass', (tester) async {
      final fakes = TaroFakes();
      var opened = 0;
      await _pumpChip(
        tester,
        _view(
          null,
          status: const SyncStatus.unavailable(failure: Failure.network()),
        ),
        onTap: () => opened++,
        fakes: fakes,
      );
      expect(find.text('Readings unavailable on this device'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      final syncsBefore = fakes.balance.calls.length;
      await tester.tap(find.byType(BalancePill));
      // Let the sync pass (and its entitlement refresh timeout) finish.
      await tester.pump(const Duration(seconds: 11));
      expect(opened, 0);
      expect(fakes.balance.calls.length, greaterThan(syncsBefore));
    });

    testWidgets('provider derives the view from the app state', (tester) async {
      final fakes = TaroFakes()
        ..balance = FakeBalanceRepository(
          cached: _balance(free: 1, paid: 3),
        );
      await pumpTaro(tester, const Center(child: BalanceChip()), fakes: fakes);
      await tester.pump();
      expect(find.textContaining('3 readings'), findsOneWidget);
    });
  });
}
