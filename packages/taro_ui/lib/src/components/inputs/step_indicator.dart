import 'package:flutter/widgets.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// Onboarding progress dots (S02–S04), announced as one node with the
/// localised [semanticsLabel] ("Step 1 of 3").
///
/// The current step is a wider `color.accent.primary` pill, the others
/// `color.border.strong` dots, `space.2` apart; the order mirrors in RTL.
class StepIndicator extends StatelessWidget {
  /// Creates the indicator for [current] (1-based) of [total].
  const StepIndicator({
    required this.current,
    required this.total,
    required this.semanticsLabel,
    super.key,
  }) : assert(total > 0 && current >= 1 && current <= total, 'in range');

  /// The current step, 1-based.
  final int current;

  /// The number of steps.
  final int total;

  /// "Step [current] of [total]", localised.
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final dot = tokens.space.s3;
    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: tokens.space.s2,
        children: [
          for (var i = 1; i <= total; i++)
            Container(
              width: i == current ? dot * 3 : dot,
              height: dot,
              decoration: BoxDecoration(
                color: i == current ? c.accent.primary : c.border.strong,
                borderRadius: BorderRadius.circular(tokens.radius.full),
              ),
            ),
        ],
      ),
    );
  }
}
