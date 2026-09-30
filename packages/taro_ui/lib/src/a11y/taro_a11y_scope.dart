import 'package:flutter/widgets.dart';

/// The in-app accessibility settings `taro_ui` needs (the app maps
/// `UserSettings.reduceMotion` and `UserSettings.hapticsEnabled` into it;
/// `taro_ui` cannot depend on `taro_core`, RC95).
class TaroA11yScope extends InheritedWidget {
  /// Provides the settings to [child].
  const TaroA11yScope({
    required super.child,
    this.reduceMotion = false,
    this.hapticsEnabled = true,
    super.key,
  });

  /// Settings → Reduce motion (01 §14.4). The system setting
  /// (`MediaQuery.disableAnimations`) applies on top of it.
  final bool reduceMotion;

  /// Settings → Haptics (01 §12).
  final bool hapticsEnabled;

  /// The nearest scope, or null.
  static TaroA11yScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TaroA11yScope>();

  @override
  bool updateShouldNotify(TaroA11yScope oldWidget) =>
      reduceMotion != oldWidget.reduceMotion ||
      hapticsEnabled != oldWidget.hapticsEnabled;
}
