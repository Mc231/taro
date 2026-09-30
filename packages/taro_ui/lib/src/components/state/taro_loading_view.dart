import 'package:flutter/widgets.dart';
import 'package:taro_ui/src/components/state/skeleton_block.dart';
import 'package:taro_ui/src/components/state/taro_shimmer.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// Ready-made skeleton layouts for [TaroLoadingView].
enum TaroLoadingLayout {
  /// Rows with a leading circle and two lines (S14 Journal, S11 store).
  list,

  /// A title and a paragraph (S09/S32 reading, S24/S25 backup).
  text,

  /// A row of cards over a few lines (S05 Today, S08, S16 Learn).
  cards,
}

/// The loading state of a screen (01 §8.2): a skeleton made of
/// [SkeletonBlock]s, never an infinite spinner. One semantics node carries
/// [semanticsLabel] (e.g. "Loading your journal") as a live region.
class TaroLoadingView extends StatelessWidget {
  /// A loading view with one of the ready-made [layout]s, or a custom
  /// [skeleton] built from [SkeletonBlock]s.
  const TaroLoadingView({
    required this.semanticsLabel,
    this.layout = TaroLoadingLayout.list,
    this.skeleton,
    this.itemCount = 4,
    super.key,
  });

  /// Localised label read by screen readers.
  final String semanticsLabel;

  /// The ready-made layout, used when [skeleton] is null.
  final TaroLoadingLayout layout;

  /// A custom skeleton.
  final Widget? skeleton;

  /// Rows (list), lines (text) or cards (cards) in the ready-made layout.
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final gap = SizedBox(height: tokens.space.s5);
    final content =
        skeleton ??
        switch (layout) {
          TaroLoadingLayout.list => Column(
            children: [
              for (var i = 0; i < itemCount; i++) ...[
                if (i > 0) gap,
                _row(tokens),
              ],
            ],
          ),
          TaroLoadingLayout.text => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FractionallySizedBox(
                widthFactor: 0.6,
                child: SkeletonBlock(height: tokens.space.s8),
              ),
              gap,
              for (var i = 0; i < itemCount; i++) ...[
                if (i > 0) SizedBox(height: tokens.space.s3),
                FractionallySizedBox(
                  widthFactor: i == itemCount - 1 ? 0.7 : 1,
                  child: const SkeletonBlock(),
                ),
              ],
            ],
          ),
          TaroLoadingLayout.cards => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: tokens.space.s5,
                runSpacing: tokens.space.s5,
                children: [
                  for (var i = 0; i < itemCount; i++)
                    const SkeletonBlock(shape: SkeletonShape.card),
                ],
              ),
              SizedBox(height: tokens.space.s7),
              const FractionallySizedBox(
                widthFactor: 0.8,
                child: SkeletonBlock(),
              ),
              SizedBox(height: tokens.space.s3),
              const FractionallySizedBox(
                widthFactor: 0.5,
                child: SkeletonBlock(),
              ),
            ],
          ),
        };
    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: TaroShimmer(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: tokens.layout.gutter,
              vertical: tokens.space.s5,
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _row(TaroTokens tokens) => Row(
    children: [
      const SkeletonBlock(shape: SkeletonShape.circle),
      SizedBox(width: tokens.space.s4),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FractionallySizedBox(
              widthFactor: 0.7,
              child: SkeletonBlock(),
            ),
            SizedBox(height: tokens.space.s3),
            const FractionallySizedBox(
              widthFactor: 0.4,
              child: SkeletonBlock(),
            ),
          ],
        ),
      ),
    ],
  );
}
