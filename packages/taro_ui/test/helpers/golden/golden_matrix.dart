import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pump_taro_ui_widget.dart';
import 'golden_sizes.dart';

/// The two base locales of every golden: English (LTR) and Arabic (RTL).
const List<Locale> kGoldenBaseLocales = [Locale('en'), Locale('ar')];

/// The enlarged text scale covered for key screens (06 §3, CLAUDE rule 16).
const double kGoldenLargeTextScale = 2;

/// One rendering of a golden: size, theme, locale and text scale.
@immutable
class GoldenVariant {
  /// Creates a variant.
  const GoldenVariant({
    required this.size,
    required this.themeMode,
    required this.locale,
    this.textScale = 1,
  });

  /// Logical surface size (see `golden_sizes.dart`).
  final Size size;

  /// [ThemeMode.light] or [ThemeMode.dark].
  final ThemeMode themeMode;

  /// The locale the widget is rendered in.
  final Locale locale;

  /// Text scale factor (1.0 or [kGoldenLargeTextScale]).
  final double textScale;

  /// Text direction implied by [locale].
  TextDirection get textDirection => textDirectionOf(locale);

  /// Whether [size] is a tablet form factor.
  bool get isTablet => isTabletSize(size);

  /// File-name slug, e.g. `phone_small_dark_ar` or `phone_large_light_en_x2`.
  String get name => [
    goldenSizeName(size),
    themeMode.name,
    locale.toLanguageTag(),
    if (textScale != 1) 'x${_trim(textScale)}',
  ].join('_');

  static String _trim(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  @override
  bool operator ==(Object other) =>
      other is GoldenVariant &&
      other.size == size &&
      other.themeMode == themeMode &&
      other.locale == locale &&
      other.textScale == textScale;

  @override
  int get hashCode => Object.hash(size, themeMode, locale, textScale);

  @override
  String toString() => 'GoldenVariant($name)';
}

/// The variants of one golden (06 §3, RC24).
///
/// * Every golden: each of [phoneSizes] × {light, dark} × {en, ar}.
/// * [extraLocales] (for example `ja`, `de` for text-heavy screens): light,
///   on each phone size.
/// * [largeText]: en light at [kGoldenLargeTextScale], on each phone size.
/// * [keyScreen] (★ states): each of [tabletSizes] in en light and ar dark.
List<GoldenVariant> goldenVariants({
  bool keyScreen = false,
  List<Locale> extraLocales = const [],
  bool largeText = false,
  List<Size> phoneSizes = kPhoneSizes,
  List<Size> tabletSizes = kTabletSizes,
}) {
  const en = Locale('en');
  const ar = Locale('ar');
  return [
    for (final size in phoneSizes) ...[
      for (final mode in const [ThemeMode.light, ThemeMode.dark])
        for (final locale in kGoldenBaseLocales)
          GoldenVariant(size: size, themeMode: mode, locale: locale),
      for (final locale in extraLocales)
        GoldenVariant(size: size, themeMode: ThemeMode.light, locale: locale),
      if (largeText)
        GoldenVariant(
          size: size,
          themeMode: ThemeMode.light,
          locale: en,
          textScale: kGoldenLargeTextScale,
        ),
    ],
    if (keyScreen)
      for (final size in tabletSizes) ...[
        GoldenVariant(size: size, themeMode: ThemeMode.light, locale: en),
        GoldenVariant(size: size, themeMode: ThemeMode.dark, locale: ar),
      ],
  ];
}

/// Pumps [child] for [variant]: sets the view size, theme, locale and text
/// scale. `taro_ui` uses [pumpTaroUiGolden]; the app passes an adapter over
/// `pumpTaroWidget` so its screens get `TaroLocalizations`.
typedef GoldenPump =
    Future<void> Function(
      WidgetTester tester,
      Widget child,
      GoldenVariant variant,
    );

/// [GoldenPump] over [pumpTaroUiWidget], for `taro_ui` components.
Future<void> pumpTaroUiGolden(
  WidgetTester tester,
  Widget child,
  GoldenVariant variant,
) => pumpTaroUiWidget(
  tester,
  child,
  locale: variant.locale,
  themeMode: variant.themeMode,
  textScale: variant.textScale,
  size: variant.size,
);

/// Relative path of a golden file: `goldens/<name>/<variant>.png` next to the
/// test file (06 §3).
String goldenPath(String name, GoldenVariant variant) =>
    'goldens/$name/${variant.name}.png';

/// Registers one `golden`-tagged widget test per variant of [name]
/// (see [goldenVariants]); each compares against [goldenPath].
///
/// [builder] receives the variant so a golden can pick locale-specific
/// sample data. Animations are settled with `pumpAndSettle`.
void goldenMatrix(
  String name,
  Widget Function(GoldenVariant variant) builder, {
  bool keyScreen = false,
  List<Locale> extraLocales = const [],
  bool largeText = false,
  List<Size> phoneSizes = kPhoneSizes,
  List<Size> tabletSizes = kTabletSizes,
  GoldenPump pump = pumpTaroUiGolden,
}) {
  final variants = goldenVariants(
    keyScreen: keyScreen,
    extraLocales: extraLocales,
    largeText: largeText,
    phoneSizes: phoneSizes,
    tabletSizes: tabletSizes,
  );
  group(name, () {
    for (final variant in variants) {
      testWidgets(variant.name, (tester) async {
        await pump(tester, builder(variant), variant);
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(WidgetsApp),
          matchesGoldenFile(goldenPath(name, variant)),
        );
      }, tags: const ['golden']);
    }
  });
}
