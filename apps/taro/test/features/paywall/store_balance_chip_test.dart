import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/balance_chip.dart';
import 'package:taro/features/paywall/view/store_screen.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../helpers/pump_app.dart';

/// "Free reading used · 1 reading": the longest everyday chip sentence.
final CreditBalance _freeUsedOnePaid = aCreditBalance()
    .withFreeRemaining(0)
    .withPaid(1)
    .build();

Future<void> _pumpStore(WidgetTester tester, Locale locale) async {
  await pumpTaro(
    tester,
    const StoreScreen(source: StoreSource.settings),
    locale: locale,
    size: const Size(360, 780),
    overrides: [
      balanceChipProvider.overrideWithValue(
        BalanceChipView(
          balance: _freeUsedOnePaid,
          sync: BalanceChipSync.synced,
        ),
      ),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  // BUG-19: in ja the chip wrapped onto two lines next to the close.
  testWidgets('S11: a chip that does not fit the bar moves under it (ja)', (
    tester,
  ) async {
    await _pumpStore(tester, const Locale('ja'));
    final close = tester.getRect(find.byType(TaroIconButton).first);
    final chip = tester.getRect(find.byType(BalancePill));
    expect(chip.top, greaterThanOrEqualTo(close.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('S11: a chip that fits stays in the bar beside the close (en)', (
    tester,
  ) async {
    await _pumpStore(tester, const Locale('en'));
    final close = tester.getRect(find.byType(TaroIconButton).first);
    final chip = tester.getRect(find.byType(BalancePill));
    expect(chip.center.dy, moreOrLessEquals(close.center.dy, epsilon: 1));
  });
}
