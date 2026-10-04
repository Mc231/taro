import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/actions/taro_button.dart';
import 'package:taro_ui/src/components/common/taro_reflow.dart';
import 'package:taro_ui/src/components/state/skeleton_block.dart';
import 'package:taro_ui/src/components/state/taro_shimmer.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';
import 'package:taro_ui/src/tokens/taro_strokes.dart';

/// The index of the offer with the lowest per-reading price, or null when
/// there are fewer than two offers or the lowest price is shared (the
/// honest "Best value" badge, 04 §11). Prices are in one currency's minor
/// units or as store-reported decimals; only their order matters.
int? bestValueOfferIndex(List<num> perReadingPrices) {
  if (perReadingPrices.length < 2) return null;
  var best = 0;
  var tie = false;
  for (var i = 1; i < perReadingPrices.length; i++) {
    final price = perReadingPrices[i];
    if (price < perReadingPrices[best]) {
      best = i;
      tie = false;
    } else if (price == perReadingPrices[best]) {
      tie = true;
    }
  }
  return tie ? null : best;
}

/// The state of a [ProductOfferTile] (01 §8.3 S11 names).
enum ProductOfferState {
  /// Buyable.
  content,

  /// This offer's purchase is running (its button spins; other tiles stay
  /// enabled).
  purchasing,

  /// Waiting for approval (Ask to Buy / pending payment): [ProductOfferTile.
  /// statusLabel] replaces the button.
  pending,

  /// Already owned (Remove Banner Ads): [ProductOfferTile.statusLabel]
  /// replaces the button.
  owned,
}

/// One purchasable pack or Remove Banner Ads (design system **PackRow**,
/// 04 §11): title, optional body, per-reading price, a computed "Best
/// value" badge and the full localised store price as its own buy button.
///
/// The best-value row gets a `color.accent.primary` outline next to its
/// badge. No pre-selection, strikethrough or timer. The buy button's
/// [purchaseSemanticsLabel] is the full sentence ("10 readings for 4.99 US
/// dollars, 50 cents per reading"). A hidden offer (`purchasesBlocked`,
/// `store.enabled = false`) is simply not built.
class ProductOfferTile extends StatelessWidget {
  /// Creates the tile.
  const ProductOfferTile({
    required this.title,
    required this.price,
    required this.purchaseSemanticsLabel,
    required this.onBuy,
    this.body,
    this.perReadingPrice,
    this.bestValueLabel,
    this.state = ProductOfferState.content,
    this.statusLabel,
    this.purchasingSemanticsHint,
    this.outlined = false,
    super.key,
  }) : _loading = false,
       loadingSemanticsLabel = null;

  /// The loading skeleton of a tile.
  const ProductOfferTile.loading({this.loadingSemanticsLabel, super.key})
    : _loading = true,
      title = '',
      price = '',
      purchaseSemanticsLabel = '',
      onBuy = null,
      body = null,
      perReadingPrice = null,
      bestValueLabel = null,
      state = ProductOfferState.content,
      statusLabel = null,
      purchasingSemanticsHint = null,
      outlined = false;

  final bool _loading;

  /// "10 readings".
  final String title;

  /// The localised store price ("$4.99"), the buy button's label.
  final String price;

  /// The buy button's full semantics sentence.
  final String purchaseSemanticsLabel;

  /// Starts the purchase; null disables the button.
  final VoidCallback? onBuy;

  /// Optional body (Remove Banner Ads explanation).
  final String? body;

  /// "$0.50 per reading".
  final String? perReadingPrice;

  /// "Best value": shown when set (see [bestValueOfferIndex]).
  final String? bestValueLabel;

  /// The tile state.
  final ProductOfferState state;

  /// "Waiting for approval" / "Banner ads removed ✓".
  final String? statusLabel;

  /// Screen-reader hint while purchasing ("Purchasing").
  final String? purchasingSemanticsHint;

  /// Uses the secondary (outlined) buy button (Remove Banner Ads, S11).
  final bool outlined;

  /// Label of the loading skeleton.
  final String? loadingSemanticsLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final Widget content;
    if (_loading) {
      content = Semantics(
        label: loadingSemanticsLabel,
        child: TaroShimmer(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(width: tokens.size.card.lg / 2),
                    SizedBox(height: tokens.space.s3),
                    SkeletonBlock(width: tokens.size.card.md),
                  ],
                ),
              ),
              SkeletonBlock(
                shape: SkeletonShape.rect,
                width: tokens.size.card.md,
              ),
            ],
          ),
        ),
      );
    } else {
      final status = statusLabel;
      final Widget trailing;
      var button = false;
      if ((state == ProductOfferState.pending ||
              state == ProductOfferState.owned) &&
          status != null) {
        trailing = Semantics(
          liveRegion: true,
          child: Text(
            status,
            textAlign: TextAlign.end,
            style: tokens.typography.label.copyWith(
              color: state == ProductOfferState.owned
                  ? c.status.success
                  : c.text.secondary,
            ),
          ),
        );
      } else {
        final buy = TaroButton(
          label: price,
          variant: outlined
              ? TaroButtonVariant.secondary
              : TaroButtonVariant.primary,
          expand: false,
          loading: state == ProductOfferState.purchasing,
          semanticsLabel: purchaseSemanticsLabel,
          loadingSemanticsHint: purchasingSemanticsHint,
          onPressed: onBuy,
        );
        trailing = buy;
        button = true;
      }
      final text = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bestValueLabel != null) ...[
            _BestValueBadge(label: bestValueLabel!),
            SizedBox(height: tokens.space.s2),
          ],
          Text(
            title,
            style: tokens.typography.titleSmall.copyWith(
              color: c.text.primary,
            ),
          ),
          if (perReadingPrice != null)
            Text(
              perReadingPrice!,
              style: tokens.typography.caption.copyWith(
                color: c.text.tertiary,
              ),
            ),
          if (body != null)
            Text(
              body!,
              style: tokens.typography.body.copyWith(
                color: c.text.secondary,
              ),
            ),
        ],
      );
      // At large text the price goes under the text instead of squeezing
      // it into a narrow column (V2-04).
      content = taroShouldReflow(context)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.space.s4,
              children: [
                text,
                trailing,
              ],
            )
          : Row(
              children: [
                Expanded(child: text),
                SizedBox(width: tokens.space.s4),
                if (button) trailing else Flexible(child: trailing),
              ],
            );
    }
    return Container(
      padding: EdgeInsetsDirectional.all(tokens.space.s5),
      decoration: BoxDecoration(
        color: c.bg.surface,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        boxShadow: tokens.elevation.e1.shadow,
        // The honest badge's row is outlined (S11 `Store.dc.html`); the
        // outline is a highlight, never a pre-selection.
        border: bestValueLabel == null || _loading
            ? null
            : Border.all(
                color: c.accent.primary,
                width: TaroStrokes.control,
              ),
      ),
      child: content,
    );
  }
}

class _BestValueBadge extends StatelessWidget {
  const _BestValueBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.color.accent.subtle,
        borderRadius: BorderRadius.circular(tokens.radius.xs),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: tokens.space.s3,
          vertical: tokens.space.s1,
        ),
        child: Text(
          label,
          style: tokens.typography.caption.copyWith(
            color: tokens.color.text.primary,
          ),
        ),
      ),
    );
  }
}
