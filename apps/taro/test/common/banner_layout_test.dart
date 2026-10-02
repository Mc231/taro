import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/features/home/controller/home_controller.dart';
import 'package:taro/routing/screen_builders.dart';
import 'package:taro/services/presentation/banner_slot_view.dart';
import 'package:taro_core/taro_core.dart';

import '../helpers/pump_app.dart';

const _adKey = Key('banner-ad');
const _adHeight = 50.0;

/// A loaded anchored banner of [_adHeight].
final class _LoadedBanner implements BannerSlotView {
  const _LoadedBanner();

  @override
  Widget build(BannerScreen screen, {required bool visible}) =>
      const SizedBox(key: _adKey, width: 320, height: _adHeight);
}

/// Fakes where every `BannerPolicy` input allows a banner (one completed AI
/// reading, UMP `canRequestAds`, no Remove Banner Ads).
TaroFakes _eligible({RemoteConfig? config, bool withReading = true}) {
  final fakes = TaroFakes(
    consent: const ConsentState(
      onboardingStep: OnboardingStep.done,
      ai: AiConsent(decision: AiConsentDecision.granted, version: 2),
      ads: AdsConsent(canRequestAds: true),
    ),
  )..banners = const _LoadedBanner();
  // Past the S05 first-run coachmark (no banner during first run).
  fakes.secureStore.values[HomeNoticeKeys.firstRunDone] = '1';
  if (config != null) fakes.config = FakeRemoteConfigRepository(config);
  if (withReading) fakes.journal.putReading(aReading().build());
  return fakes;
}

const Map<BannerScreen, ScreenId> _screens = {
  BannerScreen.home: ScreenId.s05,
  BannerScreen.journalList: ScreenId.s14,
  BannerScreen.learnLibrary: ScreenId.s16,
};

Future<void> _pumpScreen(
  WidgetTester tester,
  ScreenId id,
  TaroFakes fakes, {
  double textScale = 1,
}) async {
  await pumpTaro(
    tester,
    Builder(builder: (context) => buildScreen(context, id)),
    fakes: fakes,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}

/// The global rect of a semantics [node] (logical pixels).
Rect _globalRect(SemanticsNode node, double devicePixelRatio) {
  var rect = node.rect;
  for (SemanticsNode? n = node; n != null; n = n.parent) {
    final transform = n.transform;
    if (transform != null) rect = MatrixUtils.transformRect(transform, rect);
  }
  return Rect.fromLTRB(
    rect.left / devicePixelRatio,
    rect.top / devicePixelRatio,
    rect.right / devicePixelRatio,
    rect.bottom / devicePixelRatio,
  );
}

/// The tap targets outside scroll views (those inside are bounded by their
/// viewport, which is checked separately).
List<Rect> _fixedTapTargets(WidgetTester tester) {
  final root = tester
      .binding
      .renderViews
      .first
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!;
  final dpr = tester.view.devicePixelRatio;
  final targets = <Rect>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.hasAction(SemanticsAction.scrollUp) ||
        data.hasAction(SemanticsAction.scrollDown) ||
        data.flagsCollection.hasImplicitScrolling) {
      return;
    }
    if (data.hasAction(SemanticsAction.tap) && !node.isInvisible) {
      targets.add(_globalRect(node, dpr));
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return targets;
}

/// Asserts 04 §8 / RC59 for the banner on screen: the ad never intersects
/// a vertical scroll viewport, and every viewport and fixed tap target
/// keeps `space.adGap` (16 dp) from it.
void _expectBannerClear(WidgetTester tester) {
  final ad = tester.getRect(find.byKey(_adKey));
  final viewports = find.byWidgetPredicate(
    (w) =>
        w is Scrollable &&
        axisDirectionToAxis(w.axisDirection) == Axis.vertical,
  );
  expect(viewports, findsWidgets);
  for (final element in viewports.evaluate()) {
    final box = element.renderObject! as RenderBox;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    expect(rect.overlaps(ad), isFalse, reason: 'viewport $rect ∩ ad $ad');
    expect(ad.top - rect.bottom, greaterThanOrEqualTo(16));
  }
  for (final target in _fixedTapTargets(tester)) {
    final clear = target.bottom <= ad.top - 16 || target.top >= ad.bottom + 16;
    expect(clear, isTrue, reason: 'tap target $target is within 16 dp of $ad');
  }
}

void main() {
  for (final MapEntry(key: banner, value: id) in _screens.entries) {
    for (final scale in const [1.0, 2.0]) {
      testWidgets('${banner.id} at kPhoneSmall, text ×$scale: banner ∩ '
          'scroll viewport = ∅, ≥ 16 dp from every tap target', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _pumpScreen(tester, id, _eligible(), textScale: scale);
        expect(find.byType(BannerSlot), findsOneWidget);
        expect(find.byKey(_adKey), findsOneWidget);
        _expectBannerClear(tester);
        // Scrolled to the end, the content still stops above the banner.
        await tester.drag(
          find
              .byWidgetPredicate(
                (w) =>
                    w is Scrollable &&
                    axisDirectionToAxis(w.axisDirection) == Axis.vertical,
              )
              .first,
          const Offset(0, -2000),
        );
        await tester.pumpAndSettle();
        _expectBannerClear(tester);
        expect(tester.takeException(), isNull);
        handle.dispose();
      });
    }
  }

  group('ads.bannerMinCompletedReadings (04 §8)', () {
    testWidgets('a first-session user sees no banner until the first AI '
        'reading completes', (tester) async {
      final fakes = _eligible(withReading: false);
      await _pumpScreen(tester, ScreenId.s05, fakes);
      expect(find.byKey(_adKey), findsNothing);
      // A Classic reading does not count.
      fakes.journal.putReading(
        aReading()
            .withId('00000000-0000-4000-8000-00000000000c')
            .withStatus(const ReadingStatus.classic())
            .build(),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_adKey), findsNothing);
      // The first completed AI reading turns the banner on.
      fakes.journal.putReading(
        aReading().withId('00000000-0000-4000-8000-00000000000a').build(),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_adKey), findsOneWidget);
    });

    testWidgets('the threshold comes from config', (tester) async {
      final fakes = _eligible(
        config: RemoteConfig.defaults.copyWith(
          adsBannerMinCompletedReadings: 2,
        ),
      );
      await _pumpScreen(tester, ScreenId.s05, fakes);
      expect(find.byKey(_adKey), findsNothing);
      fakes.journal.putReading(
        aReading().withId('00000000-0000-4000-8000-00000000000b').build(),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_adKey), findsOneWidget);
    });
  });
}
