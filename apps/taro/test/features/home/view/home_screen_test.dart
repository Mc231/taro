import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/balance_chip.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/features/home/controller/home_controller.dart';
import 'package:taro/features/home/view/home_screen.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

import '../../flow_view_support.dart';

HomeView _view({
  CreditBalance? balance,
  HomeBalanceVariant variant = HomeBalanceVariant.freeAvailable,
  bool firstRun = false,
  bool balanceStale = false,
  bool deviceUnverified = false,
  bool adsRemoved = false,
  bool updateAvailable = false,
  DailyCard? dailyCard,
  List<Reading> recent = const [],
}) => HomeView(
  balance: balance ?? aCreditBalance().build(),
  variant: variant,
  firstRun: firstRun,
  balanceStale: balanceStale,
  deviceUnverified: deviceUnverified,
  adsRemoved: adsRemoved,
  updateAvailable: updateAvailable,
  dailyCard: dailyCard,
  recentReadings: recent,
);

void main() {
  late TaroLocalizations l10n;

  setUpAll(() async => l10n = await enL10n());

  Future<List<String>> pumpLayout(
    WidgetTester tester,
    HomeState state, {
    int hour = 9,
    TaroFakes? fakes,
  }) async {
    final calls = <String>[];
    await pumpTaro(
      tester,
      HomeLayout(
        state: state,
        hour: hour,
        onOpenStore: () => calls.add('store'),
        onOpenDaily: () => calls.add('daily'),
        onStartReading: () => calls.add('start'),
        onOpenReading: (r) => calls.add('reading:${r.id.value}'),
        onDismissFirstRun: () => calls.add('firstRun'),
        onDismissUpdate: () => calls.add('update'),
        onRetryVerification: () => calls.add('retry'),
      ),
      fakes: fakes ?? aiReadyFakes(),
    );
    await tester.pumpAndSettle();
    return calls;
  }

  testWidgets('loading: skeleton', (tester) async {
    await pumpLayout(tester, const HomeState.loading());
    expect(find.byType(TaroLoadingView), findsOneWidget);
  });

  testWidgets('content: greeting, chip, daily tile not drawn, start a '
      'reading, the home banner slot', (tester) async {
    final calls = await pumpLayout(tester, HomeState.content(_view()));
    expect(find.text(l10n.homeGreetingMorning), findsOneWidget);
    expect(find.byType(BalanceChip), findsOneWidget);
    expect(find.text(l10n.homeDailyTitleNotDrawn), findsOneWidget);
    expect(find.byType(TaroCardFace), findsNothing);
    expect(find.byType(BannerSlot), findsOneWidget);
    expect(find.byType(TaroCoachmark), findsNothing);
    await tapText(tester, l10n.homeStartReading);
    await tapText(tester, l10n.homeDailyTitleNotDrawn);
    expect(calls, ['start', 'daily']);
  });

  testWidgets('greetings by hour', (tester) async {
    await pumpLayout(tester, HomeState.content(_view()), hour: 14);
    expect(find.text(l10n.homeGreetingAfternoon), findsOneWidget);
    await pumpLayout(tester, HomeState.content(_view()), hour: 20);
    expect(find.text(l10n.homeGreetingEvening), findsOneWidget);
  });

  testWidgets('content variants: free used + credits and zero readings', (
    tester,
  ) async {
    final withCredits = aCreditBalance().withFreeRemaining(0).withBonus(2);
    await pumpLayout(
      tester,
      HomeState.content(
        _view(
          balance: withCredits.build(),
          variant: HomeBalanceVariant.freeUsedWithCredits,
        ),
      ),
      fakes: aiReadyFakes()
        ..balance = FakeBalanceRepository(cached: withCredits.build()),
    );
    expect(find.textContaining(l10n.balanceReadings(2)), findsOneWidget);

    final zero = aCreditBalance().withFreeRemaining(0).build();
    await pumpLayout(
      tester,
      HomeState.content(
        _view(balance: zero, variant: HomeBalanceVariant.zeroReadings),
      ),
      fakes: aiReadyFakes()..balance = FakeBalanceRepository(cached: zero),
    );
    expect(find.text(l10n.balanceFreeUsed), findsOneWidget);
  });

  testWidgets('firstRun: the coachmark, dismissible', (tester) async {
    final calls = await pumpLayout(
      tester,
      HomeState.content(_view(firstRun: true)),
    );
    expect(find.text(l10n.homeCoachmark), findsOneWidget);
    await tapText(tester, l10n.commonDismiss);
    expect(calls, ['firstRun']);
  });

  testWidgets('balanceStale: the offline banner over the content', (
    tester,
  ) async {
    final fakes = aiReadyFakes()
      ..connectivity = FakeConnectivityMonitor(online: false);
    await pumpLayout(
      tester,
      HomeState.content(_view(balanceStale: true)),
      fakes: fakes,
    );
    expect(find.text(l10n.offlineBanner), findsOneWidget);
  });

  testWidgets('deviceUnverified: notice with Retry', (tester) async {
    final calls = await pumpLayout(
      tester,
      HomeState.content(_view(deviceUnverified: true)),
    );
    expect(find.text(l10n.errorDeviceUnverifiedBody), findsOneWidget);
    await tapText(tester, l10n.commonRetry);
    expect(calls, contains('retry'));
  });

  testWidgets('dailyCardDrawn: the face and its name', (tester) async {
    final card = aDailyCard().withCard('major_17').build();
    final calls = await pumpLayout(
      tester,
      HomeState.content(_view(dailyCard: card)),
    );
    expect(find.byType(TaroCardFace), findsOneWidget);
    expect(find.text(l10n.homeDailyOpen), findsOneWidget);
    await tapText(tester, l10n.homeDailyOpen);
    expect(calls, ['daily']);
  });

  testWidgets('adsRemoved: no banner slot', (tester) async {
    await pumpLayout(tester, HomeState.content(_view(adsRemoved: true)));
    expect(find.byType(BannerSlot), findsNothing);
  });

  testWidgets('updateAvailable: dismissible notice', (tester) async {
    final calls = await pumpLayout(
      tester,
      HomeState.content(_view(updateAvailable: true)),
    );
    expect(find.text(l10n.homeUpdateAvailable), findsOneWidget);
    await tester.tap(find.byTooltip(l10n.commonDismiss));
    expect(calls, ['update']);
  });

  testWidgets('recent readings open S09 / S32', (tester) async {
    final reading = aReading().withId('r-1').build();
    final calls = await pumpLayout(
      tester,
      HomeState.content(_view(recent: [reading])),
    );
    expect(find.text(l10n.homeRecent), findsOneWidget);
    await tapFound(tester, find.text(reading.content!.title));
    expect(calls, ['reading:r-1']);
  });

  group('screen', () {
    Future<void> pumpHome(WidgetTester tester, TaroFakes fakes) => pumpFlow(
      tester,
      path: RoutePaths.home,
      builder: (_) => const HomeScreen(),
      fakes: fakes,
    );

    testWidgets('Start a reading dismisses the coachmark and opens S06', (
      tester,
    ) async {
      final fakes = aiReadyFakes();
      await pumpHome(tester, fakes);
      expect(find.text(l10n.homeCoachmark), findsOneWidget);
      await tapFound(
        tester,
        find.widgetWithText(TaroButton, l10n.homeStartReading),
      );
      expectRoute(RoutePaths.readingSpreads);
      expect(fakes.secureStore.values[HomeNoticeKeys.firstRunDone], '1');
    });

    testWidgets('the daily tile opens S13; the chip opens S11', (
      tester,
    ) async {
      await pumpHome(tester, aiReadyFakes());
      await tapText(tester, l10n.homeDailyTitleNotDrawn);
      expectRoute(RoutePaths.daily);
    });

    testWidgets('the chip opens the store', (tester) async {
      await pumpHome(tester, aiReadyFakes());
      await tester.tap(find.byType(BalanceChip));
      await tester.pumpAndSettle();
      expectRoute(RoutePaths.store);
    });

    testWidgets('a recent classic reading opens S32', (tester) async {
      final fakes = aiReadyFakes();
      final reading = aReading().withId('c-1').classic().build();
      fakes.journal.putReading(reading);
      await pumpHome(tester, fakes);
      await tapFound(tester, find.text(l10n.spread_three_ppf_name));
      expectRoute(RoutePaths.reading('c-1', classic: true));
    });

    testWidgets('an unregistered install retries verification', (
      tester,
    ) async {
      final fakes = aiReadyFakes()
        ..install = FakeInstallRepository(
          identity: anInstallIdentity(registered: false),
        );
      await pumpHome(tester, fakes);
      await tapFound(
        tester,
        find.widgetWithText(TaroButton, l10n.commonRetry).last,
      );
      expect(fakes.balance.syncReasons, contains(SyncReason.manual));
      // Let the sync coordinator's timers run out.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(minutes: 5));
    });

    testWidgets('coachmark dismissal and the retry are wired', (
      tester,
    ) async {
      final fakes = aiReadyFakes();
      await pumpHome(tester, fakes);
      await tapText(tester, l10n.commonDismiss);
      expect(find.text(l10n.homeCoachmark), findsNothing);
    });
  });
}
