import 'package:flutter/widgets.dart';
import 'package:taro_ui/src/components/state/taro_state_layout.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// An empty or full-screen blocking state (01 §8.2): illustration, title,
/// body and action (S14 `empty`, search empty, S30 update required, S12
/// `granted`). Strings arrive localised.
class TaroEmptyView extends StatelessWidget {
  /// Creates the view.
  const TaroEmptyView({
    required this.title,
    this.body,
    this.illustration,
    this.action,
    this.secondaryAction,
    this.largeTitle = true,
    super.key,
  });

  /// The headline (a semantics header).
  final String title;

  /// Supporting text.
  final String? body;

  /// An illustration (`docs/design/assets/empty/*`) or icon; decorative.
  final Widget? illustration;

  /// The main action, usually a primary `TaroButton`.
  final Widget? action;

  /// A second action, usually a secondary or tertiary `TaroButton`.
  final Widget? secondaryAction;

  /// `type.headline` when true (full-screen states), else `type.title`.
  final bool largeTitle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    return TaroStateLayout(
      children: [
        if (illustration != null) ...[
          ExcludeSemantics(child: Center(child: illustration)),
          SizedBox(height: tokens.space.s7),
        ],
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style:
                (largeTitle
                        ? tokens.typography.headline
                        : tokens.typography.title)
                    .copyWith(color: c.text.primary),
          ),
        ),
        if (body != null) ...[
          SizedBox(height: tokens.space.s3),
          Text(
            body!,
            textAlign: TextAlign.center,
            style: tokens.typography.body.copyWith(color: c.text.secondary),
          ),
        ],
        if (action != null) ...[SizedBox(height: tokens.space.s7), action!],
        if (secondaryAction != null) ...[
          SizedBox(height: tokens.space.s3),
          secondaryAction!,
        ],
      ],
    );
  }
}
