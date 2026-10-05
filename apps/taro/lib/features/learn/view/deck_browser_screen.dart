import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/features/learn/controller/deck_browser_controller.dart';
import 'package:taro/features/learn/view/learn_labels.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S16 Learn deck browser, tab "Learn" (01 §7.9): offline and ungated, with
/// the `learn_library` banner below the scroll view (RC18).
class DeckBrowserScreen extends ConsumerWidget {
  /// Creates the screen.
  const DeckBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deckBrowserControllerProvider);
    final controller = ref.read(deckBrowserControllerProvider.notifier);
    final artSet = ref.watch(deckArtSetProvider).value ?? CardArt.defaultArtSet;
    return DeckBrowserLayout(
      state: state,
      artSet: artSet,
      banner: const BannerSlot(BannerScreen.learnLibrary),
      onSearch: (text) => unawaited(controller.search(text)),
      onCard: (cardId) {
        final searching = state is DeckBrowserContent && state.query.isNotEmpty;
        unawaited(
          context.push<void>(
            Uri(
              path: RoutePaths.learnCard(cardId.value),
              queryParameters: {
                'origin':
                    (searching ? LearnCardOrigin.search : LearnCardOrigin.deck)
                        .name,
              },
            ).toString(),
          ),
        );
      },
      onSpreads: () => unawaited(context.push<void>(RoutePaths.learnSpreads)),
      onAbout: () => unawaited(context.push<void>(RoutePaths.learnAbout)),
      onRetry: () => ref.invalidate(deckBrowserControllerProvider),
    );
  }
}

/// The S16 view for one [state]: the title, the search field, the section
/// anchors, the grid grouped by section, the Spreads guide and About links,
/// and the [banner] slot outside the scroll view.
class DeckBrowserLayout extends StatefulWidget {
  /// Creates the view.
  const DeckBrowserLayout({
    required this.state,
    required this.onSearch,
    required this.onCard,
    required this.onSpreads,
    required this.onAbout,
    required this.onRetry,
    this.artSet = CardArt.defaultArtSet,
    this.banner,
    super.key,
  });

  /// The controller state.
  final DeckBrowserState state;

  /// The bundled art set.
  final String artSet;

  /// The `learn_library` banner slot (`BannerSlot`), above the tab bar.
  final Widget? banner;

  /// The search text changed.
  final ValueChanged<String> onSearch;

  /// Opens a card (S17).
  final ValueChanged<CardId> onCard;

  /// Opens the spreads guide (S18).
  final VoidCallback onSpreads;

  /// Opens About tarot & Taro (S19).
  final VoidCallback onAbout;

  /// Retries after a storage error.
  final VoidCallback onRetry;

  @override
  State<DeckBrowserLayout> createState() => _DeckBrowserLayoutState();
}

class _DeckBrowserLayoutState extends State<DeckBrowserLayout> {
  final Map<DeckSectionKind, GlobalKey> _anchors = {
    for (final kind in DeckSectionKind.values) kind: GlobalKey(),
  };
  DeckSectionKind? _selected;

  void _jumpTo(DeckSectionKind kind) {
    setState(() => _selected = kind);
    final target = _anchors[kind]?.currentContext;
    if (target == null) return;
    final motion = context.motion;
    unawaited(
      Scrollable.ensureVisible(
        target,
        duration: motion.duration.slow,
        curve: motion.easing.standard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final state = widget.state;
    final searchable = switch (state) {
      DeckBrowserContent() || DeckBrowserSearchEmpty() => true,
      _ => false,
    };
    final body = switch (state) {
      DeckBrowserLoading() => TaroLoadingView(
        semanticsLabel: l10n.commonLoading,
        layout: TaroLoadingLayout.cards,
      ),
      DeckBrowserSearchEmpty(:final query) => TaroEmptyView(
        title: l10n.learnSearchEmpty(query),
        largeTitle: false,
        illustration: Icon(
          Icons.search_rounded,
          size: tokens.size.icon.lg,
          color: tokens.color.text.tertiary,
        ),
      ),
      DeckBrowserStorageError() => TaroErrorView(
        kind: TaroErrorKind.storage,
        title: l10n.errorStorageTitle,
        body: l10n.errorStorageBody,
        onRetry: widget.onRetry,
        retryLabel: l10n.commonRetry,
      ),
      DeckBrowserContent(:final sections) => _content(context, sections),
    };
    return TaroScaffold(
      wide: true,
      bottomNavigationBar: widget.banner,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: tokens.space.s7),
          TaroLargeTitle(l10n.learnTitle),
          SizedBox(height: tokens.space.s4),
          if (searchable) ...[
            TaroTextField(
              style: TaroTextFieldStyle.search,
              hintText: l10n.learnSearchHint,
              clearLabel: l10n.commonDismiss,
              textInputAction: TextInputAction.search,
              onChanged: widget.onSearch,
            ),
            SizedBox(height: tokens.space.s4),
          ],
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, List<DeckSection> sections) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final selected = sections.any((s) => s.kind == _selected)
        ? _selected!
        : sections.first.kind;
    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.only(bottom: tokens.space.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sections.length > 1)
            _SectionAnchors(
              kinds: [for (final s in sections) s.kind],
              selected: selected,
              onSelected: _jumpTo,
            ),
          for (final section in sections) ...[
            SizedBox(height: tokens.space.s5),
            _SectionHeading(key: _anchors[section.kind], kind: section.kind),
            SizedBox(height: tokens.space.s3),
            _SectionGrid(
              section: section,
              artSet: widget.artSet,
              onCard: widget.onCard,
            ),
          ],
          SizedBox(height: tokens.space.s6),
          _LinkRow(
            icon: TaroIcon(
              TaroIcons.spread,
              color: tokens.color.accent.primary,
            ),
            title: l10n.learnSpreadsGuide,
            onTap: widget.onSpreads,
          ),
          SizedBox(height: tokens.space.s3),
          _LinkRow(
            icon: Icon(
              Icons.menu_book_outlined,
              size: tokens.size.icon.md,
              color: tokens.color.accent.primary,
            ),
            title: l10n.learnAbout,
            onTap: widget.onAbout,
          ),
        ],
      ),
    );
  }
}

/// The "Deck section" anchors: one chip per section in a horizontally
/// scrolling row (five labels do not fit across in long locales); a tap
/// scrolls the grid to that section (01 §7.9: one grid grouped by section).
class _SectionAnchors extends StatelessWidget {
  const _SectionAnchors({
    required this.kinds,
    required this.selected,
    required this.onSelected,
  });

  final List<DeckSectionKind> kinds;
  final DeckSectionKind selected;
  final ValueChanged<DeckSectionKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return Semantics(
      container: true,
      label: l10n.learnSectionLegend,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.color.bg.surface,
          borderRadius: BorderRadius.circular(tokens.radius.md),
        ),
        // Fades where anchors run past the edge (V2-05).
        child: TaroScrollRow(
          padding: EdgeInsetsDirectional.all(tokens.space.s1),
          spacing: tokens.space.s1,
          children: [
            for (final kind in kinds)
              TaroChip.filter(
                key: ValueKey('anchor-${kind.name}'),
                label: LearnLabels.section(l10n, kind),
                selected: kind == selected,
                onSelected: (_) => onSelected(kind),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.kind, super.key});

  final DeckSectionKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return Semantics(
      header: true,
      child: Row(
        spacing: tokens.space.s2,
        children: [
          SuitGlyph(LearnLabels.suitOf(kind), size: SuitGlyphSize.sm),
          Expanded(
            child: Text(
              LearnLabels.section(l10n, kind),
              style: tokens.typography.titleSmall.copyWith(
                color: tokens.color.text.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The densest grid: tablets fill `layout.maxContentWidthWide` (RC99).
const int _maxColumns = 8;

/// One section as rows of `CardGridTile`s: 3 columns on phones, growing to
/// [_maxColumns] within `layout.maxContentWidthWide` on tablets, one fewer
/// at reflow text sizes. Every row is as tall as its section's longest name
/// needs, so names never clip.
class _SectionGrid extends StatelessWidget {
  const _SectionGrid({
    required this.section,
    required this.artSet,
    required this.onCard,
  });

  final DeckSection section;
  final String artSet;
  final ValueChanged<CardId> onCard;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final gap = tokens.space.s3;
    final tiles = section.tiles;
    final sectionName = LearnLabels.section(l10n, section.kind);
    return LayoutBuilder(
      builder: (context, constraints) {
        final minTile = tokens.size.card.sm + 2 * tokens.space.s5;
        final reflow =
            MediaQuery.textScalerOf(context).scale(1) >
            kSegmentedChoiceReflowScale;
        final columns =
            (((constraints.maxWidth + gap) / (minTile + gap)).floor() -
                    (reflow ? 1 : 0))
                .clamp(2, _maxColumns);
        final tileWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        final height = _tileHeight(context, tileWidth);
        final width = CardArt.cacheWidthOf(context, tokens.size.card.thumb);
        return Column(
          spacing: gap,
          children: [
            for (var start = 0; start < tiles.length; start += columns)
              SizedBox(
                height: height,
                child: Row(
                  spacing: gap,
                  children: [
                    for (var i = start; i < start + columns; i++)
                      Expanded(
                        child: i < tiles.length
                            ? CardGridTile(
                                key: ValueKey(tiles[i].card.id),
                                image: CardArt.face(
                                  tiles[i].card.id,
                                  artSet: artSet,
                                  cacheWidth: width,
                                ),
                                name: tiles[i].name,
                                numeral: LearnLabels.tileNumeral(tiles[i].card),
                                semanticsLabel: l10n.learnCardTileSemantics(
                                  tiles[i].name,
                                  sectionName,
                                  i + 1,
                                  tiles.length,
                                ),
                                onTap: () => onCard(tiles[i].card.id),
                              )
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  /// Padding, numeral, gaps, the thumb-sized art and the tallest name.
  double _tileHeight(BuildContext context, double tileWidth) {
    final tokens = context.tokens;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double heightOf(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        textAlign: TextAlign.center,
      )..layout(maxWidth: tileWidth - 2 * tokens.space.s3);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final name = section.tiles
        .map((t) => heightOf(t.name, tokens.typography.label))
        .fold<double>(0, math.max);
    final numeral = heightOf('XVIII', tokens.typography.numeral);
    final art = tokens.size.card.thumb / tokens.size.card.aspectRatio;
    return (2 * tokens.space.s3 + numeral + 2 * tokens.space.s2 + art + name)
        .ceilToDouble();
  }
}

/// A link row ("Spreads guide", "About tarot & Taro"): `color.bg.surface`,
/// `radius.md`, icon + label + chevron.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final Widget icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SettingsSection(
    children: [SettingsTile(leading: icon, title: title, onTap: onTap)],
  );
}
