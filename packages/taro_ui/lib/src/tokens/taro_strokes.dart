/// Stroke widths from the component specs (`docs/design/components.md`).
/// The token file has no stroke group, so these named constants are the
/// single source for borders and the focus ring (CLAUDE.md rule 15).
abstract final class TaroStrokes {
  /// Hairline dividers and decorative outlines (`color.border.subtle`).
  static const double hairline = 1;

  /// Control outlines: secondary buttons, inputs (`color.border.strong`).
  static const double control = 1.5;

  /// The focus ring (`color.border.focus`).
  static const double focusRing = 2;

  /// Gap between a control and its focus ring, so the ring sits on the
  /// background (REVIEW.md K8 note).
  static const double focusGap = 2;
}
