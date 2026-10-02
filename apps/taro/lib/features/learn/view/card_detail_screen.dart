import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/features/learn/controller/card_detail_controller.dart';
import 'package:taro/features/learn/view/learn_labels.dart';
import 'package:taro/features/learn/view/learn_top_bar.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S17 Learn card detail (01 §7.9) for [cardId], opened from [origin].
class CardDetailScreen extends ConsumerWidget {
  /// Creates the screen.
  const CardDetailScreen({
    required this.cardId,
    this.origin = LearnCardOrigin.deck,
    super.key,
  });

  /// The card shown.
  final CardId cardId;

  /// Where it was opened from (`learn_card_viewed.origin`).
  final LearnCardOrigin origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = cardDetailControllerProvider(
      CardDetailArgs(cardId: cardId, origin: origin),
    );
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final artSet = ref.watch(deckArtSetProvider).value ?? CardArt.defaultArtSet;
    return CardDetailLayout(
      state: state,
      artSet: artSet,
      onReversed: (reversed) =>
          unawaited(controller.setReversed(reversed: reversed)),
      onZoom: controller.zoom,
      onCloseZoom: controller.closeZoom,
      onCard: (id) => context.pushReplacement(RoutePaths.learnCard(id.value)),
      // The journal tab, filtered to this card (`?card=`, S14).
      onJournal: () => context.go(
        Uri(
          path: RoutePaths.journal,
          queryParameters: {'card': cardId.value},
        ).toString(),
      ),
      onBack: () => Navigator.of(context).maybePop(),
      onRetry: () => ref.invalidate(provider),
    );
  }
}

/// The S17 view for one [state]: the hero (art + facts + keywords), the
/// Upright / Reversed toggle, the meaning, the aspects, the reflection
/// questions, the journal link and previous / next navigation.
class CardDetailLayout extends StatelessWidget {
  /// Creates the view.
  const CardDetailLayout({
    required this.state,
    required this.onReversed,
    required this.onZoom,
    required this.onCloseZoom,
    required this.onCard,
    required this.onJournal,
    required this.onBack,
    required this.onRetry,
    this.artSet = CardArt.defaultArtSet,
    super.key,
  });

  /// The controller state.
  final CardDetailState state;

  /// The bundled art set.
  final String artSet;

  /// The Upright / Reversed toggle.
  final ValueChanged<bool> onReversed;

  /// Opens the full-screen art.
  final VoidCallback onZoom;

  /// Closes the full-screen art.
  final VoidCallback onCloseZoom;

  /// Opens the previous or next card.
  final ValueChanged<CardId> onCard;

  /// "In your journal: drawn N times" (→ Journal filtered by the card).
  final VoidCallback onJournal;

  /// Back.
  final VoidCallback onBack;

  /// Retries after a storage error.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    return switch (state) {
      CardDetailLoading() => _frame(
        context,
        null,
        TaroLoadingView(
          semanticsLabel: l10n.commonLoading,
          layout: TaroLoadingLayout.text,
        ),
      ),
      CardDetailStorageError() => _frame(
        context,
        null,
        TaroErrorView(
          kind: TaroErrorKind.storage,
          title: l10n.errorStorageTitle,
          body: l10n.errorStorageBody,
          onRetry: onRetry,
          retryLabel: l10n.commonRetry,
        ),
      ),
      CardDetailZoomed(:final view) => _Zoomed(
        image: CardArt.face(view.card.id, artSet: artSet),
        onClose: onCloseZoom,
      ),
      CardDetailUpright(:final view) => _frame(
        context,
        view,
        _Detail(view: view, reversed: false, layout: this),
      ),
      CardDetailReversed(:final view) => _frame(
        context,
        view,
        _Detail(view: view, reversed: true, layout: this),
      ),
    };
  }

  Widget _frame(BuildContext context, CardDetailView? view, Widget body) {
    final l10n = TaroLocalizations.of(context);
    final previous = view?.previous;
    final next = view?.next;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    void swipe(DragEndDetails details) {
      final velocity = details.primaryVelocity ?? 0;
      if (velocity == 0) return;
      // A swipe towards the start edge shows the next card.
      final forward = rtl ? velocity > 0 : velocity < 0;
      final target = forward ? next : previous;
      if (target != null) onCard(target);
    }

    return TaroScaffold(
      appBar: LearnTopBar(
        caption: view == null
            ? null
            : l10n.cardPosition(
                LearnLabels.sectionOf(l10n, view.card),
                view.position,
                view.sectionSize,
              ),
        onBack: onBack,
        actions: [
          if (view != null) ...[
            TaroIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              semanticsLabel: l10n.cardPreviousAction,
              onPressed: previous == null ? null : () => onCard(previous),
            ),
            TaroIconButton(
              icon: Icons.arrow_forward_ios_rounded,
              semanticsLabel: l10n.cardNextAction,
              onPressed: next == null ? null : () => onCard(next),
            ),
          ],
        ],
      ),
      body: view == null
          ? body
          : GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: swipe,
              child: body,
            ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.view,
    required this.reversed,
    required this.layout,
  });

  final CardDetailView view;
  final bool reversed;
  final CardDetailLayout layout;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final motion = context.motion;
    final text = view.text;
    final aspects = text.aspects;
    final orientation = reversed ? l10n.commonReversed : l10n.commonUpright;
    // The text cross-fades on the toggle (reduced motion: instant).
    final meaning = AnimatedSwitcher(
      duration: motion.duration.base,
      switchInCurve: motion.easing.standard,
      switchOutCurve: motion.easing.standard,
      layoutBuilder: (current, previous) =>
          Stack(children: [...previous, ?current]),
      child: Column(
        key: ValueKey(reversed),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.space.s5,
        children: [
          _Heading(
            reversed ? l10n.cardMeaningReversed : l10n.cardMeaningUpright,
          ),
          _ReadingWidth(
            child: Text(
              reversed ? text.meaningReversed : text.meaningUpright,
              style: tokens.typography.bodyReading.copyWith(
                color: tokens.color.text.primary,
              ),
            ),
          ),
          _Aspects(
            rows: [
              (
                l10n.cardAspectRelationships,
                reversed
                    ? aspects.relationshipsReversed
                    : aspects.relationshipsUpright,
              ),
              (
                l10n.cardAspectWork,
                reversed ? aspects.workReversed : aspects.workUpright,
              ),
              (
                l10n.cardAspectGrowth,
                reversed ? aspects.growthReversed : aspects.growthUpright,
              ),
            ],
          ),
        ],
      ),
    );
    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.only(
        top: tokens.space.s5,
        bottom: tokens.space.s7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.space.s5,
        children: [
          _Hero(
            view: view,
            reversed: reversed,
            artSet: layout.artSet,
            orientation: orientation,
            onZoom: layout.onZoom,
          ),
          Semantics(
            container: true,
            label: l10n.cardOrientationLegend,
            child: SegmentedChoice<bool>(
              segments: [
                TaroSegment(value: false, label: l10n.commonUpright),
                TaroSegment(value: true, label: l10n.commonReversed),
              ],
              selected: reversed,
              onChanged: layout.onReversed,
            ),
          ),
          meaning,
          if (text.reflectionQuestions.isNotEmpty) ...[
            _Heading(l10n.cardReflectionQuestions),
            for (final question in text.reflectionQuestions)
              _Question(question),
          ],
          _JournalLink(count: view.drawnCount, onTap: layout.onJournal),
        ],
      ),
    );
  }
}

/// The card art (tap → zoom) beside the name, facts and keywords; stacked
/// at reflow text sizes.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.view,
    required this.reversed,
    required this.artSet,
    required this.orientation,
    required this.onZoom,
  });

  final CardDetailView view;
  final bool reversed;
  final String artSet;
  final String orientation;
  final VoidCallback onZoom;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final card = view.card;
    final text = view.text;
    final numeral = LearnLabels.numeral(card);
    final element = card.element;
    final factStyle = tokens.typography.caption.copyWith(
      color: c.text.secondary,
    );
    final keywords = reversed ? text.keywordsReversed : text.keywordsUpright;
    final art = Semantics(
      button: true,
      label: l10n.dailyCardFaceSemantics(text.name, orientation),
      hint: l10n.cardZoomOpen,
      onTap: onZoom,
      excludeSemantics: true,
      child: TaroCardFace(
        image: CardArt.face(
          card.id,
          artSet: artSet,
          cacheWidth: CardArt.cacheWidthOf(context, tokens.size.card.md),
        ),
        semanticsLabel: text.name,
        reversed: reversed,
        reversedLabel: l10n.commonReversed,
        onTap: onZoom,
      ),
    );
    final facts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.space.s3,
      children: [
        Semantics(
          header: true,
          child: Text(
            text.name,
            style: tokens.typography.headline.copyWith(color: c.text.primary),
          ),
        ),
        Row(
          spacing: tokens.space.s2,
          children: [
            SuitGlyph(LearnLabels.suitOfCard(card), size: SuitGlyphSize.sm),
            Flexible(
              child: Text(LearnLabels.arcanaLine(l10n, card), style: factStyle),
            ),
          ],
        ),
        if (element != null)
          Text(
            l10n.cardElementValue(LearnLabels.element(l10n, element)),
            style: factStyle,
          ),
        if (numeral != null)
          Text(l10n.cardNumberValue(numeral), style: factStyle),
        if (keywords.isNotEmpty)
          Semantics(
            label: l10n.dailyKeywordsSemantics(keywords.join(', ')),
            excludeSemantics: true,
            child: Wrap(
              spacing: tokens.space.s2,
              runSpacing: tokens.space.s2,
              children: [
                for (final k in keywords)
                  TaroBadge(label: k, variant: TaroBadgeVariant.keyword),
              ],
            ),
          ),
      ],
    );
    if (MediaQuery.textScalerOf(context).scale(1) >
        kSegmentedChoiceReflowScale) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.space.s5,
        children: [
          Center(child: art),
          facts,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.space.s5,
      children: [
        art,
        Expanded(child: facts),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      header: true,
      child: Text(
        text,
        style: tokens.typography.titleSmall.copyWith(
          color: tokens.color.text.primary,
        ),
      ),
    );
  }
}

/// Caps long text at `layout.readingMaxWidth` on tablets.
class _ReadingWidth extends StatelessWidget {
  const _ReadingWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topStart,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: context.tokens.layout.readingMaxWidth,
      ),
      child: child,
    ),
  );
}

/// Relationships, Work & purpose, Personal growth, each "label: text".
class _Aspects extends StatelessWidget {
  const _Aspects({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    return Container(
      padding: EdgeInsetsDirectional.all(tokens.space.s4),
      decoration: BoxDecoration(
        color: c.bg.surface,
        borderRadius: BorderRadius.circular(tokens.radius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.space.s3,
        children: [
          for (final (label, text) in rows)
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.space.s1,
                children: [
                  Text(
                    label,
                    style: tokens.typography.caption.copyWith(
                      color: c.text.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    text,
                    style: tokens.typography.label.copyWith(
                      color: c.text.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One reflection question behind a `color.accent.subtle` start rule.
class _Question extends StatelessWidget {
  const _Question(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return _ReadingWidth(
      child: Container(
        padding: EdgeInsetsDirectional.only(start: tokens.space.s4),
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(
              color: tokens.color.accent.subtle,
              width: TaroStrokes.focusRing,
            ),
          ),
        ),
        child: Text(
          text,
          style: tokens.typography.bodyReading.copyWith(
            color: tokens.color.text.secondary,
          ),
        ),
      ),
    );
  }
}

/// "In your journal: drawn N times" (→ filtered journal); with N = 0 the
/// row reads "Not in your journal yet" and is not tappable.
class _JournalLink extends StatelessWidget {
  const _JournalLink({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final icon = Icon(
      Icons.article_outlined,
      size: tokens.size.icon.md,
      color: tokens.color.accent.primary,
    );
    if (count == 0) {
      return Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: tokens.space.s3),
        child: Row(
          spacing: tokens.space.s4,
          children: [
            ExcludeSemantics(child: icon),
            Expanded(
              child: Text(
                l10n.cardDrawnTimes(0),
                style: tokens.typography.body.copyWith(
                  color: tokens.color.text.secondary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return SettingsSection(
      children: [
        SettingsTile(
          leading: icon,
          title: l10n.cardDrawnTimes(count),
          onTap: onTap,
        ),
      ],
    );
  }
}

/// `zoomed`: the art full screen on an opaque `color.bg.scrim`, pinch to
/// zoom, a Close button. The art is never mirrored.
class _Zoomed extends StatelessWidget {
  const _Zoomed({required this.image, required this.onClose});

  final ImageProvider image;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return Material(
      color: Color.alphaBlend(tokens.color.bg.scrim, tokens.color.bg.canvas),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Semantics(
                image: true,
                label: l10n.cardZoomSemantics,
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Padding(
                    padding: EdgeInsetsDirectional.all(tokens.space.s7),
                    child: Image(
                      image: image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: tokens.space.s2,
              end: tokens.space.s2,
              child: TaroIconButton(
                icon: Icons.close_rounded,
                semanticsLabel: l10n.commonClose,
                onPressed: onClose,
                color: tokens.color.text.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
