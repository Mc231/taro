import 'package:flutter/widgets.dart';

/// The ambient card-back art below this widget (02 §14.3).
///
/// `taro_ui` never reads the app's assets: the app places one
/// [TaroCardBackArt] above its routes with the bundled back image, and every
/// `TaroCardBack` without its own `art` (including the backs inside
/// `CardFan`) draws it. Without a scope, or with a null [image], backs paint
/// the design-system ornament.
class TaroCardBackArt extends InheritedWidget {
  /// Provides [image] as the card back of [child].
  const TaroCardBackArt({required this.image, required super.child, super.key});

  /// The back art (full size; `TaroCardBack` adds the decode width).
  final ImageProvider? image;

  /// The nearest [image], or null without a scope.
  static ImageProvider? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TaroCardBackArt>()?.image;

  @override
  bool updateShouldNotify(TaroCardBackArt oldWidget) =>
      image != oldWidget.image;
}
