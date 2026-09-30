import 'package:flutter/material.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// The two reading sources an [AiGeneratedLabel] names.
enum ReadingSourceVariant {
  /// An AI reading: "AI-generated" (05 §3 `aiLabel`).
  ai,

  /// A Classic reading: "Classic reading" + a one-line explanation (S32).
  classic,
}

/// The reading-source label in the reading header (S09, S15, S32).
///
/// * [AiGeneratedLabel.new]: the compact "AI-generated" pill
///   (`color.accent.subtle`, `radius.xs`, `type.caption`).
/// * [AiGeneratedLabel.classic]: "Classic reading" with a book glyph and the
///   [explanation] line ("Built from the meaning of each card in its
///   position. No AI, free and works offline.").
///
/// Read as one node, in reading order; the glyph is decorative.
class AiGeneratedLabel extends StatelessWidget {
  /// The AI variant.
  const AiGeneratedLabel({required this.label, super.key})
    : variant = ReadingSourceVariant.ai,
      explanation = null;

  /// The Classic variant.
  const AiGeneratedLabel.classic({
    required this.label,
    required String this.explanation,
    super.key,
  }) : variant = ReadingSourceVariant.classic;

  /// Localised label ("AI-generated", "Classic reading").
  final String label;

  /// Localised explanation of the Classic variant.
  final String? explanation;

  /// The variant.
  final ReadingSourceVariant variant;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    if (variant == ReadingSourceVariant.ai) {
      return Container(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: tokens.space.s3,
          vertical: tokens.space.s1,
        ),
        decoration: BoxDecoration(
          color: c.accent.subtle,
          borderRadius: BorderRadius.circular(tokens.radius.xs),
        ),
        child: Text(
          label,
          style: tokens.typography.label.copyWith(color: c.text.primary),
        ),
      );
    }
    return MergeSemantics(
      child: Container(
        padding: EdgeInsetsDirectional.all(tokens.space.s4),
        decoration: BoxDecoration(
          color: c.bg.surface,
          borderRadius: BorderRadius.circular(tokens.radius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.menu_book_rounded,
                size: tokens.size.icon.md,
                color: c.card.frame,
              ),
            ),
            SizedBox(width: tokens.space.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: tokens.typography.label.copyWith(
                      color: c.text.primary,
                    ),
                  ),
                  SizedBox(height: tokens.space.s1),
                  Text(
                    explanation!,
                    style: tokens.typography.caption.copyWith(
                      color: c.text.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
