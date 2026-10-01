import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/common/disclaimer_footer.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/features/reading/controller/draw_state.dart';
import 'package:taro/features/reading/view/spread_slots.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// Whether the ambient text scale reflows rows into columns (01 §12).
bool _reflow(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > kSpreadReflowTextScale;

/// The ritual frame: a scrolling top part and the pinned [bottom].
class _RitualFrame extends StatelessWidget {
  const _RitualFrame({required this.content, this.bottom = const []});

  final List<Widget> content;
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final gutter = EdgeInsetsDirectional.symmetric(
      horizontal: tokens.layout.gutter,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: gutter.add(
              EdgeInsetsDirectional.only(
                top: tokens.space.s5,
                bottom: tokens.space.s5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: content,
            ),
          ),
        ),
        if (bottom.isNotEmpty)
          Padding(
            padding: gutter.add(
              EdgeInsetsDirectional.only(bottom: tokens.space.s5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: tokens.space.s3,
              children: bottom,
            ),
          ),
      ],
    );
  }
}

/// The centred serif title and its subtitle.
class _Heading extends StatelessWidget {
  const _Heading({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      spacing: tokens.space.s2,
      children: [
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: tokens.typography.cardName,
          ),
        ),
        if (subtitle case final subtitle?)
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: tokens.typography.label.copyWith(
              color: tokens.color.text.secondary,
            ),
          ),
      ],
    );
  }
}

/// Two buttons side by side, stacked above 1.5× text (01 §12).
class _ButtonPair extends StatelessWidget {
  const _ButtonPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    final gap = context.tokens.space.s4;
    if (_reflow(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: context.tokens.space.s3,
        children: [second, first],
      );
    }
    return Row(
      children: [
        Expanded(child: first),
        SizedBox(width: gap),
        Expanded(child: second),
      ],
    );
  }
}

/// S08 `shuffling` (`DrawShuffle.dc.html`): hold the deck or tap Shuffle;
/// "I'm ready — draw" is enabled once `motion.ritual.shuffle` has run (the
/// order was fixed when S08 opened, 01 §7.3, so the shuffle is ceremonial).
/// The drawn faces are decoded meanwhile (02 §17).
class ShufflePane extends StatefulWidget {
  /// Creates the pane.
  const ShufflePane({
    required this.view,
    required this.onShuffled,
    this.artSet = CardArt.defaultArtSet,
    super.key,
  });

  /// The draw.
  final DrawView view;

  /// The bundled art set (precached faces).
  final String artSet;

  /// "I'm ready — draw".
  final VoidCallback onShuffled;

  @override
  State<ShufflePane> createState() => _ShufflePaneState();
}

class _ShufflePaneState extends State<ShufflePane>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shuffle = AnimationController(vsync: this);
  bool _ready = false;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    unawaited(
      CardArt.precacheFaces(
        context,
        [for (final c in widget.view.draw.cards) c.cardId],
        logicalWidth: TaroCardSize.md.widthIn(context),
        artSet: widget.artSet,
      ),
    );
  }

  @override
  void dispose() {
    _shuffle.dispose();
    super.dispose();
  }

  void _runOnce() {
    _shuffle.duration = context.motion.ritual.shuffle;
    _shuffle.forward(from: 0).whenCompleteOrCancel(_done);
  }

  void _hold() {
    _shuffle.duration = context.motion.ritual.shuffle;
    unawaited(_shuffle.repeat());
  }

  void _release() {
    // The current loop finishes: at least one full shuffle.
    _shuffle.forward().whenCompleteOrCancel(_done);
  }

  void _done() {
    if (mounted && !_ready) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return _RitualFrame(
      content: [
        _Heading(title: l10n.drawShuffleTitle, subtitle: l10n.drawShuffleHint),
        SizedBox(height: tokens.space.s8),
        // The Shuffle button is the screen-reader path; the deck gesture is
        // a duplicate for touch only (06 §3.2 labelled targets).
        GestureDetector(
          excludeFromSemantics: true,
          onLongPressStart: (_) => _hold(),
          onLongPressEnd: (_) => _release(),
          onTap: _runOnce,
          child: ExcludeSemantics(
            child: Center(
              child: FittedBox(
                child: _ShuffleDeck(animation: _shuffle),
              ),
            ),
          ),
        ),
      ],
      bottom: [
        Text(
          l10n.drawShuffleNote,
          textAlign: TextAlign.center,
          style: tokens.typography.caption.copyWith(
            color: tokens.color.text.secondary,
          ),
        ),
        _ButtonPair(
          first: TaroButton.secondary(
            label: l10n.drawShuffleButton,
            icon: Icons.shuffle_rounded,
            expand: true,
            onPressed: _runOnce,
          ),
          second: TaroButton.primary(
            label: l10n.drawShuffleReady,
            expand: true,
            onPressed: _ready ? widget.onShuffled : null,
          ),
        ),
      ],
    );
  }
}

/// Three stacked backs that sway while [animation] runs; under reduced
/// motion a cross-fade dip instead (01 §14.4).
class _ShuffleDeck extends StatelessWidget {
  const _ShuffleDeck({required this.animation});

  final Animation<double> animation;

  static const List<double> _tilt = [-0.14, 0.08, 0];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final card = TaroCardSize.md.sizeOf(tokens);
    final reduced = context.reduceMotion;
    final sway = tokens.space.s8;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final phase = t * 2 * math.pi;
        return Opacity(
          opacity: reduced ? 1 - math.sin(t * math.pi) / 2 : 1,
          child: SizedBox(
            width: card.width + sway * 2,
            height: card.height + sway,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (var i = 0; i < _tilt.length; i++)
                  Transform.translate(
                    offset: Offset(
                      reduced ? 0 : math.sin(phase + i * 2) * sway,
                      0,
                    ),
                    child: Transform.rotate(
                      angle: _tilt[i] + (reduced ? 0 : math.sin(phase + i) / 8),
                      child: TaroCardBack(
                        size: TaroCardSize.md,
                        picked: i == _tilt.length - 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// S08 `picking` (`Draw.dc.html`): the spread's slots and the deck fan.
/// Tapping a card picks it; "Pick this card" picks the focused (centre)
/// card; "Draw for me" places every remaining card (01 §12).
class PickPane extends StatefulWidget {
  /// Creates the pane.
  const PickPane({
    required this.view,
    required this.onPick,
    required this.onDrawForMe,
    super.key,
  });

  /// The draw.
  final DrawView view;

  /// One card was picked.
  final VoidCallback onPick;

  /// "Draw for me".
  final VoidCallback onDrawForMe;

  @override
  State<PickPane> createState() => _PickPaneState();
}

class _PickPaneState extends State<PickPane> {
  int? _focus;
  int _placedBefore = 0;

  @override
  void initState() {
    super.initState();
    _placedBefore = widget.view.placed;
  }

  @override
  void didUpdateWidget(PickPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.view.placed != widget.view.placed) {
      _placedBefore = oldWidget.view.placed;
    }
  }

  void _pick() {
    unawaited(TaroHaptics.pick(context));
    widget.onPick();
  }

  void _drawForMe() {
    unawaited(TaroHaptics.pick(context));
    widget.onDrawForMe();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final view = widget.view;
    final open = !view.allPlaced;
    final remaining = view.cardCount - view.placed;
    final deckLeft = Deck.size - view.placed;
    final focus = math.min(_focus ?? deckLeft ~/ 2, deckLeft - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _RitualFrame(
            content: [
              _Heading(
                title: open
                    ? l10n.drawPickTitle(remaining)
                    : l10n.drawRevealTitle,
                subtitle: l10n.drawPickSubtitle,
              ),
              SizedBox(height: tokens.space.s7),
              _canvas(context),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(bottom: tokens.space.s5),
          child: RepaintBoundary(
            child: CardFan(
              cardCount: deckLeft,
              semanticsLabel: l10n.drawDeckSemantics(deckLeft),
              cardSemanticsLabel: (_) => l10n.drawCardBackSemantics(
                view.placed + 1,
                view.cardCount,
              ),
              drawForMeLabel: l10n.drawForMe,
              onDrawForMe: open ? _drawForMe : null,
              focusedIndex: focus,
              onFocus: open
                  ? (index) {
                      setState(() => _focus = index);
                      widget.onPick();
                    }
                  : null,
              confirmLabel: l10n.drawPickThis,
              onConfirm: open ? _pick : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _canvas(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final view = widget.view;
    final layouts = spreadSlotLayouts(view.spread);
    return SpreadCanvas(
      semanticsLabel: SpreadText.name(l10n, view.spread.id),
      cardSize: view.cardCount <= 3 ? TaroCardSize.md : TaroCardSize.sm,
      slots: [
        for (var i = 0; i < view.cardCount; i++)
          _slot(context, i, layouts[math.min(i, layouts.length - 1)]),
      ],
    );
  }

  SpreadCanvasSlot _slot(BuildContext context, int i, SpreadSlotLayout at) {
    final l10n = TaroLocalizations.of(context);
    final view = widget.view;
    final name = SpreadText.positionName(
      l10n,
      view.spread.id,
      view.draw.cards[i].positionId,
    );
    return SpreadCanvasSlot(
      layout: at,
      label: name,
      number: i + 1,
      emptySemanticsLabel: l10n.drawEmptySlotSemantics(i + 1, name),
      card: i < view.placed
          ? _DealIn(
              key: ValueKey('dealt-$i'),
              stagger: view.autoDraw ? math.max(0, i - _placedBefore) : 0,
              child: TaroCardBack(
                picked: i == view.placed - 1,
                semanticsLabel: l10n.drawSlotBackSemantics(
                  i + 1,
                  view.cardCount,
                  name,
                ),
              ),
            )
          : null,
    );
  }
}

/// A picked card arriving in its slot: it rises into place over
/// `motion.duration.slow` with `motion.easing.emphasized`, [stagger] ×
/// `motion.ritual.dealStagger` late; a fade under reduced motion.
class _DealIn extends StatefulWidget {
  const _DealIn({required this.child, this.stagger = 0, super.key});

  final Widget child;
  final int stagger;

  @override
  State<_DealIn> createState() => _DealInState();
}

class _DealInState extends State<_DealIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
  );
  Timer? _delay;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final motion = context.motion;
    _controller.duration = motion.duration.slow;
    final wait = motion.ritual.dealStagger * widget.stagger;
    if (wait == Duration.zero) {
      unawaited(_controller.forward());
    } else {
      _delay = Timer(wait, () {
        if (mounted) unawaited(_controller.forward());
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = context.reduceMotion;
    final easing = context.motion.easing.emphasized;
    final rise = context.tokens.space.s12;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        final eased = easing.transform(t);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, reduced ? 0 : (1 - eased) * rise),
            child: child,
          ),
        );
      },
    );
  }
}

/// S08 after the pick: `revealing` (`DrawReveal.dc.html`), the keywords
/// view while the reading is written (`DrawAwaiting.dc.html`, plus
/// `slowReading` / `timeoutPolling`), `generationFailed`,
/// `deliveryExpired` and `holdLost` (every card face-down, RC48, RC50).
/// The `disclaimerShort` footer closes every one of them.
class ResultPane extends StatelessWidget {
  /// Creates the pane.
  const ResultPane({
    required this.state,
    required this.view,
    required this.onReveal,
    required this.onRevealAll,
    required this.onRetry,
    required this.onFinishLater,
    required this.onOpenOptions,
    this.artSet = CardArt.defaultArtSet,
    super.key,
  });

  /// The controller state.
  final DrawState state;

  /// The draw.
  final DrawView view;

  /// The bundled art set.
  final String artSet;

  /// The next card was flipped.
  final VoidCallback onReveal;

  /// "Reveal all".
  final VoidCallback onRevealAll;

  /// "Try again".
  final VoidCallback onRetry;

  /// "Save and finish later".
  final VoidCallback onFinishLater;

  /// S10 after `holdLost`.
  final VoidCallback onOpenOptions;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final revealing = state is DrawRevealing;
    final faceDown = state is DrawHoldLost;
    final waiting = switch (state) {
      DrawAwaitingReading() ||
      DrawSlowReading() ||
      DrawTimeoutPolling() => true,
      _ => false,
    };
    final shown = revealing ? view.revealed : (faceDown ? 0 : view.cardCount);
    final question = view.question;
    final status = switch (state) {
      DrawSlowReading() => l10n.drawSlowReading,
      DrawTimeoutPolling() => l10n.drawTimeoutPolling,
      _ => null,
    };
    final Widget? notice = switch (state) {
      DrawGenerationFailed() => TaroInlineNotice(
        kind: TaroNoticeKind.error,
        title: l10n.drawGenerationFailedTitle,
        body: l10n.drawGenerationFailedBody,
        liveRegion: true,
      ),
      DrawDeliveryExpired() => TaroInlineNotice(
        kind: TaroNoticeKind.info,
        title: l10n.drawDeliveryExpired,
        liveRegion: true,
      ),
      DrawHoldLost() => TaroInlineNotice(
        kind: TaroNoticeKind.info,
        title: l10n.drawHoldLost,
        liveRegion: true,
      ),
      _ => null,
    };
    Widget primary(String label, VoidCallback onPressed) =>
        TaroButton.primary(label: label, expand: true, onPressed: onPressed);
    Widget secondary(String label, VoidCallback onPressed) =>
        TaroButton.secondary(label: label, expand: true, onPressed: onPressed);
    final actions = switch (state) {
      DrawRevealing() => [secondary(l10n.drawRevealAll, onRevealAll)],
      DrawSlowReading() || DrawTimeoutPolling() => [
        secondary(l10n.drawFinishLater, onFinishLater),
      ],
      DrawGenerationFailed() => [
        primary(l10n.commonRetry, onRetry),
        secondary(l10n.drawFinishLater, onFinishLater),
      ],
      DrawDeliveryExpired() => [primary(l10n.commonRetry, onRetry)],
      DrawHoldLost() => [primary(l10n.outOfReadingsGetMore, onOpenOptions)],
      _ => const <Widget>[],
    };
    return _RitualFrame(
      content: [
        if (revealing) ...[
          _Heading(title: l10n.drawRevealTitle, subtitle: l10n.drawRevealHint),
          SizedBox(height: tokens.space.s7),
        ],
        _canvas(context, revealing: revealing, faceDown: faceDown),
        if (shown > 0) ...[
          SizedBox(height: tokens.space.s7),
          _KeywordsList(view: view, count: shown),
        ],
        if (waiting) ...[
          SizedBox(height: tokens.space.s8),
          _Progress(status: status),
        ],
        if (notice != null) ...[SizedBox(height: tokens.space.s7), notice],
        if (revealing && question != null && question.isNotEmpty) ...[
          SizedBox(height: tokens.space.s7),
          Text(
            question,
            textAlign: TextAlign.center,
            style: tokens.typography.body.copyWith(
              color: tokens.color.text.secondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const DisclaimerFooter(centered: true),
      ],
      bottom: actions,
    );
  }

  Widget _canvas(
    BuildContext context, {
    required bool revealing,
    required bool faceDown,
  }) {
    final l10n = TaroLocalizations.of(context);
    final layouts = spreadSlotLayouts(view.spread);
    final size = revealing && view.cardCount <= 3
        ? TaroCardSize.md
        : TaroCardSize.sm;
    return SpreadCanvas(
      semanticsLabel: SpreadText.name(l10n, view.spread.id),
      cardSize: size,
      slots: [
        for (var i = 0; i < view.cardCount; i++)
          () {
            final card = view.draw.cards[i];
            final name = SpreadText.positionName(
              l10n,
              view.spread.id,
              card.positionId,
            );
            final back = TaroCardBack(
              semanticsLabel: l10n.drawSlotBackSemantics(
                i + 1,
                view.cardCount,
                name,
              ),
            );
            final Widget slot;
            if (faceDown) {
              slot = back;
            } else if (revealing) {
              final next = i == view.revealed;
              slot = TaroCardFlip(
                key: ValueKey('flip-$i'),
                revealed: i < view.revealed,
                back: next ? _nextBack(context, i, name) : back,
                face: i < view.revealed
                    ? _Face(card: card, position: name, artSet: artSet)
                    : const SizedBox.shrink(),
              );
            } else {
              slot = _Face(card: card, position: name, artSet: artSet);
            }
            return SpreadCanvasSlot(
              layout: layouts[math.min(i, layouts.length - 1)],
              label: name,
              number: i + 1,
              card: slot,
            );
          }(),
      ],
    );
  }

  /// The next card to turn: tappable, with "Tap to reveal".
  Widget _nextBack(BuildContext context, int i, String name) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return Stack(
      alignment: AlignmentDirectional.bottomCenter,
      children: [
        TaroCardBack(
          picked: true,
          onTap: onReveal,
          semanticsLabel: l10n.drawSlotRevealSemantics(
            i + 1,
            view.cardCount,
            name,
          ),
        ),
        PositionedDirectional(
          bottom: tokens.space.s4,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: TaroBadge(label: l10n.drawTapToReveal),
            ),
          ),
        ),
      ],
    );
  }
}

/// A revealed card face, its art decoded at its layout width (02 §17).
class _Face extends ConsumerWidget {
  const _Face({
    required this.card,
    required this.position,
    required this.artSet,
  });

  final DrawnCard card;
  final String position;
  final String artSet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TaroLocalizations.of(context);
    final text = ref.watch(cardTextProvider(card.cardId)).value;
    final name = text?.name ?? '';
    const size = TaroCardSize.md;
    return TaroCardFace(
      image: CardArt.face(
        card.cardId,
        artSet: artSet,
        cacheWidth: CardArt.cacheWidthOf(context, size.widthIn(context)),
      ),
      semanticsLabel: l10n.drawCardSemantics(
        name,
        card.reversed ? l10n.commonReversed : l10n.commonUpright,
        position,
      ),
      reversed: card.reversed,
      reversedLabel: l10n.commonReversed,
    );
  }
}

/// Position, card name (+ "Reversed") and 3 keywords per revealed card
/// (PR8 keywords view).
class _KeywordsList extends ConsumerWidget {
  const _KeywordsList({required this.view, required this.count});

  final DrawView view;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    return TaroSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) Divider(height: tokens.space.s7, color: c.border.subtle),
            () {
              final card = view.draw.cards[i];
              final text = ref.watch(cardTextProvider(card.cardId)).value;
              final keywords =
                  text?.keywords(reversed: card.reversed).take(3) ??
                  const <String>[];
              return MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: tokens.space.s1,
                  children: [
                    Text(
                      SpreadText.positionName(
                        l10n,
                        view.spread.id,
                        card.positionId,
                      ),
                      style: tokens.typography.label.copyWith(
                        color: c.text.tertiary,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        text: text?.name ?? '',
                        children: [
                          if (card.reversed)
                            TextSpan(
                              text: ', ${l10n.commonReversed}',
                              style: TextStyle(color: c.card.reversedBadge),
                            ),
                        ],
                      ),
                      style: tokens.typography.cardName,
                    ),
                    Text(
                      keywords.join(' · '),
                      style: tokens.typography.body.copyWith(
                        color: c.text.secondary,
                      ),
                    ),
                  ],
                ),
              );
            }(),
          ],
        ],
      ),
    );
  }
}

/// "Writing your reading…" with a calm, indeterminate bar (no percentage,
/// no fake progress) and the slow / polling line.
class _Progress extends StatelessWidget {
  const _Progress({this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return Column(
      spacing: tokens.space.s3,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            l10n.drawAwaitingTitle,
            textAlign: TextAlign.center,
            style: tokens.typography.cardName,
          ),
        ),
        ExcludeSemantics(
          child: FractionallySizedBox(
            widthFactor: 0.4,
            child: TaroShimmer(child: SkeletonBlock(height: tokens.space.s1)),
          ),
        ),
        Semantics(
          liveRegion: status != null,
          child: Text(
            status ?? l10n.drawAwaitingBody,
            textAlign: TextAlign.center,
            style: tokens.typography.body.copyWith(
              color: tokens.color.text.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
