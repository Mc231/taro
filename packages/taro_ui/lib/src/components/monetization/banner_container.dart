import 'package:flutter/material.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// The box a banner ad lives in (`BannerSlot` in the app fills it; 04 §8,
/// RC59): full width, fixed [height], `color.ad.container`, square corners,
/// and a `space.adGap` (≥ 16 dp) margin above and below so no tap target
/// sits next to the ad.
///
/// [child] is the ad view; without it the container is the reserved
/// (loading) state. [collapsed] (failed, ads removed, not eligible) removes
/// the box and its margins. [label] is an optional localised "Ad" marker
/// for the reserved state; a loaded AdMob creative carries its own label,
/// which is never overridden.
class BannerContainer extends StatelessWidget {
  /// Creates the container.
  const BannerContainer({
    required this.height,
    this.child,
    this.label,
    this.collapsed = false,
    super.key,
  });

  /// The ad height in logical pixels (the loaded `AdSize` height).
  final double height;

  /// The ad view.
  final Widget? child;

  /// Localised "Ad" marker shown while reserved.
  final String? label;

  /// Removes the container.
  final bool collapsed;

  /// The separation between the banner and any tap target: `space.adGap`,
  /// never under 16 dp (04 §8).
  static double separationOf(BuildContext context) =>
      context.tokens.space.adGap;

  @override
  Widget build(BuildContext context) {
    if (collapsed) return const SizedBox.shrink();
    final tokens = context.tokens;
    final gap = separationOf(context);
    final marker = label;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: gap),
      child: Semantics(
        container: true,
        child: ColoredBox(
          color: tokens.color.ad.container,
          child: SizedBox(
            width: double.infinity,
            height: height,
            child:
                child ??
                (marker == null
                    ? null
                    : Align(
                        alignment: AlignmentDirectional.topStart,
                        child: Padding(
                          padding: EdgeInsetsDirectional.symmetric(
                            horizontal: tokens.space.s4,
                            vertical: tokens.space.s2,
                          ),
                          child: Text(
                            marker,
                            style: tokens.typography.caption.copyWith(
                              color: tokens.color.text.tertiary,
                            ),
                          ),
                        ),
                      )),
          ),
        ),
      ),
    );
  }
}
