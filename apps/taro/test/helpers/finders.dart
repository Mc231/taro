import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Finders for widgets that flutter_test only recognises by the Flutter SDK's
/// own Material classes, not by their `material_ui` counterparts.
extension TaroFinders on CommonFinders {
  /// Like [CommonFinders.byTooltip], but also finds a `material_ui` [Tooltip]
  /// that excludes itself from semantics (TaroIconButton puts the label on
  /// its own Semantics), which `byTooltip` only matches for the SDK class.
  /// Same rule as `byTooltip`: the [Tooltip] itself only when it gives its
  /// [RawTooltip] no semantics tooltip, otherwise that [RawTooltip].
  Finder byTaroTooltip(String message, {bool skipOffstage = true}) =>
      byWidgetPredicate(
        (widget) {
          if (widget is Tooltip && (widget.excludeFromSemantics ?? false)) {
            return widget.message == message;
          }
          return widget is RawTooltip && widget.semanticsTooltip == message;
        },
        description: 'tooltip "$message"',
        skipOffstage: skipOffstage,
      );
}
