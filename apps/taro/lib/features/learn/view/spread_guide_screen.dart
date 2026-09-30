import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/features/learn/controller/spread_guide_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S18 Learn spreads guide (`/learn/spreads`) and spread detail
/// (`/learn/spreads/:spreadId`), 01 §7.9.
class SpreadGuideScreen extends ConsumerWidget {
  /// Creates the guide, opened on [initial] when the route names one.
  const SpreadGuideScreen({this.initial, super.key});

  /// The spread of the route, if any.
  final SpreadId? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = spreadGuideControllerProvider(initial);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    return SpreadGuideLayout(
      state: state,
      onSelect: (id) => unawaited(controller.select(id)),
      onBack: () {
        if (state case SpreadGuideContent(
          :final selected?,
        ) when selected != initial) {
          controller.closeDetail();
        } else {
          unawaited(Navigator.of(context).maybePop());
        }
      },
      onStart: (id) => context.go(RoutePaths.readingQuestion(id.value)),
      onRetry: () => ref.invalidate(provider),
    );
  }
}

/// The S18 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
class SpreadGuideLayout extends StatelessWidget {
  /// Creates the view.
  const SpreadGuideLayout({
    required this.state,
    required this.onSelect,
    required this.onBack,
    required this.onStart,
    required this.onRetry,
    super.key,
  });

  /// The controller state.
  final SpreadGuideState state;

  /// Opens a spread's detail.
  final ValueChanged<SpreadId> onSelect;

  /// Back (detail → list, list → Learn).
  final VoidCallback onBack;

  /// "Start this spread" (→ S07).
  final ValueChanged<SpreadId> onStart;

  /// Retries after a storage error.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final body = switch (state) {
      SpreadGuideLoading() => TaroLoadingView(
        semanticsLabel: l10n.commonLoading,
      ),
      SpreadGuideStorageError() => TaroErrorView(
        kind: TaroErrorKind.storage,
        title: l10n.errorStorageTitle,
        body: l10n.errorStorageBody,
        onRetry: onRetry,
        retryLabel: l10n.commonRetry,
      ),
      SpreadGuideContent(:final spreads, :final selected) => switch (spreads
          .where((e) => e.spread.id == selected)
          .firstOrNull) {
        final entry? => _detail(context, entry),
        null => ListView(
          children: [
            for (final entry in spreads)
              TaroListTile(
                key: ValueKey(entry.spread.id),
                title: SpreadText.name(l10n, entry.spread.id),
                subtitle: l10n.spreadCardCount(entry.spread.cardCount),
                onTap: () => onSelect(entry.spread.id),
                showChevron: true,
              ),
          ],
        ),
      },
    };
    return TaroScaffold(
      appBar: TaroAppBar(
        leadingLabel: l10n.commonBack,
        onLeading: onBack,
        title: l10n.spreadGuideTitle,
      ),
      body: Padding(
        padding: EdgeInsetsDirectional.only(top: tokens.space.s3),
        child: body,
      ),
    );
  }

  Widget _detail(BuildContext context, SpreadGuideEntry entry) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final spread = entry.spread;
    return ListView(
      children: [
        Semantics(
          header: true,
          child: Text(
            SpreadText.name(l10n, spread.id),
            style: tokens.typography.title,
          ),
        ),
        Text(
          l10n.spreadCardCount(spread.cardCount),
          style: tokens.typography.caption,
        ),
        SizedBox(height: tokens.space.s5),
        Text(l10n.spreadGuideWhenToUse, style: tokens.typography.titleSmall),
        Text(
          SpreadText.whenToUse(l10n, spread.id) ?? '',
          style: tokens.typography.body,
        ),
        SizedBox(height: tokens.space.s5),
        Text(l10n.spreadGuidePositions, style: tokens.typography.titleSmall),
        for (final position in spread.positionsInOrder)
          TaroListTile(
            title: SpreadText.positionName(l10n, spread.id, position.id),
            subtitle: SpreadText.positionDescription(
              l10n,
              spread.id,
              position.id,
            ),
          ),
        if (entry.startable)
          TaroButton.primary(
            label: l10n.spreadGuideStart,
            onPressed: () => onStart(spread.id),
          ),
      ],
    );
  }
}
