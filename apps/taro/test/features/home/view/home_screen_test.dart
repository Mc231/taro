import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// A chip view the test can change (live-region announcements).
final class _ChipNotifier extends Notifier<BalanceChipView> {
  @override
  BalanceChipView build() => BalanceChipView(
    balance: aCreditBalance().build(),
    sync: BalanceChipSync.synced,
  );

  // A write-only test hook.
  // ignore: avoid_setters_without_getters
  set view(BalanceChipView value) => state = value;
}

final _chipProvider = NotifierProvider<_ChipNotifier, BalanceChipView>(
  _ChipNotifier.new,
);

final DateTime _evening = DateTime(2026, 9, 27, 20, 30);

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
        now: () => DateTime(2026, 9, 27, hour, 30),
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
    expect(find.text(l10n.homeCoachmarkTitle), findsOneWidget);
    expect(find.text(l10n.homeCoachmarkFreeBody), findsOneWidget);
    expect(find.byType(BannerSlot), findsNothing);
    await tapText(tester, l10n.homeCoachmarkDismiss);
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

  Future<List<String>> pumpWith(
    WidgetTester tester,
    HomeView view, {
    double textScale = 1,
    bool withUpdate = false,
    TaroFakes? fakes,
  }) async {
    final calls = <String>[];
    await pumpTaro(
      tester,
      HomeLayout(
        state: HomeState.content(view),
        now: () => _evening,
        onOpenStore: () => calls.add('store'),
        onOpenDaily: () => calls.add('daily'),
        onStartReading: () => calls.add('start'),
        onOpenReading: (r) => calls.add('reading:${r.id.value}'),
        onDismissFirstRun: () => calls.add('firstRun'),
        onDismissUpdate: () => calls.add('update'),
        onRetryVerification: () => calls.add('retry'),
        onUpdate: withUpdate ? () => calls.add('openStore') : null,
        onFreeReset: () => calls.add('reset'),
      ),
      fakes: fakes ?? aiReadyFakes(),
      textScale: textScale,
    );
    await tester.pumpAndSettle();
    return calls;
  }

  testWidgets('header: the localised date above the greeting', (
    tester,
  ) async {
    await pumpWith(tester, _view());
    expect(find.text('Sunday, September 27'), findsOneWidget);
    expect(find.text(l10n.homeGreetingEvening), findsOneWidget);
  });

  testWidgets('zero readings: the real countdown to free.resetsAt', (
    tester,
  ) async {
    final zero = aCreditBalance()
        .withFreeRemaining(0)
        .withResetsAt(_evening.add(const Duration(hours: 5, minutes: 12)))
        .build();
    final calls = await pumpWith(
      tester,
      _view(balance: zero, variant: HomeBalanceVariant.zeroReadings),
    );
    expect(
      find.text(l10n.balanceNextFreeIn(l10n.durationHoursMinutes(5, 12))),
      findsOneWidget,
    );
    expect(calls, isEmpty);
  });

  testWidgets('first launch offline: "Connect to start AI readings"', (
    tester,
  ) async {
    final view = _view(balanceStale: true).copyWith(
      balance: null,
      variant: HomeBalanceVariant.unknown,
    );
    await pumpWith(tester, view);
    expect(find.text(l10n.offlineFirstLaunchNote), findsOneWidget);
  });

  testWidgets('deviceUnverified: the notice replaces the chip', (
    tester,
  ) async {
    await pumpWith(tester, _view(deviceUnverified: true));
    expect(find.byType(BalanceChip), findsNothing);
    expect(find.text(l10n.balanceUnavailable), findsOneWidget);
  });

  testWidgets('updateAvailable: Update opens the store when wired', (
    tester,
  ) async {
    final calls = await pumpWith(
      tester,
      _view(updateAvailable: true),
      withUpdate: true,
    );
    await tapText(tester, l10n.homeUpdateAction);
    expect(calls, ['openStore']);
  });

  testWidgets('firstRun: the target stays tappable through the scrim, '
      'which follows a scroll', (tester) async {
    final calls = await pumpWith(
      tester,
      _view(firstRun: true, recent: [aReading().build()]),
    );
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(40);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TaroButton, l10n.homeStartReading));
    await tester.tapAt(const Offset(20, 20));
    expect(calls, ['start', 'firstRun']);
  });

  testWidgets('firstRun without a free reading: no free claim', (
    tester,
  ) async {
    await pumpWith(
      tester,
      _view(firstRun: true, variant: HomeBalanceVariant.zeroReadings),
    );
    expect(find.text(l10n.homeCoachmarkTitle), findsNothing);
    expect(find.text(l10n.homeCoachmark), findsOneWidget);
  });

  testWidgets('recent rows: positions and a relative day', (tester) async {
    final yesterday = aReading().withId('y').onLocalDate('2026-09-26').build();
    final today = aReading().withId('t').onLocalDate('2026-09-27').build();
    final older = aReading().withId('o').onLocalDate('2026-09-01').build();
    await pumpWith(tester, _view(recent: [yesterday, today, older]));
    expect(find.textContaining(l10n.relativeYesterday), findsOneWidget);
    expect(find.textContaining(l10n.relativeToday), findsOneWidget);
    expect(find.textContaining('Sep 1'), findsOneWidget);
    expect(
      find.textContaining(l10n.spread_three_ppf_pos_past_name),
      findsNWidgets(3),
    );
  });

  testWidgets('200% text: the tile stacks and the CTA stretches', (
    tester,
  ) async {
    await pumpWith(tester, _view(), textScale: 2);
    final tile = find.ancestor(
      of: find.byType(TaroCardBack),
      matching: find.byType(Column),
    );
    expect(tile, findsWidgets);
    await revealFound(
      tester,
      find.widgetWithText(TaroButton, l10n.homeStartReading),
    );
    final button = tester.widget<TaroButton>(
      find.widgetWithText(TaroButton, l10n.homeStartReading),
    );
    expect(button.expand, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a balance change is announced politely', (tester) async {
    await pumpTaro(
      tester,
      HomeLayout(
        state: HomeState.content(_view()),
        now: () => _evening,
        onOpenStore: () {},
        onOpenDaily: () {},
        onStartReading: () {},
        onOpenReading: (_) {},
        onDismissFirstRun: () {},
        onDismissUpdate: () {},
        onRetryVerification: () {},
      ),
      fakes: aiReadyFakes(),
      overrides: [
        balanceChipProvider.overrideWith((ref) => ref.watch(_chipProvider)),
      ],
    );
    await tester.pumpAndSettle();
    tester.takeAnnouncements();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeLayout)),
    );
    final credits = aCreditBalance().withFreeRemaining(0).withBonus(3).build();
    container.read(_chipProvider.notifier).view = BalanceChipView(
      balance: credits,
      sync: BalanceChipSync.synced,
    );
    await tester.pumpAndSettle();
    final label = BalanceChipView(
      balance: credits,
      sync: BalanceChipSync.synced,
    ).label(l10n);
    expect(
      tester.takeAnnouncements().map((a) => a.message),
      [l10n.balanceUpdated(label)],
    );
    // A syncing pass is not announced here (the chip's own live region).
    container.read(_chipProvider.notifier).view = BalanceChipView(
      balance: credits,
      sync: BalanceChipSync.syncing,
    );
    await tester.pumpAndSettle();
    expect(tester.takeAnnouncements(), isEmpty);
  });

  group('screen', () {
    Future<void> pumpHome(
      WidgetTester tester,
      TaroFakes fakes, {
      bool firstRun = false,
    }) {
      if (!firstRun) {
        fakes.secureStore.values[HomeNoticeKeys.firstRunDone] = '1';
      }
      return pumpFlow(
        tester,
        path: RoutePaths.home,
        builder: (_) => const HomeScreen(),
        fakes: fakes,
      );
    }

    testWidgets('Start a reading dismisses the coachmark and opens S06', (
      tester,
    ) async {
      final fakes = aiReadyFakes();
      await pumpHome(tester, fakes, firstRun: true);
      expect(find.text(l10n.homeCoachmarkFreeBody), findsOneWidget);
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
      await tapFound(tester, find.byType(JournalEntryTile));
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
      await pumpHome(tester, fakes, firstRun: true);
      await tapText(tester, l10n.homeCoachmarkDismiss);
      expect(find.text(l10n.homeCoachmarkFreeBody), findsNothing);
    });
  });
}
