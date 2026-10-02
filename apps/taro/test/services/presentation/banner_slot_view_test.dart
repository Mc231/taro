import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
import 'package:taro/services/presentation/banner_slot_view.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/fakes/fakes.dart';
import '../ads/fake_ads_platform.dart';

const _unit = 'ca-app-pub-3940256099942544/6300978111';
const _adKey = Key('platform-ad');

void main() {
  late FakeAdsPlatform platform;
  late CapturingLogger logger;
  late Completer<void> ready;
  late bool npa;
  late FakeAnalyticsService analytics;

  setUp(() {
    platform = FakeAdsPlatform();
    logger = CapturingLogger();
    npa = false;
    analytics = FakeAnalyticsService();
  });
  tearDown(() => platform.uninstall());

  /// A widget test whose `ready` completer lives in the fake-async zone,
  /// so completing it is flushed by `pump`.
  void bannerTest(String name, WidgetTesterCallback body) =>
      testWidgets(name, (tester) async {
        ready = Completer<void>();
        await body(tester);
      });

  AdMobBannerSlotView view({AnchoredSizeLookup? size}) => AdMobBannerSlotView(
    adUnitId: _unit,
    ready: () => ready.future,
    nonPersonalizedAds: () => npa,
    logger: logger,
    analytics: analytics,
    anchoredSize: size ?? gma.AdSize.getLargeAnchoredAdaptiveBannerAdSize,
    adWidget: (_) => const SizedBox.expand(key: _adKey),
  );

  Future<void> pumpSlot(
    WidgetTester tester,
    BannerSlotView slot, {
    bool visible = true,
  }) => tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: AlignmentDirectional.bottomCenter,
        child: slot.build(BannerScreen.home, visible: visible),
      ),
    ),
  );

  Size slotSize(WidgetTester tester) =>
      tester.getSize(find.byType(AdMobBanner));

  bannerTest('NoOpBannerSlotView is always zero-sized', (tester) async {
    // Non-const: the constructor line must run (06 QA2 per-file floor).
    // ignore: prefer_const_constructors
    await pumpSlot(tester, NoOpBannerSlotView());
    expect(tester.getSize(find.byType(SizedBox)), Size.zero);
  });

  bannerTest('a hidden slot loads nothing', (tester) async {
    await pumpSlot(tester, view(), visible: false);
    ready.complete();
    await tester.pump();
    expect(find.byType(AdMobBanner), findsNothing);
    expect(platform.calls, isEmpty);
  });

  bannerTest('loads an anchored adaptive banner once the SDK is ready', (
    tester,
  ) async {
    await pumpSlot(tester, view());
    expect(slotSize(tester), Size.zero);
    await tester.pump();
    expect(platform.calls, isEmpty, reason: 'no request before init (RC19)');

    ready.complete();
    await tester.pump();
    await tester.pump();
    expect(
      platform.argsOf('AdSize#getLargeAnchoredAdaptiveBannerAdSize'),
      {'width': 800},
    );
    final load = platform.argsOf('loadBannerAd');
    expect(load['adUnitId'], _unit);
    expect((load['request']! as gma.AdRequest).nonPersonalizedAds, isNull);
    expect(slotSize(tester), const Size(800, 60));
    expect(find.byKey(_adKey), findsOneWidget);
    expect(
      analytics.events.whereType<AdBannerImpressionEvent>().single.screenId,
      BannerScreen.home,
    );

    await tester.pumpWidget(const SizedBox());
    expect(platform.methods.last, 'disposeAd');
  });

  bannerTest('non-personalised when ad personalisation is denied', (
    tester,
  ) async {
    npa = true;
    ready.complete();
    await pumpSlot(tester, view());
    await tester.pump();
    final request = platform.argsOf('loadBannerAd')['request']!;
    expect((request as gma.AdRequest).nonPersonalizedAds, isTrue);
  });

  bannerTest('no fill collapses to zero and disposes the ad', (tester) async {
    platform.loadMode = LoadMode.noFill;
    ready.complete();
    await pumpSlot(tester, view());
    await tester.pump();
    await tester.pump();
    expect(slotSize(tester), Size.zero);
    expect(platform.methods, contains('disposeAd'));
    expect(logger.logged('banner no fill: 3'), isTrue);
    final failed = analytics.events.whereType<AdBannerFailedEvent>().single;
    expect(failed.parameters, {'screen_id': 'home', 'error_code': 3});
  });

  bannerTest('a failing load collapses to zero', (tester) async {
    platform.loadMode = LoadMode.error;
    ready.complete();
    await pumpSlot(tester, view());
    await tester.pump();
    expect(slotSize(tester), Size.zero);
    expect(logger.logged('banner load failed'), isTrue);
    expect(
      analytics.events.whereType<AdBannerFailedEvent>().single.errorCode,
      isNull,
    );
  });

  bannerTest('no adaptive size → no request', (tester) async {
    platform.bannerHeight = null;
    ready.complete();
    await pumpSlot(tester, view());
    await tester.pump();
    expect(slotSize(tester), Size.zero);
    expect(platform.methods, isNot(contains('loadBannerAd')));
  });

  bannerTest('unmounted before the SDK is ready → never loads', (
    tester,
  ) async {
    await pumpSlot(tester, view());
    await tester.pumpWidget(const SizedBox());
    ready.complete();
    await tester.pump();
    expect(platform.calls, isEmpty);
  });

  bannerTest('unmounted while sizing → never loads', (tester) async {
    final size = Completer<gma.AdSize?>();
    ready.complete();
    await pumpSlot(tester, view(size: (_) => size.future));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    size.complete(gma.AdSize.banner);
    await tester.pump();
    expect(platform.calls, isEmpty);
  });

  bannerTest('unmounted while loading → the late result is ignored', (
    tester,
  ) async {
    platform.loadMode = LoadMode.hang;
    ready.complete();
    await pumpSlot(tester, view());
    await tester.pump();
    final id = platform.loadedIds.single;
    await tester.pumpWidget(const SizedBox());
    await platform.loaded(id);
    await tester.pump();
    expect(platform.methods, contains('disposeAd'));
  });

  test('the default platform view is the SDK AdWidget', () {
    final ad = gma.BannerAd(
      size: gma.AdSize.banner,
      adUnitId: _unit,
      listener: const gma.BannerAdListener(),
      request: const gma.AdRequest(),
    );
    expect(AdMobBannerSlotView.defaultAdWidget(ad), isA<gma.AdWidget>());
    final slot = AdMobBannerSlotView(
      adUnitId: _unit,
      ready: () async {},
      nonPersonalizedAds: () => false,
      logger: logger,
    );
    expect(slot.adWidget, AdMobBannerSlotView.defaultAdWidget);
    expect(
      slot.build(BannerScreen.journalList, visible: true),
      isA<AdMobBanner>(),
    );
  });
}
