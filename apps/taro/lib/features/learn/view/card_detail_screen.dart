import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/features/learn/controller/card_detail_controller.dart';
import 'package:taro/features/learn/view/learn_labels.dart';
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
    return CardDetailLayout(
      state: state,
      onReversed: (reversed) =>
          unawaited(controller.setReversed(reversed: reversed)),
      onZoom: controller.zoom,
      onCloseZoom: controller.closeZoom,
      onCard: (id) => context.pushReplacement(RoutePaths.learnCard(id.value)),
      onJournal: () => context.go(RoutePaths.journal),
      onBack: () => Navigator.of(context).maybePop(),
      onRetry: () => ref.invalidate(provider),
    );
  }
}

/// The S17 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
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
    super.key,
  });

  /// The controller state.
  final CardDetailState state;

  /// The Upright / Reversed toggle.
  final ValueChanged<bool> onReversed;

  /// Opens the full-screen art.
  final VoidCallback onZoom;

  /// Closes the full-screen art.
  final VoidCallback onCloseZoom;

  /// Opens the previous or next card.
  final ValueChanged<CardId> onCard;

  /// "In your journal: drawn N times" (→ Journal).
  final VoidCallback onJournal;

  /// Back.
  final VoidCallback onBack;

  /// Retries after a storage error.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final body = switch (state) {
      CardDetailLoading() => TaroLoadingView(
        semanticsLabel: l10n.commonLoading,
        layout: TaroLoadingLayout.text,
      ),
      CardDetailStorageError() => TaroErrorView(
        kind: TaroErrorKind.storage,
        title: l10n.errorStorageTitle,
        body: l10n.errorStorageBody,
        onRetry: onRetry,
        retryLabel: l10n.commonRetry,
      ),
      CardDetailZoomed(:final view) => Semantics(
        label: l10n.cardZoomSemantics,
        child: TaroEmptyView(
          title: view.text.name,
          largeTitle: false,
          action: TaroButton.secondary(
            label: l10n.commonClose,
            onPressed: onCloseZoom,
          ),
        ),
      ),
      CardDetailUpright(:final view) => _detail(context, view, reversed: false),
      CardDetailReversed(:final view) => _detail(context, view, reversed: true),
    };
    return TaroScaffold(
      appBar: TaroAppBar(
        leadingLabel: l10n.commonBack,
        onLeading: onBack,
        title: l10n.learnTitle,
      ),
      body: body,
    );
  }

  Widget _detail(
    BuildContext context,
    CardDetailView view, {
    required bool reversed,
  }) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final text = view.text;
    final aspects = text.aspects;
    final previous = view.previous;
    final next = view.next;
    return ListView(
      children: [
        Semantics(
          header: true,
          child: Text(text.name, style: tokens.typography.title),
        ),
        Text(
          l10n.cardPosition(
            LearnLabels.sectionOf(l10n, view.card),
            view.position,
            view.sectionSize,
          ),
          style: tokens.typography.caption,
        ),
        TaroButton.tertiary(label: l10n.cardZoomOpen, onPressed: onZoom),
        SizedBox(height: tokens.space.s3),
        SegmentedChoice<bool>(
          segments: [
            TaroSegment(value: false, label: l10n.commonUpright),
            TaroSegment(value: true, label: l10n.commonReversed),
          ],
          selected: reversed,
          onChanged: onReversed,
        ),
        SizedBox(height: tokens.space.s5),
        _Section(
          title: l10n.cardKeywords,
          body: (reversed ? text.keywordsReversed : text.keywordsUpright).join(
            ', ',
          ),
        ),
        _Section(
          title: l10n.cardMeaning,
          body: reversed ? text.meaningReversed : text.meaningUpright,
        ),
        _Section(
          title: l10n.cardAspectRelationships,
          body: reversed
              ? aspects.relationshipsReversed
              : aspects.relationshipsUpright,
        ),
        _Section(
          title: l10n.cardAspectWork,
          body: reversed ? aspects.workReversed : aspects.workUpright,
        ),
        _Section(
          title: l10n.cardAspectGrowth,
          body: reversed ? aspects.growthReversed : aspects.growthUpright,
        ),
        _Section(
          title: l10n.cardReflectionQuestions,
          body: text.reflectionQuestions.join('\n'),
        ),
        TaroListTile(
          title: l10n.cardDrawnTimes(view.drawnCount),
          onTap: view.drawnCount > 0 ? onJournal : null,
          showChevron: view.drawnCount > 0,
        ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          children: [
            if (previous != null)
              TaroButton.tertiary(
                label: l10n.cardPreviousAction,
                onPressed: () => onCard(previous),
              ),
            if (next != null)
              TaroButton.tertiary(
                label: l10n.cardNextAction,
                onPressed: () => onCard(next),
              ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: tokens.space.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: tokens.typography.titleSmall),
          ),
          Text(body, style: tokens.typography.body),
        ],
      ),
    );
  }
}
