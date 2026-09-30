import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/common/taro_pressable.dart';
import 'package:taro_ui/src/motion/taro_motion.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// An expandable FAQ item (S28): the question row with a chevron, the
/// answer revealed below.
///
/// The header is a button exposing `Semantics(expanded:)`. It opens with a
/// `motion.duration.base` / `motion.easing.standard` size change; under
/// reduced motion there is no height animation (the answer appears at
/// once). Uncontrolled by default; pass [expanded] with
/// [onExpansionChanged] to control it.
class TaroAccordion extends StatefulWidget {
  /// Creates the item.
  const TaroAccordion({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.expanded,
    this.onExpansionChanged,
    super.key,
  });

  /// Creates an item whose answer is plain [body] text.
  factory TaroAccordion.text({
    required String title,
    required String body,
    bool initiallyExpanded = false,
    bool? expanded,
    ValueChanged<bool>? onExpansionChanged,
    Key? key,
  }) => TaroAccordion(
    title: title,
    initiallyExpanded: initiallyExpanded,
    expanded: expanded,
    onExpansionChanged: onExpansionChanged,
    key: key,
    child: _AccordionBody(body),
  );

  /// The localised question.
  final String title;

  /// The answer.
  final Widget child;

  /// The first state when uncontrolled.
  final bool initiallyExpanded;

  /// The state when controlled.
  final bool? expanded;

  /// Called with the requested state on tap.
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<TaroAccordion> createState() => _TaroAccordionState();
}

class _TaroAccordionState extends State<TaroAccordion> {
  late bool _open = widget.expanded ?? widget.initiallyExpanded;

  bool get _expanded => widget.expanded ?? _open;

  void _toggle() {
    final next = !_expanded;
    if (widget.expanded == null) setState(() => _open = next);
    widget.onExpansionChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final motion = context.motion;
    final reduced = context.reduceMotion;
    final expanded = _expanded;
    final header = Semantics(
      container: true,
      button: true,
      expanded: expanded,
      child: TaroPressable(
        onTap: _toggle,
        borderRadius: tokens.radius.md,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: tokens.size.touchTarget.min),
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: tokens.space.s5,
              vertical: tokens.space.s4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: tokens.typography.titleSmall.copyWith(
                      color: c.text.primary,
                    ),
                  ),
                ),
                SizedBox(width: tokens.space.s3),
                ExcludeSemantics(
                  child: AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: motion.duration.base,
                    curve: motion.easing.standard,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: tokens.size.icon.md,
                      color: c.text.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final answer = expanded
        ? Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              tokens.space.s5,
              0,
              tokens.space.s5,
              tokens.space.s5,
            ),
            child: widget.child,
          )
        : const SizedBox(width: double.infinity);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg.surface,
        borderRadius: BorderRadius.circular(tokens.radius.md),
        border: Border.all(
          color: c.border.subtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (reduced)
            answer
          else
            AnimatedSize(
              duration: motion.duration.base,
              curve: motion.easing.standard,
              alignment: AlignmentDirectional.topStart,
              child: answer,
            ),
        ],
      ),
    );
  }
}

class _AccordionBody extends StatelessWidget {
  const _AccordionBody(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Text(
      text,
      style: tokens.typography.body.copyWith(
        color: tokens.color.text.secondary,
      ),
    );
  }
}
