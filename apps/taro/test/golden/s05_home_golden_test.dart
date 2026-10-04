@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/balance_chip.dart';
import 'package:taro/features/home/controller/home_controller.dart';
import 'package:taro/features/home/view/home_screen.dart';
import 'package:taro_core/taro_core.dart';

import 'golden_app_support.dart';

/// Sunday 27 September, evening (the canvas `Today` artboard).
final DateTime _now = DateTime(2026, 9, 27, 20, 30);

final Reading _recent = aReading()
    .withId('r-recent')
    .onLocalDate('2026-09-26')
    .build();

HomeLayout _layout(HomeView view) => HomeLayout(
  state: HomeState.content(view),
  now: () => _now,
  onOpenStore: () {},
  onOpenDaily: () {},
  onStartReading: () {},
  onOpenReading: (_) {},
  onDismissFirstRun: () {},
  onDismissUpdate: () {},
  onRetryVerification: () {},
);

HomeView _view(
  CreditBalance balance,
  HomeBalanceVariant variant, {
  bool firstRun = false,
  DailyCard? dailyCard,
}) => HomeView(
  balance: balance,
  variant: variant,
  firstRun: firstRun,
  balanceStale: false,
  deviceUnverified: false,
  adsRemoved: false,
  updateAvailable: false,
  dailyCard: dailyCard,
  recentReadings: firstRun ? const [] : [_recent],
);

TaroFakes Function() _fakes(CreditBalance balance, {bool withReading = true}) =>
    () {
      final fakes = goldenFakes(clock: FakeClock(_now))
        ..balance = FakeBalanceRepository(cached: balance);
      if (withReading) fakes.journal.putReading(_recent);
      return fakes;
    };

/// A synced chip for [balance] (the real chip reads the sync state).
GoldenPump _pump(CreditBalance balance, {bool withReading = true}) =>
    pumpAppGolden(
      _fakes(balance, withReading: withReading),
      overrides: [
        balanceChipProvider.overrideWithValue(
          BalanceChipView(balance: balance, sync: BalanceChipSync.synced),
        ),
      ],
    );

void main() {
  final free = aCreditBalance().withFreeRemaining(1).build();
  final credits = aCreditBalance().withFreeRemaining(0).withBonus(3).build();
  final zero = aCreditBalance()
      .withFreeRemaining(0)
      .withResetsAt(_now.add(const Duration(hours: 5, minutes: 12)))
      .build();

  goldenMatrix(
    's05_home_content_free',
    (_) => _layout(_view(free, HomeBalanceVariant.freeAvailable)),
    keyScreen: true,
    accessibility: true,
    largeText: true,
    pump: _pump(free),
  );

  goldenMatrix(
    's05_home_content_credits',
    (_) => _layout(
      _view(
        credits,
        HomeBalanceVariant.freeUsedWithCredits,
        dailyCard: aDailyCard().withCard('major_17').build(),
      ),
    ),
    keyScreen: true,
    accessibility: true,
    pump: _pump(credits),
  );

  goldenMatrix(
    's05_home_content_zero',
    (_) => _layout(_view(zero, HomeBalanceVariant.zeroReadings)),
    keyScreen: true,
    accessibility: true,
    pump: _pump(zero),
  );

  goldenMatrix(
    's05_home_first_run',
    (_) => _layout(
      _view(free, HomeBalanceVariant.freeAvailable, firstRun: true),
    ),
    // BUG-13: at 200 % the target is scrolled into view.
    largeText: true,
    pump: _pump(free, withReading: false),
  );
}
