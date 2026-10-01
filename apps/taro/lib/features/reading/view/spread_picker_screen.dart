import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/features/reading/controller/spread_picker_controller.dart';
import 'package:taro/features/reading/view/spread_slots.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S06 Spread picker (01 §8.3 `content`): the enabled spreads; each uses
/// one reading whatever its size. No banner (reading flow).
class SpreadPickerScreen extends ConsumerWidget {
  /// Creates the screen.
  const SpreadPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(spreadPickerControllerProvider);
    return SpreadPickerLayout(
      state: state,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(RoutePaths.home),
      onPick: (spread) => context.push(
        RoutePaths.readingQuestion(
          spread.id.value,
          source: ReadingFlowSource.home.wire,
        ),
      ),
      onHowTheyWork: () => context.push(RoutePaths.learnSpreads),
      onRetry: () => unawaited(
        ref.read(spreadPickerControllerProvider.notifier).retry(),
      ),
    );
  }
}

/// The S06 layout for [state].
class SpreadPickerLayout extends StatelessWidget {
  /// Creates the view.
  const SpreadPickerLayout({
    required this.state,
    required this.onBack,
    required this.onPick,
    required this.onHowTheyWork,
    required this.onRetry,
    super.key,
  });

  /// The controller state.
  final SpreadPickerState state;

  /// Leaves S06.
  final VoidCallback onBack;

  /// A spread was chosen (S07).
  final ValueChanged<SpreadDefinition> onPick;

  /// "How spreads work" (S18).
  final VoidCallback onHowTheyWork;

  /// Retry after `failed`.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return TaroScaffold(
      appBar: TaroAppBar(onLeading: onBack, leadingLabel: l10n.commonBack),
      body: switch (state) {
        SpreadPickerLoading() => TaroLoadingView(
          semanticsLabel: l10n.commonLoading,
        ),
        SpreadPickerFailed(:final failure) => FailureView.of(
          failure,
          onRetry: onRetry,
        ),
        SpreadPickerContent(:final spreads) => ListView(
          padding: EdgeInsetsDirectional.only(bottom: tokens.space.s7),
          children: [
            Semantics(
              header: true,
              child: Text(l10n.spreadsTitle, style: tokens.typography.headline),
            ),
            SizedBox(height: tokens.space.s2),
            Text(
              l10n.spreadsSubtitle,
              style: tokens.typography.label.copyWith(
                color: tokens.color.text.secondary,
              ),
            ),
            SizedBox(height: tokens.space.s6),
            for (final spread in spreads) ...[
              _row(context, spread),
              SizedBox(height: tokens.space.s4),
            ],
            SizedBox(height: tokens.space.s3),
            Center(
              child: TaroButton.tertiary(
                label: l10n.spreadsHowTheyWork,
                onPressed: onHowTheyWork,
              ),
            ),
          ],
        ),
      },
    );
  }

  Widget _row(BuildContext context, SpreadDefinition spread) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final name = SpreadText.name(l10n, spread.id);
    final cards = l10n.spreadCardCount(spread.cardCount);
    final meta = SpreadText.meta(l10n, spread.id);
    // One button per row ("Past · Present · Future. 3 cards. How a
    // situation is moving"); the diagram is decorative here.
    return Semantics(
      key: ValueKey('spread-${spread.id.value}'),
      label: l10n.spreadRowSemantics(name, cards, meta ?? ''),
      button: true,
      excludeSemantics: true,
      child: TaroListTile(
        leading: ExcludeSemantics(
          child: SizedBox(
            width: tokens.size.card.sm,
            child: SpreadDiagram(
              layout: spreadSlotLayouts(spread),
              semanticsLabel: name,
            ),
          ),
        ),
        title: name,
        subtitle: meta == null ? cards : l10n.commonItemSeparator(cards, meta),
        onTap: () => onPick(spread),
      ),
    );
  }
}
