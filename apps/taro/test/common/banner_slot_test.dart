import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/services/presentation/banner_slot_view.dart';
import 'package:taro_core/taro_core.dart';

import '../helpers/pump_app.dart';

const _adKey = Key('ad');
const _adHeight = 50.0;

/// A [BannerSlotView] whose ad is either loaded ([height] > 0) or not.
final class _FakeBannerView implements BannerSlotView {
  _FakeBannerView({this.height = _adHeight});

  final double height;
  final List<(BannerScreen, bool)> builds = [];

  @override
  Widget build(BannerScreen screen, {required bool visible}) {
    builds.add((screen, visible));
    return SizedBox(key: _adKey, width: 320, height: height);
  }
}

/// Fakes where every `BannerPolicy` input allows a banner.
TaroFakes _eligible({double adHeight = _adHeight}) {
  final fakes = TaroFakes(
    consent: const ConsentState(
      onboardingStep: OnboardingStep.done,
      ads: AdsConsent(canRequestAds: true),
    ),
  )..banners = _FakeBannerView(height: adHeight);
  fakes.journal.putReading(aReading().build());
  return fakes;
}

Future<void> _pumpSlot(WidgetTester tester, TaroFakes fakes) async {
  await pumpTaro(
    tester,
    const Column(
      children: [
        Expanded(child: SizedBox.expand()),
        BannerSlot(BannerScreen.home),
      ],
    ),
    fakes: fakes,
  );
  await tester.pump();
}

double _slotHeight(WidgetTester tester) =>
    tester.getSize(find.byType(BannerSlot)).height;

void main() {
  testWidgets('loaded: the ad in its band with space.adGap on both sides', (
    tester,
  ) async {
    final fakes = _eligible();
    await _pumpSlot(tester, fakes);
    expect(find.byKey(_adKey), findsOneWidget);
    expect(_slotHeight(tester), _adHeight + 2 * 16);
    final view = fakes.banners as _FakeBannerView;
    expect(view.builds.last, (BannerScreen.home, true));
    final frame = tester.getRect(find.byType(AdGapFrame));
    final ad = tester.getRect(find.byKey(_adKey));
    expect(ad.top - frame.top, 16);
    expect(frame.bottom - ad.bottom, 16);
    expect(find.bySemanticsLabel('Advertisement'), findsOneWidget);
  });

  testWidgets('failed or not loaded: slot and gaps collapse to zero', (
    tester,
  ) async {
    await _pumpSlot(tester, _eligible(adHeight: 0));
    expect(_slotHeight(tester), 0);
  });

  testWidgets('no banner before the first completed AI reading', (
    tester,
  ) async {
    final fakes = TaroFakes(
      consent: const ConsentState(
        onboardingStep: OnboardingStep.done,
        ads: AdsConsent(canRequestAds: true),
      ),
    )..banners = _FakeBannerView();
    // Classic readings never count (04 §8).
    fakes.journal.putReading(
      aReading().withStatus(const ReadingStatus.classic()).build(),
    );
    await _pumpSlot(tester, fakes);
    expect(find.byKey(_adKey), findsNothing);
    expect(_slotHeight(tester), 0);
  });

  testWidgets('Remove Banner Ads hides the slot', (tester) async {
    final fakes = _eligible()
      ..entitlements = FakeEntitlementCache(
        const Entitlement(
          removeAds: EntitlementState.owned,
          source: EntitlementSource.cache,
        ),
      );
    await _pumpSlot(tester, fakes);
    expect(find.byKey(_adKey), findsNothing);
  });

  testWidgets('UMP canRequestAds false hides the slot', (tester) async {
    final fakes = TaroFakes()..banners = _FakeBannerView();
    fakes.journal.putReading(aReading().build());
    await _pumpSlot(tester, fakes);
    expect(find.byKey(_adKey), findsNothing);
  });

  testWidgets('config ads.bannerEnabled false hides the slot', (tester) async {
    final fakes = _eligible()
      ..config = FakeRemoteConfigRepository(
        aRemoteConfig().withBannerEnabled(false).build(),
      );
    await _pumpSlot(tester, fakes);
    expect(find.byKey(_adKey), findsNothing);
  });

  group('completedAiReadingsProvider', () {
    test('counts complete readings only', () async {
      final fakes = TaroFakes();
      fakes.journal
        ..putReading(
          aReading().withId('00000000-0000-4000-8000-000000000001').build(),
        )
        ..putReading(
          aReading()
              .withId('00000000-0000-4000-8000-000000000002')
              .withStatus(const ReadingStatus.pending())
              .build(),
        )
        ..putReading(
          aReading()
              .withId('00000000-0000-4000-8000-000000000003')
              .withStatus(const ReadingStatus.classic())
              .build(),
        );
      final container = fakes.container()
        ..listen(completedAiReadingsProvider, (_, _) {});
      expect(await container.read(completedAiReadingsProvider.future), 1);
    });
  });

  group('RenderAdGapFrame', () {
    testWidgets('updates gap and colour and handles no child', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: AdGapFrame(gap: 8, color: Color(0xFF000000)),
          ),
        ),
      );
      final render = tester.renderObject<RenderAdGapFrame>(
        find.byType(AdGapFrame),
      );
      expect(render.size, Size.zero);
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: AdGapFrame(
              gap: 4,
              color: Color(0xFFFFFFFF),
              child: SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      );
      expect(render.gap, 4);
      expect(render.color, const Color(0xFFFFFFFF));
      // Unbounded width (inside a Row): the frame takes the child's width.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdGapFrame(
                gap: 4,
                color: Color(0xFFFFFFFF),
                child: SizedBox(width: 10, height: 10),
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(AdGapFrame)),
        const Size(10, 18),
      );
      // Same values: no relayout or repaint needed.
      final same =
          tester.renderObject<RenderAdGapFrame>(
              find.byType(AdGapFrame),
            )
            ..gap = 4
            ..color = const Color(0xFFFFFFFF);
      expect(same.debugNeedsLayout, isFalse);
      expect(same, isA<RenderShiftedBox>());
    });
  });
}
