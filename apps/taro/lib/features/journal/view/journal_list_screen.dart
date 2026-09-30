import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/features/journal/controller/journal_list_controller.dart';
import 'package:taro/features/journal/view/journal_labels.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S14 Journal list, tab "Journal" (01 §7.8).
class JournalListScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const JournalListScreen({super.key});

  @override
  ConsumerState<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends ConsumerState<JournalListScreen> {
  JournalTypeFilter _type = JournalTypeFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journalListControllerProvider);
    final controller = ref.read(journalListControllerProvider.notifier);
    return JournalListLayout(
      state: state,
      type: _type,
      onType: (type) {
        setState(() => _type = type);
        unawaited(controller.setType(type));
      },
      onSearch: (text) => unawaited(controller.search(text)),
      onClearFilters: () {
        setState(() => _type = JournalTypeFilter.all);
        controller.clearFilters();
      },
      onOpen: (item) =>
          unawaited(context.push<void>(JournalLabels.location(item))),
      onFinish: (id) =>
          unawaited(context.push<void>(JournalLabels.finishLocation(id))),
      onUndo: () => unawaited(controller.undo()),
      onStartReading: () => context.go(RoutePaths.readingSpreads),
      onRetry: () => ref.invalidate(journalListControllerProvider),
    );
  }
}

/// The S14 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
class JournalListLayout extends StatelessWidget {
  /// Creates the view.
  const JournalListLayout({
    required this.state,
    required this.type,
    required this.onType,
    required this.onSearch,
    required this.onClearFilters,
    required this.onOpen,
    required this.onFinish,
    required this.onUndo,
    required this.onStartReading,
    required this.onRetry,
    super.key,
  });

  /// The controller state.
  final JournalListState state;

  /// The selected type chip.
  final JournalTypeFilter type;

  /// A type chip was tapped.
  final ValueChanged<JournalTypeFilter> onType;

  /// The search text changed.
  final ValueChanged<String> onSearch;

  /// "Clear filter".
  final VoidCallback onClearFilters;

  /// Opens an entry (S15).
  final ValueChanged<JournalItem> onOpen;

  /// "Finish reading" of a pending reading.
  final ValueChanged<ReadingId> onFinish;

  /// Undo of a deletion.
  final VoidCallback onUndo;

  /// "Start a reading" (empty journal).
  final VoidCallback onStartReading;

  /// Retries after a storage error.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final showControls = switch (state) {
      JournalListContent() ||
      JournalListFilteredEmpty() ||
      JournalListSearchEmpty() => true,
      _ => false,
    };
    final body = switch (state) {
      JournalListLoading() => TaroLoadingView(
        semanticsLabel: l10n.commonLoading,
      ),
      JournalListEmpty() => TaroEmptyView(
        title: l10n.journalEmptyTitle,
        body: l10n.journalEmptyBody,
        action: TaroButton.primary(
          label: l10n.homeStartReading,
          onPressed: onStartReading,
        ),
      ),
      JournalListFilteredEmpty() => TaroEmptyView(
        title: l10n.journalFilteredEmpty,
        largeTitle: false,
        action: TaroButton.secondary(
          label: l10n.journalClearFilter,
          onPressed: onClearFilters,
        ),
      ),
      JournalListSearchEmpty(:final query) => TaroEmptyView(
        title: l10n.journalSearchEmpty(query),
        largeTitle: false,
      ),
      JournalListStorageError() => TaroErrorView(
        kind: TaroErrorKind.storage,
        title: l10n.errorStorageTitle,
        body: l10n.errorStorageBody,
        onRetry: onRetry,
        retryLabel: l10n.commonRetry,
      ),
      JournalListContent(:final months, :final patterns, :final undoable) =>
        ListView(
          children: [
            if (patterns != null) _PatternsCard(patterns: patterns),
            for (final month in months) ...[
              Padding(
                padding: EdgeInsetsDirectional.only(
                  top: tokens.space.s5,
                  bottom: tokens.space.s3,
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    JournalLabels.month(l10n, month.yearMonth),
                    style: tokens.typography.label,
                  ),
                ),
              ),
              for (final item in month.items) _tile(l10n, item),
            ],
            if (undoable != null)
              TaroInlineNotice(
                kind: TaroNoticeKind.info,
                title: l10n.journalDeleted,
                liveRegion: true,
                actions: [
                  TaroButton.tertiary(
                    label: l10n.commonUndo,
                    onPressed: onUndo,
                  ),
                ],
              ),
          ],
        ),
    };
    return TaroScaffold(
      appBar: TaroAppBar(
        leading: TaroAppBarLeading.none,
        title: l10n.journalTitle,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showControls) ...[
            TaroTextField(
              style: TaroTextFieldStyle.search,
              hintText: l10n.journalSearchHint,
              clearLabel: l10n.commonDismiss,
              onChanged: onSearch,
            ),
            SizedBox(height: tokens.space.s3),
            Wrap(
              spacing: tokens.space.s3,
              children: [
                for (final (filter, label) in [
                  (JournalTypeFilter.all, l10n.journalFilterAll),
                  (JournalTypeFilter.readings, l10n.journalFilterReadings),
                  (JournalTypeFilter.dailyCards, l10n.journalFilterDailyCards),
                  (JournalTypeFilter.favourites, l10n.journalFilterFavourites),
                ])
                  TaroChip.filter(
                    label: label,
                    selected: type == filter,
                    onSelected: (_) => onType(filter),
                  ),
              ],
            ),
          ],
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _tile(TaroLocalizations l10n, JournalItem item) {
    final status = JournalLabels.status(item);
    final (hasNote, favourite) = switch (item) {
      JournalReadingItem(:final reading) => (
        reading.note?.isNotEmpty ?? false,
        reading.favourite,
      ),
      JournalDailyCardItem(:final card) => (
        card.note?.isNotEmpty ?? false,
        card.favourite,
      ),
    };
    final pendingId = switch (item) {
      JournalReadingItem(:final reading)
          when status == JournalEntryTileStatus.pending =>
        reading.id,
      _ => null,
    };
    return JournalEntryTile(
      key: ValueKey(JournalLabels.routeId(item)),
      title: JournalLabels.title(l10n, item),
      meta: JournalLabels.meta(l10n, item),
      status: status,
      statusLabel: JournalLabels.statusLabel(l10n, status),
      hasNote: hasNote,
      noteLabel: l10n.journalEntryHasNote,
      favourite: favourite,
      favouriteLabel: l10n.journalEntryFavourite,
      finishLabel: pendingId == null ? null : l10n.journalFinishReading,
      onFinish: pendingId == null ? null : () => onFinish(pendingId),
      onTap: () => onOpen(item),
    );
  }
}

class _PatternsCard extends StatelessWidget {
  const _PatternsCard({required this.patterns});

  final JournalPatterns patterns;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return TaroSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.journalPatternsTitle(30),
            style: tokens.typography.titleSmall,
          ),
          Text(l10n.journalPatternsCount(patterns.totalEntries)),
          Text(
            l10n.journalPatternsFootnote,
            style: tokens.typography.caption,
          ),
        ],
      ),
    );
  }
}
