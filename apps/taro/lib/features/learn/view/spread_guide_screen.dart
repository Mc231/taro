import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/features/learn/controller/spread_guide_controller.dart';
import 'package:taro/features/learn/view/learn_top_bar.dart';
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

/// The S18 view for one [state]: the index of spreads (derived from the S06
/// rows) or one spread's detail with its layout diagram, positions, "When
/// to use it" and "Start this spread" (hidden when remote config disables
/// the spread; the detail stays readable).
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

  /// Opens a spread's detail (also previous / next spread).
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
    final state = this.state;
    if (state case SpreadGuideContent(:final spreads, :final selected?)) {
      final index = spreads.indexWhere((e) => e.spread.id == selected);
      if (index >= 0) return _detail(context, spreads, index);
    }
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
      SpreadGuideContent(:final spreads) => _index(context, spreads),
    };
    return TaroScaffold(
      appBar: TaroAppBar(leadingLabel: l10n.commonBack, onLeading: onBack),
      body: body,
    );
  }

  Widget _index(BuildContext context, List<SpreadGuideEntry> spreads) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return ListView(
      padding: EdgeInsetsDirectional.only(bottom: tokens.space.s7),
      children: [
        TaroLargeTitle(l10n.spreadGuideTitle),
        SizedBox(height: tokens.space.s6),
        for (final entry in spreads) ...[
          _IndexRow(entry: entry, onTap: () => onSelect(entry.spread.id)),
          SizedBox(height: tokens.space.s4),
        ],
      ],
    );
  }

  Widget _detail(
    BuildContext context,
    List<SpreadGuideEntry> spreads,
    int index,
  ) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final entry = spreads[index];
    final spread = entry.spread;
    final name = SpreadText.name(l10n, spread.id);
    final cards = l10n.spreadCardCount(spread.cardCount);
    final meta = SpreadText.meta(l10n, spread.id);
    final whenToUse = SpreadText.whenToUse(l10n, spread.id);
    final previous = index > 0 ? spreads[index - 1].spread.id : null;
    final next = index < spreads.length - 1
        ? spreads[index + 1].spread.id
        : null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    void swipe(DragEndDetails details) {
      final velocity = details.primaryVelocity ?? 0;
      if (velocity == 0) return;
      final forward = rtl ? velocity > 0 : velocity < 0;
      final target = forward ? next : previous;
      if (target != null) onSelect(target);
    }

    final metaLine = [
      cards,
      ?meta,
      l10n.spreadUsesOneReading,
    ].reduce(l10n.commonItemSeparator);
    final body = ListView(
      key: ValueKey('spread-detail-${spread.id.value}'),
      padding: EdgeInsetsDirectional.only(
        top: tokens.space.s3,
        bottom: tokens.space.s7,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            name,
            style: tokens.typography.headline.copyWith(color: c.text.primary),
          ),
        ),
        SizedBox(height: tokens.space.s2),
        Text(
          metaLine,
          style: tokens.typography.caption.copyWith(color: c.text.secondary),
        ),
        SizedBox(height: tokens.space.s6),
        SpreadDiagram(
          layout: _slotLayouts(spread),
          size: SpreadDiagramSize.large,
          semanticsLabel: l10n.spreadGuideDiagramSemantics(name, cards),
        ),
        SizedBox(height: tokens.space.s6),
        _Positions(spread: spread),
        if (whenToUse != null) ...[
          SizedBox(height: tokens.space.s6),
          Semantics(
            header: true,
            child: Text(
              l10n.spreadGuideWhenToUse,
              style: tokens.typography.titleSmall.copyWith(
                color: c.text.primary,
              ),
            ),
          ),
          SizedBox(height: tokens.space.s2),
          Text(
            whenToUse,
            style: tokens.typography.label.copyWith(color: c.text.secondary),
          ),
        ],
      ],
    );
    return TaroScaffold(
      appBar: LearnTopBar(
        caption: l10n.spreadGuidePager(index + 1, spreads.length),
        onBack: onBack,
        actions: [
          TaroIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            semanticsLabel: l10n.spreadGuidePrevious,
            onPressed: previous == null ? null : () => onSelect(previous),
          ),
          TaroIconButton(
            icon: Icons.arrow_forward_ios_rounded,
            semanticsLabel: l10n.spreadGuideNext,
            onPressed: next == null ? null : () => onSelect(next),
          ),
        ],
      ),
      bottom: entry.startable
          ? TaroButton.primary(
              label: l10n.spreadGuideStart,
              expand: true,
              onPressed: () => onStart(spread.id),
            )
          : null,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: swipe,
        child: AnimatedSwitcher(
          duration: context.motion.duration.base,
          child: body,
        ),
      ),
    );
  }
}

/// One index row: the mini diagram, the name and the meta (like S06).
class _IndexRow extends StatelessWidget {
  const _IndexRow({required this.entry, required this.onTap});

  final SpreadGuideEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final spread = entry.spread;
    final name = SpreadText.name(l10n, spread.id);
    final cards = l10n.spreadCardCount(spread.cardCount);
    final meta = SpreadText.meta(l10n, spread.id);
    return Semantics(
      key: ValueKey(spread.id),
      label: l10n.spreadRowSemantics(name, cards, meta ?? ''),
      button: true,
      excludeSemantics: true,
      child: TaroListTile(
        leading: ExcludeSemantics(
          child: SizedBox(
            width: tokens.size.card.sm,
            child: SpreadDiagram(
              layout: _slotLayouts(spread),
              semanticsLabel: name,
            ),
          ),
        ),
        title: name,
        subtitle: meta == null ? cards : l10n.commonItemSeparator(cards, meta),
        onTap: onTap,
        showChevron: true,
      ),
    );
  }
}

/// The numbered positions: "1 · Present · where you stand right now".
class _Positions extends StatelessWidget {
  const _Positions({required this.spread});

  final SpreadDefinition spread;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final positions = spread.positionsInOrder;
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: tokens.space.s4,
        vertical: tokens.space.s2,
      ),
      decoration: BoxDecoration(
        color: c.bg.surface,
        borderRadius: BorderRadius.circular(tokens.radius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < positions.length; i++) ...[
            if (i > 0)
              Divider(height: TaroStrokes.hairline, color: c.border.subtle),
            MergeSemantics(
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  vertical: tokens.space.s3,
                ),
                child: Row(
                  spacing: tokens.space.s4,
                  children: [
                    _NumberBubble(i + 1),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: SpreadText.positionName(
                                l10n,
                                spread.id,
                                positions[i].id,
                              ),
                              style: tokens.typography.label.copyWith(
                                color: c.text.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (SpreadText.positionDescription(
                                  l10n,
                                  spread.id,
                                  positions[i].id,
                                )
                                case final description?)
                              TextSpan(text: ' · $description'),
                          ],
                        ),
                        style: tokens.typography.label.copyWith(
                          color: c.text.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NumberBubble extends StatelessWidget {
  const _NumberBubble(this.number);

  final int number;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    return Container(
      constraints: BoxConstraints(
        minWidth: tokens.size.icon.md,
        minHeight: tokens.size.icon.md,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.accent.primary, width: TaroStrokes.control),
      ),
      child: Text(
        '$number',
        style: tokens.typography.caption.copyWith(color: c.text.primary),
      ),
    );
  }
}

/// The normalized slot layouts of [spread] in draw order (01 §10.2).
List<SpreadSlotLayout> _slotLayouts(SpreadDefinition spread) => [
  for (final p in spread.positionsInOrder)
    SpreadSlotLayout(
      x: p.x.clamp(0, 1).toDouble(),
      y: p.y.clamp(0, 1).toDouble(),
      rotationDeg: p.rotationDeg,
    ),
];
