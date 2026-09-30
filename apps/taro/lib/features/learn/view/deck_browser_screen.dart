import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/features/learn/controller/deck_browser_controller.dart';
import 'package:taro/features/learn/view/learn_labels.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S16 Learn deck browser, tab "Learn" (01 §7.9): offline and ungated.
class DeckBrowserScreen extends ConsumerWidget {
  /// Creates the screen.
  const DeckBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deckBrowserControllerProvider);
    final controller = ref.read(deckBrowserControllerProvider.notifier);
    return DeckBrowserLayout(
      state: state,
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

/// The S16 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
class DeckBrowserLayout extends StatelessWidget {
  /// Creates the view.
  const DeckBrowserLayout({
    required this.state,
    required this.onSearch,
    required this.onCard,
    required this.onSpreads,
    required this.onAbout,
    required this.onRetry,
    super.key,
  });

  /// The controller state.
  final DeckBrowserState state;

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
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
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
      ),
      DeckBrowserStorageError() => TaroErrorView(
        kind: TaroErrorKind.storage,
        title: l10n.errorStorageTitle,
        body: l10n.errorStorageBody,
        onRetry: onRetry,
        retryLabel: l10n.commonRetry,
      ),
      DeckBrowserContent(:final sections) => ListView(
        children: [
          TaroListTile(
            title: l10n.learnSpreadsGuide,
            onTap: onSpreads,
            showChevron: true,
          ),
          TaroListTile(
            title: l10n.learnAbout,
            onTap: onAbout,
            showChevron: true,
          ),
          for (final section in sections) ...[
            Padding(
              padding: EdgeInsetsDirectional.only(
                top: tokens.space.s5,
                bottom: tokens.space.s3,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  LearnLabels.section(l10n, section.kind),
                  style: tokens.typography.label,
                ),
              ),
            ),
            for (final tile in section.tiles)
              TaroListTile(
                key: ValueKey(tile.card.id),
                title: tile.name,
                onTap: () => onCard(tile.card.id),
                showChevron: true,
              ),
          ],
        ],
      ),
    };
    return TaroScaffold(
      appBar: TaroAppBar(
        leading: TaroAppBarLeading.none,
        title: l10n.learnTitle,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (searchable)
            TaroTextField(
              style: TaroTextFieldStyle.search,
              hintText: l10n.learnSearchHint,
              clearLabel: l10n.commonDismiss,
              onChanged: onSearch,
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
