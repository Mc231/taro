import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/icons/suit_glyph.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// One suit of a [PatternsChart].
@immutable
class PatternsChartEntry {
  /// Creates an entry.
  const PatternsChartEntry({
    required this.suit,
    required this.label,
    required this.count,
  }) : assert(count >= 0, 'count is never negative');

  /// The suit (glyph and `color.chart.suit.*`).
  final TaroSuit suit;

  /// Localised legend text with the count ("Major 9").
  final String label;

  /// Cards of this suit drawn.
  final int count;
}

/// Suit balance of the last 30 days (S14; `docs/design/components.md`
/// § PatternsChart): a stacked bar in `color.chart.suit.*` on a
/// `color.bg.sunken` track, and a legend where each suit has its glyph,
/// name and count, so colour is never the only signal.
///
/// The chart is one semantics node ([semanticsLabel], e.g. "Suit balance:
/// Major Arcana 9, Wands 4…"). In RTL the bar grows from the right. With no
/// cards drawn (or [emptyMessage] set and the total under the app's
/// threshold) the bar and legend give way to [emptyMessage].
class PatternsChart extends StatelessWidget {
  /// Creates the chart.
  const PatternsChart({
    required this.title,
    required this.entries,
    required this.semanticsLabel,
    this.trailing,
    this.highlight,
    this.caption,
    this.emptyMessage,
    this.showEmpty = false,
    super.key,
  });

  /// "Patterns · last 30 days".
  final String title;

  /// The suits in display order.
  final List<PatternsChartEntry> entries;

  /// The one-sentence summary for screen readers.
  final String semanticsLabel;

  /// "28 cards drawn".
  final String? trailing;

  /// "Most drawn: The Star, 5 times".
  final String? highlight;

  /// "Patterns in your draws, not predictions."
  final String? caption;

  /// The too-few-readings copy.
  final String? emptyMessage;

  /// Shows [emptyMessage] instead of the bar (too few readings).
  final bool showEmpty;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final total = entries.fold<int>(0, (sum, e) => sum + e.count);
    final empty = showEmpty || total == 0;
    final captionStyle = tokens.typography.caption.copyWith(
      color: c.text.secondary,
    );
    final header = Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: tokens.space.s4,
      children: [
        Text(
          title,
          style: tokens.typography.titleSmall.copyWith(color: c.text.primary),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: tokens.typography.body.copyWith(color: c.text.secondary),
          ),
      ],
    );
    final barHeight = tokens.space.s4;
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radius.full),
      child: ColoredBox(
        color: c.bg.sunken,
        child: SizedBox(
          height: barHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.space.s1,
            children: [
              for (final entry in entries)
                if (entry.count > 0)
                  Expanded(
                    flex: entry.count,
                    child: ColoredBox(color: entry.suit.chartColorIn(context)),
                  ),
            ],
          ),
        ),
      ),
    );
    final legend = Wrap(
      spacing: tokens.space.s5,
      runSpacing: tokens.space.s3,
      children: [
        for (final entry in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SuitGlyph(
                entry.suit,
                size: SuitGlyphSize.sm,
                color: entry.suit.chartColorIn(context),
              ),
              SizedBox(width: tokens.space.s2),
              Text(
                entry.label,
                style: tokens.typography.label.copyWith(
                  color: c.text.primary,
                ),
              ),
            ],
          ),
      ],
    );
    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsetsDirectional.all(tokens.space.s6),
        decoration: BoxDecoration(
          color: c.bg.surface,
          borderRadius: BorderRadius.circular(tokens.radius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            if (empty && emptyMessage != null) ...[
              SizedBox(height: tokens.space.s4),
              Text(
                emptyMessage!,
                style: tokens.typography.body.copyWith(
                  color: c.text.secondary,
                ),
              ),
            ] else if (!empty) ...[
              if (highlight != null) ...[
                SizedBox(height: tokens.space.s4),
                Text(
                  highlight!,
                  style: tokens.typography.body.copyWith(
                    color: c.text.primary,
                  ),
                ),
              ],
              SizedBox(height: tokens.space.s4),
              bar,
              SizedBox(height: tokens.space.s4),
              legend,
            ],
            if (caption != null) ...[
              SizedBox(height: tokens.space.s4),
              Text(caption!, style: captionStyle),
            ],
          ],
        ),
      ),
    );
  }
}
