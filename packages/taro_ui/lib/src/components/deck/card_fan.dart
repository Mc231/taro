import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:taro_ui/src/a11y/taro_haptics.dart';
import 'package:taro_ui/src/components/actions/taro_button.dart';
import 'package:taro_ui/src/components/deck/taro_card_back.dart';
import 'package:taro_ui/src/components/deck/taro_card_size.dart';
import 'package:taro_ui/src/motion/taro_motion.dart';
import 'package:taro_ui/src/theme/taro_tokens_extension.dart';

/// The deck as a horizontally scrollable arc of face-down cards (S08
/// `shuffling`, `picking`; `docs/design/components.md` § CardFan).
///
/// Tapping a card focuses it (lifted, `color.card.glow`, `haptic.pick`);
/// [confirmLabel] then picks it through [onConfirm]. "Draw for me"
/// ([drawForMeLabel], [onDrawForMe]) is always offered as the alternative to
/// the gesture (01 §12). While [shuffling] the cards drift in a loop of
/// `motion.ritual.shuffle`; under reduced motion the fan is static. With no
/// cards left ([cardCount] 0, exhausted) both actions are disabled.
class CardFan extends StatefulWidget {
  /// Creates the fan.
  const CardFan({
    required this.cardCount,
    required this.semanticsLabel,
    required this.cardSemanticsLabel,
    required this.drawForMeLabel,
    required this.onDrawForMe,
    this.focusedIndex,
    this.onFocus,
    this.confirmLabel,
    this.onConfirm,
    this.shuffling = false,
    super.key,
  });

  /// Cards left in the deck.
  final int cardCount;

  /// Localised label of the deck ("Deck, 76 cards").
  final String semanticsLabel;

  /// Localised label of card `index` ("Card 5 of 76, double-tap to pick").
  final String Function(int index) cardSemanticsLabel;

  /// Localised "Draw for me".
  final String drawForMeLabel;

  /// Picks a card for the user; null disables the button.
  final VoidCallback? onDrawForMe;

  /// The focused card, if any.
  final int? focusedIndex;

  /// Called with the tapped card's index.
  final ValueChanged<int>? onFocus;

  /// Localised "Pick this card"; null hides the confirm button.
  final String? confirmLabel;

  /// Picks the focused card; enabled only while a card is focused.
  final VoidCallback? onConfirm;

  /// The hold-to-shuffle loop.
  final bool shuffling;

  @override
  State<CardFan> createState() => _CardFanState();
}

class _CardFanState extends State<CardFan> with SingleTickerProviderStateMixin {
  ScrollController? _scroll;
  late final AnimationController _shuffle = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncShuffle();
  }

  @override
  void didUpdateWidget(CardFan oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncShuffle();
  }

  void _syncShuffle() {
    if (widget.shuffling && !context.reduceMotion && widget.cardCount > 0) {
      _shuffle.duration = context.motion.ritual.shuffle;
      if (!_shuffle.isAnimating) unawaited(_shuffle.repeat());
    } else {
      _shuffle
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _scroll?.dispose();
    _shuffle.dispose();
    super.dispose();
  }

  void _focus(int index) {
    unawaited(TaroHaptics.pick(context));
    widget.onFocus?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final exhausted = widget.cardCount == 0;
    final card = TaroCardSize.sm.sizeOf(tokens);
    final lift = tokens.space.s5;
    final drop = tokens.space.s8;
    final fan = SizedBox(
      height: card.height + lift + drop + tokens.space.s5,
      child: exhausted
          ? const SizedBox.shrink()
          : LayoutBuilder(builder: (context, c) => _fan(context, c.maxWidth)),
    );
    final confirm = widget.confirmLabel;
    final actions = Row(
      children: [
        Expanded(
          child: TaroButton.secondary(
            label: widget.drawForMeLabel,
            onPressed: exhausted ? null : widget.onDrawForMe,
          ),
        ),
        if (confirm != null) ...[
          SizedBox(width: tokens.space.s4),
          Expanded(
            child: TaroButton.primary(
              label: confirm,
              onPressed: exhausted || widget.focusedIndex == null
                  ? null
                  : widget.onConfirm,
            ),
          ),
        ],
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: widget.semanticsLabel,
          child: fan,
        ),
        SizedBox(height: tokens.space.s5),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: tokens.layout.gutter,
          ),
          child: actions,
        ),
      ],
    );
  }

  Widget _fan(BuildContext context, double viewport) {
    final tokens = context.tokens;
    final card = TaroCardSize.sm.sizeOf(tokens);
    final step = card.width / 2;
    final count = widget.cardCount;
    final total = step * (count - 1) + card.width;
    final padding = math.max(0, (viewport - card.width) / 2).toDouble();
    final content = total + padding * 2;
    final scroll = _scroll ??= ScrollController(
      initialScrollOffset: math.max(0, (content - viewport) / 2),
    );
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final lift = tokens.space.s5;
    final drop = tokens.space.s8;
    final jitter = tokens.space.s2;
    return SingleChildScrollView(
      controller: scroll,
      scrollDirection: Axis.horizontal,
      child: AnimatedBuilder(
        animation: Listenable.merge([scroll, _shuffle]),
        builder: (context, _) {
          final offset = scroll.hasClients ? scroll.offset : 0.0;
          final center = offset + viewport / 2;
          final first = math.max(0, ((offset - padding) / step).floor() - 2);
          final last = math.min(
            count - 1,
            ((offset + viewport - padding) / step).ceil() + 1,
          );
          final phase = _shuffle.value * 2 * math.pi;
          final children = <Widget>[];
          for (var i = first; i <= last; i++) {
            final start = padding + i * step;
            final dx = start + card.width / 2 - center;
            final visual = rtl ? -dx : dx;
            final t = (visual / (viewport / 2)).clamp(-1.0, 1.0);
            final focused = widget.focusedIndex == i;
            final shake = _shuffle.isAnimating
                ? math.sin(phase + i) * jitter
                : 0.0;
            children.add(
              PositionedDirectional(
                start: start + shake,
                top:
                    lift +
                    (1 - math.cos(t * math.pi / 2)) * drop -
                    (focused ? lift : 0),
                child: Transform.rotate(
                  angle: t * math.pi / 8,
                  alignment: AlignmentDirectional.bottomCenter,
                  child: TaroCardBack(
                    picked: focused,
                    semanticsLabel: widget.cardSemanticsLabel(i),
                    onTap: () => _focus(i),
                  ),
                ),
              ),
            );
          }
          // The focused card is painted over its neighbours.
          final focusedIndex = widget.focusedIndex;
          if (focusedIndex != null &&
              focusedIndex >= first &&
              focusedIndex <= last) {
            children.add(children.removeAt(focusedIndex - first));
          }
          return SizedBox(
            width: content,
            height: card.height + lift + drop + tokens.space.s5,
            child: Stack(clipBehavior: Clip.none, children: children),
          );
        },
      ),
    );
  }
}
