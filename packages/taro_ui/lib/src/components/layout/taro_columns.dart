import 'package:flutter/material.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// The narrowest width that holds two panes side by side: the Material
/// `medium` window size class boundary (02 §14.1), so every pane is at
/// least as wide as a phone column. Narrower widths stack the panes.
const double kTaroTwoPaneMinWidth = 600;

/// Whether a content column [width] wide splits into two panes (RC99).
bool taroTwoPanes(double width) => width >= kTaroTwoPaneMinWidth;

/// Two panes of a wide browse screen (RC99): side by side, [start] first
/// in reading order, separated by `space.5`, when the available width
/// reaches [kTaroTwoPaneMinWidth]; otherwise stacked with [spacing]
/// between them (the phone layout). Directional: [start] sits on the
/// right in RTL.
class TaroColumns extends StatelessWidget {
  /// Creates the panes.
  const TaroColumns({
    required this.start,
    required this.end,
    this.startFlex = 1,
    this.endFlex = 1,
    this.spacing,
    super.key,
  });

  /// The first pane (left in LTR, right in RTL; on top when stacked).
  final Widget start;

  /// The second pane.
  final Widget end;

  /// The share of the width [start] takes when split.
  final int startFlex;

  /// The share of the width [end] takes when split.
  final int endFlex;

  /// The gap between the stacked panes (default `space.5`).
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!taroTwoPanes(constraints.maxWidth)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: spacing ?? tokens.space.s5,
            children: [start, end],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.space.s5,
          children: [
            Expanded(flex: startFlex, child: start),
            Expanded(flex: endFlex, child: end),
          ],
        );
      },
    );
  }
}
