import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/journal/controller/journal_content.dart';
import 'package:taro/features/journal/controller/journal_list_controller.dart';
import 'package:taro/features/journal/view/journal_dialogs.dart';
import 'package:taro/features/journal/view/journal_labels.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S14 Journal list, tab "Journal" (01 §7.8; canvas `Journal`,
/// `JournalEmpty`, `JournalAr`). [cardId] (query `card`, the S17 "drawn N
/// times" link) opens the list filtered to the entries with that card.
///
/// The banner is `BannerSlot('journal_list')` in the scaffold's bottom slot:
/// outside the scroll view, above the tab bar, with both `space.adGap`
/// spacers collapsing with it (RC18, RC59).
class JournalListScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const JournalListScreen({this.cardId, super.key});

  /// The "contains card" filter to start with.
  final String? cardId;

  @override
  ConsumerState<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends ConsumerState<JournalListScreen> {
  JournalFilters _filters = const JournalFilters();
  PatternsRange _range = PatternsRange.d30;
  JournalUndoToast? _undoToast;

  JournalListController get _controller =>
      ref.read(journalListControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _startWithCard(widget.cardId);
  }

  @override
  void didUpdateWidget(JournalListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cardId != oldWidget.cardId) _startWithCard(widget.cardId);
  }

  void _startWithCard(String? id) {
    if (id == null || id.isEmpty) return;
    final card = CardId(id);
    _filters = _filters.copyWith(cardId: card);
    // The controller is read after this frame's build (no provider writes
    // while building).
    scheduleMicrotask(() {
      if (mounted) unawaited(_controller.setCard(card));
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<JournalListState>(journalListControllerProvider, (
      previous,
      next,
    ) {
      final before = previous is JournalListContent ? previous.undoable : null;
      final after = next is JournalListContent ? next.undoable : null;
      if (after != null && after != before) {
        _undoToast = JournalUndoToast.show(
          context,
          onUndo: () => unawaited(_controller.undo()),
        );
      } else if (before != null && next is JournalListContent) {
        // The 5 s window ended: the Undo goes with it.
        _undoToast?.close();
        _undoToast = null;
      }
    });
    final state = ref.watch(journalListControllerProvider);
    final clock = ref.watch(clockProvider);
    return JournalListLayout(
      state: state,
      filters: _filters,
      range: _range,
      now: clock.nowLocal,
      cardNames: ref.watch(journalCardNamesProvider).value ?? const {},
      banner: const BannerSlot(BannerScreen.journalList),
      onType: (type) {
        setState(() => _filters = _filters.copyWith(type: type));
        unawaited(_controller.setType(type));
      },
      onSpread: (spread) {
        setState(() => _filters = _filters.copyWith(spreadId: spread));
        unawaited(_controller.setSpread(spread));
      },
      onClearCard: () {
        setState(() => _filters = _filters.copyWith(cardId: null));
        unawaited(_controller.setCard(null));
      },
      onSearch: (text) => unawaited(_controller.search(text)),
      onClearFilters: () {
        setState(() => _filters = const JournalFilters());
        _controller.clearFilters();
      },
      onRange: (range) {
        setState(() => _range = range);
        unawaited(_controller.viewPatterns(range));
      },
      onOpen: (item) =>
          unawaited(context.push<void>(JournalLabels.location(item))),
      onFinish: (id) =>
          unawaited(context.push<void>(JournalLabels.finishLocation(id))),
      onDelete: (id) async {
        if (await confirmJournalDelete(context)) await _controller.delete(id);
      },
      onOpenCard: (card) =>
          unawaited(context.push<void>(RoutePaths.learnCard(card.value))),
      onStartReading: () => unawaited(context.push(RoutePaths.readingSpreads)),
      onOpenDaily: () => unawaited(context.push(RoutePaths.daily)),
      onRetry: () {
        // The search field is rebuilt empty, so the search ends too.
        unawaited(_controller.search(''));
        ref.invalidate(journalListControllerProvider);
      },
    );
  }
}

/// The S14 layout for [state] (`docs/design/screens/S14/spec.md`): the
/// title, search and filter chips, the Patterns card, month groups of
/// [JournalEntryTile] rows; and the `empty`, `filteredEmpty`, `searchEmpty`
/// and `storageError` states. [banner] sits below the scroll view on the
/// list states only (none while empty, loading or failed).
class JournalListLayout extends StatelessWidget {
  /// Creates the view.
  const JournalListLayout({
    required this.state,
    required this.filters,
    required this.now,
    required this.onType,
    required this.onSpread,
    required this.onClearCard,
    required this.onSearch,
    required this.onClearFilters,
    required this.onOpen,
    required this.onFinish,
    required this.onDelete,
    required this.onOpenCard,
    required this.onRange,
    required this.onStartReading,
    required this.onOpenDaily,
    required this.onRetry,
    this.range = PatternsRange.d30,
    this.cardNames = const {},
    this.banner,
    super.key,
  });

  /// The controller state.
  final JournalListState state;

  /// The filters the user picked (the chips' selected state).
  final JournalFilters filters;

  /// The Patterns window shown.
  final PatternsRange range;

  /// The current local time (the app's `Clock`): "Today", "Yesterday".
  final DateTime Function() now;

  /// Localized card names (daily card titles, Patterns, the card filter).
  final Map<CardId, String> cardNames;

  /// The bottom banner slot (`BannerSlot('journal_list')`).
  final Widget? banner;

  /// A type chip was tapped.
  final ValueChanged<JournalTypeFilter> onType;

  /// A spread was picked in the filter sheet (`null`: any spread).
  final ValueChanged<SpreadId?> onSpread;

  /// The "contains card" chip was cleared.
  final VoidCallback onClearCard;

  /// The search text changed.
  final ValueChanged<String> onSearch;

  /// "Clear filter".
  final VoidCallback onClearFilters;

  /// Opens an entry (S15).
  final ValueChanged<JournalItem> onOpen;

  /// "Finish reading" of a pending reading (S08 `awaitingReading`).
  final ValueChanged<ReadingId> onFinish;

  /// Deletes a reading (swipe or the row's delete action; asks first).
  final ValueChanged<ReadingId> onDelete;

  /// The Patterns "Most drawn" card (S17).
  final ValueChanged<CardId> onOpenCard;

  /// The Patterns 30/90-day toggle.
  final ValueChanged<PatternsRange> onRange;

  /// "Start a reading" (empty journal → S06).
  final VoidCallback onStartReading;

  /// "Reveal card" (empty journal → S13).
  final VoidCallback onOpenDaily;

  /// Retries after a storage error.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final listed = switch (state) {
      JournalListContent() ||
      JournalListFilteredEmpty() ||
      JournalListSearchEmpty() => true,
      _ => false,
    };
    Widget fill(Widget child) => SliverFillRemaining(child: child);
    final body = switch (state) {
      JournalListLoading() => [
        fill(
          TaroLoadingView(semanticsLabel: l10n.commonLoading, itemCount: 5),
        ),
      ],
      JournalListEmpty() => [
        fill(
          TaroEmptyView(
            illustration: const _EmptyIllustration(),
            title: l10n.journalEmptyTitle,
            body: l10n.journalEmptyBody,
            action: TaroButton.primary(
              label: l10n.homeStartReading,
              expand: true,
              onPressed: onStartReading,
            ),
            secondaryAction: TaroButton.secondary(
              label: l10n.homeDailyReveal,
              expand: true,
              onPressed: onOpenDaily,
            ),
          ),
        ),
      ],
      JournalListFilteredEmpty() => [
        fill(
          TaroEmptyView(
            title: l10n.journalFilteredEmpty,
            largeTitle: false,
            action: TaroButton.secondary(
              label: l10n.journalClearFilter,
              onPressed: onClearFilters,
            ),
          ),
        ),
      ],
      JournalListSearchEmpty(:final query) => [
        fill(
          TaroEmptyView(
            illustration: Icon(
              Icons.search_off,
              size: tokens.size.icon.lg,
              color: tokens.color.text.tertiary,
            ),
            title: l10n.journalSearchEmpty(query),
            largeTitle: false,
          ),
        ),
      ],
      JournalListStorageError() => [
        fill(
          TaroErrorView(
            kind: TaroErrorKind.storage,
            title: l10n.errorStorageTitle,
            body: l10n.errorStorageBody,
            onRetry: onRetry,
            retryLabel: l10n.commonRetry,
          ),
        ),
      ],
      JournalListContent(:final months, :final patterns) => [
        SliverPadding(
          padding: EdgeInsetsDirectional.only(bottom: tokens.space.s7),
          sliver: SliverList.list(
            children: [
              if (patterns != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(top: tokens.space.s4),
                  child: _PatternsCard(
                    patterns: patterns,
                    range: range,
                    names: cardNames,
                    onRange: onRange,
                    onOpenCard: onOpenCard,
                  ),
                ),
              for (final month in months) ...[
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    top: tokens.space.s6,
                    bottom: tokens.space.s3,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(
                      JournalLabels.month(l10n, month.yearMonth),
                      style: tokens.typography.caption.copyWith(
                        color: tokens.color.text.tertiary,
                      ),
                    ),
                  ),
                ),
                for (final item in month.items)
                  Padding(
                    key: ValueKey(JournalLabels.routeId(item)),
                    padding: EdgeInsetsDirectional.only(
                      bottom: tokens.space.s3,
                    ),
                    child: _JournalRow(
                      item: item,
                      names: cardNames,
                      now: now,
                      onOpen: () => onOpen(item),
                      onFinish: onFinish,
                      onDelete: onDelete,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    };
    return TaroScaffold(
      bottomNavigationBar: listed ? banner : null,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              controls: listed,
              filters: filters,
              cardNames: cardNames,
              onType: onType,
              onSpread: onSpread,
              onClearCard: onClearCard,
              onSearch: onSearch,
            ),
          ),
          ...body,
        ],
      ),
    );
  }
}

/// The title, then (with [controls]) the search field and the filter chips.
/// The search field keeps its place in the tree across states, so typing
/// survives `searchEmpty`.
class _Header extends StatelessWidget {
  const _Header({
    required this.controls,
    required this.filters,
    required this.cardNames,
    required this.onType,
    required this.onSpread,
    required this.onClearCard,
    required this.onSearch,
  });

  final bool controls;
  final JournalFilters filters;
  final Map<CardId, String> cardNames;
  final ValueChanged<JournalTypeFilter> onType;
  final ValueChanged<SpreadId?> onSpread;
  final VoidCallback onClearCard;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final spread = filters.spreadId;
    final card = filters.cardId;
    return Padding(
      padding: EdgeInsetsDirectional.only(top: tokens.space.s9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: tokens.space.s4,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.journalTitle,
              style: tokens.typography.headline.copyWith(
                color: tokens.color.text.primary,
              ),
            ),
          ),
          if (controls) ...[
            TaroTextField(
              style: TaroTextFieldStyle.search,
              hintText: l10n.journalSearchHint,
              clearLabel: l10n.commonDismiss,
              textInputAction: TextInputAction.search,
              onChanged: onSearch,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: tokens.space.s3,
                children: [
                  for (final (type, label) in [
                    (JournalTypeFilter.all, l10n.journalFilterAll),
                    (JournalTypeFilter.readings, l10n.journalFilterReadings),
                    (
                      JournalTypeFilter.dailyCards,
                      l10n.journalFilterDailyCards,
                    ),
                    (
                      JournalTypeFilter.favourites,
                      l10n.journalFilterFavourites,
                    ),
                  ])
                    TaroChip.filter(
                      label: label,
                      selected: filters.type == type,
                      onSelected: (_) => onType(type),
                    ),
                  if (spread != null)
                    TaroChip.filter(
                      label: SpreadText.name(l10n, spread),
                      selected: true,
                      onSelected: (_) => onSpread(null),
                    ),
                  if (card != null)
                    TaroChip.filter(
                      label: l10n.commonItemSeparator(
                        l10n.journalFilterCard,
                        cardNames[card] ?? l10n.journalFilterAnyCard,
                      ),
                      selected: true,
                      onSelected: (_) => onClearCard(),
                    ),
                  TaroChip.suggestion(
                    label: l10n.journalFilterMore,
                    leading: Icon(Icons.tune, size: tokens.size.icon.sm),
                    onPressed: () => unawaited(_openSheet(context)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final picked = await TaroSheet.show<(SpreadId?,)>(
      context,
      builder: (_) => _FilterSheet(spread: filters.spreadId),
    );
    if (picked != null && picked.$1 != filters.spreadId) onSpread(picked.$1);
  }
}

/// The "Filter" sheet: the spread filter (01 §7.8). The "contains card"
/// filter comes from S17 and shows as a removable chip.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.spread});

  final SpreadId? spread;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SpreadId? _spread = widget.spread;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return TaroSheet(
      title: l10n.journalFilterMore,
      actions: [
        TaroButton.primary(
          label: l10n.journalFilterApply,
          expand: true,
          onPressed: () => Navigator.of(context).pop((_spread,)),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.journalFilterSpread,
              style: tokens.typography.label.copyWith(
                color: tokens.color.text.secondary,
              ),
            ),
          ),
          for (final spread in <SpreadId?>[null, ...kSpreadIds])
            TaroRadioTile<SpreadId?>(
              value: spread,
              groupValue: _spread,
              onChanged: (value) => setState(() => _spread = value),
              title: spread == null
                  ? l10n.journalFilterAnySpread
                  : SpreadText.name(l10n, spread),
            ),
        ],
      ),
    );
  }
}

/// One journal row: thumbs, title (question, else spread or card name),
/// meta ("Past · Present · Future · Sat 26 Sep"), favourite and note
/// glyphs, the Classic badge and, for a pending reading, "Finish reading".
/// A reading can be swiped away (or deleted through its semantics action);
/// both ask first.
class _JournalRow extends StatelessWidget {
  const _JournalRow({
    required this.item,
    required this.names,
    required this.now,
    required this.onOpen,
    required this.onFinish,
    required this.onDelete,
  });

  final JournalItem item;
  final Map<CardId, String> names;
  final DateTime Function() now;
  final VoidCallback onOpen;
  final ValueChanged<ReadingId> onFinish;
  final ValueChanged<ReadingId> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final status = JournalLabels.status(item);
    final day = _day(l10n, switch (item) {
      JournalReadingItem(:final reading) => reading.localDate,
      JournalDailyCardItem(:final card) => card.localDate,
    });
    final tile = switch (item) {
      JournalReadingItem(:final reading) => JournalEntryTile(
        title: JournalLabels.title(l10n, item),
        meta: switch (status) {
          JournalEntryTileStatus.pending ||
          JournalEntryTileStatus.failed => l10n.commonItemSeparator(
            SpreadText.name(l10n, reading.spreadId),
            day,
          ),
          _ => [
            for (final card in reading.cards.take(3))
              SpreadText.positionName(l10n, reading.spreadId, card.positionId),
            day,
          ].reduce(l10n.commonItemSeparator),
        },
        status: status,
        statusLabel: switch (status) {
          JournalEntryTileStatus.ai => null,
          _ => JournalLabels.statusLabel(l10n, status),
        },
        leading: _Thumbs(
          count: reading.cards.length.clamp(1, 3),
          faceDown: status == JournalEntryTileStatus.pending,
        ),
        hasNote: reading.note?.trim().isNotEmpty ?? false,
        noteLabel: l10n.journalEntryHasNote,
        favourite: reading.favourite,
        favouriteLabel: l10n.journalEntryFavourite,
        finishLabel: l10n.journalFinishReading,
        onFinish: status == JournalEntryTileStatus.pending
            ? () => onFinish(reading.id)
            : null,
        onTap: onOpen,
      ),
      JournalDailyCardItem(:final card) => JournalEntryTile(
        title: names[card.cardId] ?? l10n.commonDailyCard,
        meta: l10n.commonItemSeparator(l10n.commonDailyCard, day),
        status: status,
        leading: const _Thumbs(count: 1, faceDown: false),
        hasNote: card.note?.trim().isNotEmpty ?? false,
        noteLabel: l10n.journalEntryHasNote,
        favourite: card.favourite,
        favouriteLabel: l10n.journalEntryFavourite,
        onTap: onOpen,
      ),
    };
    final reading = switch (item) {
      JournalReadingItem(:final reading) => reading,
      JournalDailyCardItem() => null,
    };
    if (reading == null) return tile;
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.commonDelete): () =>
            onDelete(reading.id),
      },
      child: Dismissible(
        key: ValueKey('dismiss-${reading.id.value}'),
        direction: DismissDirection.endToStart,
        // The row leaves through the journal stream once deleted; the
        // swipe itself never removes it (so Cancel puts it back).
        confirmDismiss: (_) async {
          onDelete(reading.id);
          return false;
        },
        background: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.color.status.error,
            borderRadius: BorderRadius.circular(tokens.radius.lg),
          ),
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: tokens.space.s6),
              child: Icon(
                Icons.delete_outline,
                size: tokens.size.icon.md,
                color: tokens.color.text.onAccent,
              ),
            ),
          ),
        ),
        child: tile,
      ),
    );
  }

  String _day(TaroLocalizations l10n, String localDate) {
    final date = DateTime.parse(localDate);
    final today = now();
    final day = DateTime(today.year, today.month, today.day);
    return switch (day.difference(date).inDays) {
      0 => l10n.relativeToday,
      1 => l10n.relativeYesterday,
      _ => DateFormat.MMMEd(l10n.localeName).format(date),
    };
  }
}

/// 1–3 card thumbs (`space.6` wide, card aspect): face-down
/// (`color.card.back`) for a pending reading.
class _Thumbs extends StatelessWidget {
  const _Thumbs({required this.count, required this.faceDown});

  final int count;
  final bool faceDown;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final width = tokens.space.s6;
    return SizedBox(
      width: 3 * width + 2 * tokens.space.s1,
      child: Row(
        spacing: tokens.space.s1,
        children: [
          for (var i = 0; i < count; i++)
            Container(
              width: width,
              height: width / tokens.size.card.aspectRatio,
              decoration: BoxDecoration(
                color: faceDown
                    ? tokens.color.card.back
                    : tokens.color.bg.sunken,
                borderRadius: BorderRadius.circular(tokens.radius.xs),
                border: Border.all(
                  color: tokens.color.card.frame,
                  width: TaroStrokes.control,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The Patterns card (01 §7.8): the suit balance chart for the chosen
/// window, the most drawn card (→ S17), the major/minor and reversed
/// ratios, the 30/90-day toggle, and "Patterns in your draws, not
/// predictions."
class _PatternsCard extends StatelessWidget {
  const _PatternsCard({
    required this.patterns,
    required this.range,
    required this.names,
    required this.onRange,
    required this.onOpenCard,
  });

  final JournalPatterns patterns;
  final PatternsRange range;
  final Map<CardId, String> names;
  final ValueChanged<PatternsRange> onRange;
  final ValueChanged<CardId> onOpenCard;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final window = range == PatternsRange.d30
        ? patterns.last30
        : patterns.last90;
    final entries = [
      (TaroSuit.major, l10n.learnSectionMajor, window.major),
      (TaroSuit.wands, l10n.suitWands, window.suits[Suit.wands] ?? 0),
      (TaroSuit.cups, l10n.suitCups, window.suits[Suit.cups] ?? 0),
      (TaroSuit.swords, l10n.suitSwords, window.suits[Suit.swords] ?? 0),
      (
        TaroSuit.pentacles,
        l10n.suitPentacles,
        window.suits[Suit.pentacles] ?? 0,
      ),
    ];
    final legend = [
      for (final (_, name, count) in entries)
        l10n.journalPatternsLegendItem(name, count),
    ];
    final top = window.mostDrawn.firstOrNull;
    final caption = tokens.typography.caption.copyWith(
      color: c.text.secondary,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg.surface,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PatternsChart(
            title: l10n.journalPatternsTitle(window.days),
            trailing: l10n.journalPatternsCardsDrawn(window.cards),
            semanticsLabel: [
              l10n.journalPatternsTitle(window.days),
              l10n.journalPatternsSuitBalance,
              ...legend,
            ].reduce(l10n.commonItemSeparator),
            entries: [
              for (final (suit, name, count) in entries)
                PatternsChartEntry(
                  suit: suit,
                  label: l10n.journalPatternsLegendItem(name, count),
                  count: count,
                ),
            ],
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: tokens.space.s6,
              end: tokens.space.s6,
              bottom: tokens.space.s6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.space.s3,
              children: [
                if (top != null)
                  TaroButton.tertiary(
                    label: l10n.journalPatternsMostDrawn(
                      top.count,
                      names[top.cardId] ?? top.cardId.value,
                    ),
                    onPressed: () => onOpenCard(top.cardId),
                  ),
                if (window.cards > 0)
                  Text(
                    l10n.commonItemSeparator(
                      l10n.journalPatternsMajorMinor(
                        window.major,
                        window.minor,
                      ),
                      l10n.journalPatternsReversed(
                        (window.reversedRatio * 100).round(),
                      ),
                    ),
                    style: caption,
                  ),
                SegmentedChoice<PatternsRange>(
                  segments: [
                    TaroSegment(
                      value: PatternsRange.d30,
                      label: l10n.journalPatternsRange30,
                    ),
                    TaroSegment(
                      value: PatternsRange.d90,
                      label: l10n.journalPatternsRange90,
                    ),
                  ],
                  selected: range,
                  onChanged: onRange,
                ),
                Text(l10n.journalPatternsFootnote, style: caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The empty-journal picture: three face-down cards in a small fan
/// (decorative; `TaroEmptyView` excludes it from semantics).
class _EmptyIllustration extends StatelessWidget {
  const _EmptyIllustration();

  /// The tilt of the outer cards, in radians.
  static const double _tilt = 0.22;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final offset = tokens.space.s9;
    Widget card(double turn, double dx) => Transform.translate(
      offset: Offset(dx, 0),
      child: Transform.rotate(angle: turn, child: const TaroCardBack()),
    );
    return Stack(
      alignment: Alignment.center,
      children: [card(-_tilt, -offset), card(_tilt, offset), card(0, 0)],
    );
  }
}
