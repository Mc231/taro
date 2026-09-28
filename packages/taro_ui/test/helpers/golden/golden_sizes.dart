import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden and widget-test surface sizes in logical pixels (06 §3, RC24).
///
/// Tests render at a device pixel ratio of 1.0, so a golden PNG is exactly
/// this many pixels wide and tall.

/// iPhone SE class phone, the default widget-test size.
const Size kPhoneSmall = Size(375, 667);

/// iPhone Pro Max class phone.
const Size kPhoneLarge = Size(430, 932);

/// iPad 13" in portrait (RC24).
const Size kTabletIpad13 = Size(1032, 1376);

/// Android 10" tablet in portrait (RC24).
const Size kTabletAndroid = Size(800, 1280);

/// Phone sizes that every golden covers.
const List<Size> kPhoneSizes = [kPhoneSmall, kPhoneLarge];

/// Tablet sizes that ★ (key screen) goldens also cover.
const List<Size> kTabletSizes = [kTabletIpad13, kTabletAndroid];

/// File-name slug of every known golden size.
final Map<Size, String> kGoldenSizeNames = Map.unmodifiable(<Size, String>{
  kPhoneSmall: 'phone_small',
  kPhoneLarge: 'phone_large',
  kTabletIpad13: 'tablet_ipad13',
  kTabletAndroid: 'tablet_android',
});

/// The slug of [size] used in golden file names, for example `phone_small`.
///
/// A size outside [kGoldenSizeNames] is named `<width>x<height>`.
String goldenSizeName(Size size) =>
    kGoldenSizeNames[size] ??
    '${size.width.toStringAsFixed(0)}x${size.height.toStringAsFixed(0)}';

/// Whether [size] is one of the tablet form factors.
bool isTabletSize(Size size) => size.shortestSide >= 600;

/// Sets the test view to [size] logical pixels at a device pixel ratio of
/// 1.0 and resets it when the test ends.
void applyTestViewSize(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
