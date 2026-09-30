import 'package:flutter/material.dart';
import 'package:taro_ui/src/components/common/taro_pressable.dart';
import 'package:taro_ui/src/components/common/taro_reflow.dart';
import 'package:taro_ui/src/components/layout/taro_badge.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// The kinds of journal entry a [JournalEntryTile] shows.
enum JournalEntryTileStatus {
  /// A completed AI reading.
  ai,

  /// A Classic reading (status badge "Classic").
  classic,

  /// A daily card.
  dailyCard,

  /// A reading waiting to be finished (warning meta + "Finish reading").
  pending,

  /// A reading that failed (error meta).
  failed,
}

/// One journal row (S14 list, S05 "Recent"): leading card thumb(s), title
/// (question or card name), meta line (spread · date), a status badge
/// (Classic), note and favourite indicators, and the inline "Finish
/// reading" action for pending entries.
///
/// The row is one button node whose label is the title, meta, status and
/// the indicator labels; the Finish action is a separate button. Colour is
/// never the only signal: pending and failed rows carry their [statusLabel]
/// in text. Titles wrap to two lines and never clip at large text.
class JournalEntryTile extends StatelessWidget {
  /// Creates the row.
  const JournalEntryTile({
    required this.title,
    required this.meta,
    required this.status,
    required this.onTap,
    this.statusLabel,
    this.leading,
    this.hasNote = false,
    this.noteLabel,
    this.favourite = false,
    this.favouriteLabel,
    this.finishLabel,
    this.onFinish,
    super.key,
  }) : assert(!hasNote || noteLabel != null, 'a note needs its label'),
       assert(!favourite || favouriteLabel != null, 'favourite needs a label');

  /// Localised title (question or card name).
  final String title;

  /// Localised meta line ("Past · Present · Future · Sat 26 Sep").
  final String meta;

  /// The entry kind.
  final JournalEntryTileStatus status;

  /// Localised status word: the badge for [JournalEntryTileStatus.classic],
  /// the meta prefix for pending and failed ("Pending", "Couldn't finish").
  final String? statusLabel;

  /// Leading thumbs (`TaroCardFace`/`TaroCardBack` at `size.card.thumb`).
  final Widget? leading;

  /// Whether the entry has a note.
  final bool hasNote;

  /// Localised "Has a note".
  final String? noteLabel;

  /// Whether the entry is a favourite.
  final bool favourite;

  /// Localised "Favourite".
  final String? favouriteLabel;

  /// Localised "Finish reading" for pending entries.
  final String? finishLabel;

  /// Called by the Finish action.
  final VoidCallback? onFinish;

  /// Opens the entry.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    final metaColor = switch (status) {
      JournalEntryTileStatus.pending => c.status.warning,
      JournalEntryTileStatus.failed => c.status.error,
      _ => c.text.tertiary,
    };
    final prefixed =
        (status == JournalEntryTileStatus.pending ||
                status == JournalEntryTileStatus.failed) &&
            statusLabel != null
        ? '$statusLabel · $meta'
        : meta;
    final indicators = <Widget>[
      if (status == JournalEntryTileStatus.classic && statusLabel != null)
        TaroBadge(label: statusLabel!),
      if (hasNote)
        Semantics(
          label: noteLabel,
          child: ExcludeSemantics(
            child: Icon(
              Icons.sticky_note_2_outlined,
              size: tokens.size.icon.sm,
              color: c.text.secondary,
            ),
          ),
        ),
      if (favourite)
        Semantics(
          label: favouriteLabel,
          child: ExcludeSemantics(
            child: Icon(
              Icons.star_rounded,
              size: tokens.size.icon.md,
              color: c.card.frame,
            ),
          ),
        ),
    ];
    final main = MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: TaroPressable(
          onTap: onTap,
          borderRadius: tokens.radius.lg,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: tokens.size.touchTarget.min,
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.all(tokens.space.s4),
              child: Row(
                children: [
                  if (leading != null) ...[
                    ExcludeSemantics(child: leading),
                    SizedBox(width: tokens.space.s4),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tokens.typography.titleSmall.copyWith(
                            color: c.text.primary,
                          ),
                        ),
                        SizedBox(height: tokens.space.s1),
                        Text(
                          prefixed,
                          style: tokens.typography.caption.copyWith(
                            color: metaColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (indicators.isNotEmpty) ...[
                    SizedBox(width: tokens.space.s3),
                    Wrap(
                      spacing: tokens.space.s2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: indicators,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final finish =
        status == JournalEntryTileStatus.pending &&
            onFinish != null &&
            finishLabel != null
        ? Padding(
            padding: EdgeInsetsDirectional.only(end: tokens.space.s4),
            child: Semantics(
              container: true,
              button: true,
              child: TaroPressable(
                onTap: onFinish,
                borderRadius: tokens.radius.full,
                color: c.accent.subtle,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: tokens.size.touchTarget.min,
                    minWidth: tokens.size.touchTarget.min,
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: tokens.space.s5,
                      vertical: tokens.space.s3,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        finishLabel!,
                        textAlign: TextAlign.center,
                        style: tokens.typography.label.copyWith(
                          color: c.text.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        : null;
    return Material(
      color: c.bg.surface,
      borderRadius: BorderRadius.circular(tokens.radius.lg),
      // At large text the Finish action moves under the row (01 §12).
      child: taroShouldReflow(context)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                main,
                if (finish != null)
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: tokens.space.s4,
                      bottom: tokens.space.s4,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: finish,
                    ),
                  ),
              ],
            )
          : Row(
              children: [
                Expanded(child: main),
                ?finish,
              ],
            ),
    );
  }
}
