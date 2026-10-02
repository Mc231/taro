import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/services/presentation/banner_slot_view.dart';
import 'package:taro_core/taro_core.dart' hide ThemeMode;
import 'package:taro_ui/taro_ui.dart';

import '../../../../packages/taro_ui/test/helpers/golden/golden_matrix.dart';
import '../helpers/pump_app.dart';

export '../../../../packages/taro_ui/test/helpers/golden/golden_matrix.dart';
export '../helpers/pump_app.dart';

/// The adaptive anchored banner height of the placeholder creative.
const double kGoldenBannerHeight = 50;

/// A loaded banner (`bannerLoaded`): the reserved box with its "Ad" label,
/// as the canvas draws it.
final class GoldenBannerSlotView implements BannerSlotView {
  /// Creates the view.
  const GoldenBannerSlotView();

  @override
  Widget build(BannerScreen screen, {required bool visible}) =>
      const BannerContainer(height: kGoldenBannerHeight, label: 'Ad');
}

/// Fakes where every `BannerPolicy` input allows the banner.
TaroFakes goldenFakes({FakeClock? clock}) => TaroFakes(
  clock: clock,
  consent: const ConsentState(
    onboardingStep: OnboardingStep.done,
    ai: AiConsent(decision: AiConsentDecision.granted, version: 2),
    ads: AdsConsent(canRequestAds: true),
  ),
)..banners = const GoldenBannerSlotView();

/// A [GoldenPump] over `pumpTaro` with the fakes from [fakes], which then
/// decodes every on-screen image (card art) so the golden shows it.
GoldenPump pumpAppGolden(
  TaroFakes Function() fakes, {
  List<Override> overrides = const [],
}) => (tester, child, variant) async {
  await pumpTaro(
    tester,
    child,
    fakes: fakes(),
    // The bundled D15 art (the fake deck names another set).
    overrides: [
      ...overrides,
      deckArtSetProvider.overrideWith((ref) async => CardArt.defaultArtSet),
    ],
    locale: variant.locale,
    theme: variant.themeMode,
    textScale: variant.textScale,
    size: variant.size,
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pump();
};
