import 'package:flutter/widgets.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// The shared centred, scrollable layout of `TaroEmptyView` and
/// `TaroErrorView`: gutter padding, capped at `layout.maxContentWidth`,
/// scrolls instead of clipping at 200 % text (01 §12).
class TaroStateLayout extends StatelessWidget {
  /// Lays out [children] centred.
  const TaroStateLayout({required this.children, super.key});

  /// Top to bottom: visual, title, body, actions.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: tokens.layout.gutter,
          vertical: tokens.space.s7,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.hasBoundedHeight
                ? (constraints.maxHeight - 2 * tokens.space.s7).clamp(
                    0,
                    double.infinity,
                  )
                : 0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: tokens.layout.maxContentWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
