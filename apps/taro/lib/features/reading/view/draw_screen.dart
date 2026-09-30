import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/app_state/balance_controller.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/features/reading/controller/draw_controller.dart';
import 'package:taro/features/reading/controller/draw_state.dart';
import 'package:taro/features/reading/controller/reading_session.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S08 entered from the Journal "Finish reading" / "Try again" (S14, S15:
/// `/reading/draw?resume=<readingId>`, RC49): starts the resume session for
/// the stored reading, then shows [DrawScreen]. A reading that cannot be
/// resumed (missing, no longer pending or failed) goes Home. Without
/// `resume` it is the plain [DrawScreen].
class DrawEntry extends ConsumerStatefulWidget {
  /// Creates the entry; [resumeId] is the `?resume=` reading ID.
  const DrawEntry({this.resumeId, super.key});

  /// The route's `?resume=` reading ID, or null.
  final String? resumeId;

  @override
  ConsumerState<DrawEntry> createState() => _DrawEntryState();
}

class _DrawEntryState extends ConsumerState<DrawEntry> {
  late bool _ready;

  @override
  void initState() {
    super.initState();
    final id = widget.resumeId;
    final current = ref.read(readingSessionProvider)?.resumeReadingId;
    _ready = id == null || id.isEmpty || current?.value == id;
    if (!_ready) unawaited(_resume(ReadingId(id!)));
  }

  Future<void> _resume(ReadingId id) async {
    final ok = await ref.read(readingSessionProvider.notifier).resume(id);
    if (!mounted) return;
    if (ok) {
      setState(() => _ready = true);
    } else {
      context.go(RoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const DrawScreen();
    return TaroScaffold(
      body: TaroLoadingView(
        semanticsLabel: TaroLocalizations.of(context).commonLoading,
        layout: TaroLoadingLayout.cards,
      ),
    );
  }
}

/// S08 Draw ritual (01 §7.3, §8.3; RC31, RC48–RC51): shuffle → pick →
/// reveal → keywords while the reading is written. Card faces appear only
/// for revealed cards (the hold was taken before S08 opened, RC50);
/// `holdLost` keeps every card face-down and opens S10. No banner.
class DrawScreen extends ConsumerWidget {
  /// Creates the screen.
  const DrawScreen({super.key});

  /// The number of card backs in the picking fan.
  static const int fanSize = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(drawControllerProvider, (previous, next) {
      if (previous?.runtimeType == next.runtimeType) return;
      _onEntered(context, ref, next);
    });
    final state = ref.watch(drawControllerProvider);
    if (state is DrawUnavailable) {
      // A stale route (no reading session): nothing to draw.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(RoutePaths.home);
      });
    }
    final controller = ref.read(drawControllerProvider.notifier);
    final view = _viewOf(state);
    final picked = view != null && view.placed > 0;
    final terminal = switch (state) {
      DrawCompleted() || DrawCrisis() || DrawReturnedToQuestion() => true,
      _ => false,
    };
    return DrawBackScope(
      confirm: picked && !terminal,
      child: DrawLayout(
        state: state,
        artSet: ref.watch(deckArtSetProvider).value ?? CardArt.defaultArtSet,
        onClose: () => context.go(RoutePaths.home),
        onShuffled: controller.finishShuffle,
        onPick: () => unawaited(controller.pick()),
        onDrawForMe: () => unawaited(controller.drawForMe()),
        onReveal: () => unawaited(controller.reveal()),
        onRevealAll: () => unawaited(controller.revealAll()),
        onRetry: () => unawaited(controller.retry()),
        onFinishLater: () => context.go(RoutePaths.journal),
        onOpenOptions: () => unawaited(_openOptions(context, ref)),
      ),
    );
  }

  static void _onEntered(BuildContext context, WidgetRef ref, DrawState next) {
    switch (next) {
      case DrawCompleted(:final reading):
        context.go(
          RoutePaths.reading(
            reading.id.value,
            classic: reading.status is ReadingStatusClassic,
          ),
        );
      case DrawCrisis():
        context.go(
          RoutePaths.helpCrisisFrom(CrisisResourcesOrigin.reading.wire),
        );
      case DrawReturnedToQuestion():
        if (context.canPop()) context.pop();
      case DrawHoldLost():
        unawaited(_openOptions(context, ref));
      default:
        break;
    }
  }

  /// S10 with the cards face-down; after a grant or purchase the same draw
  /// is resubmitted (RC48, RC50). Nothing starts while no reading is
  /// available.
  static Future<void> _openOptions(BuildContext context, WidgetRef ref) async {
    await TaroModals.outOfReadings<void>(
      context,
      source: OutOfReadingsSource.holdLost.wire,
    );
    if (!context.mounted) return;
    final canRead = ref.read(balanceProvider)?.canRead ?? false;
    if (canRead && ref.read(drawControllerProvider) is DrawHoldLost) {
      await ref.read(drawControllerProvider.notifier).resumeAfterHoldLost();
    }
  }
}

DrawView? _viewOf(DrawState state) => switch (state) {
  DrawUnavailable() || DrawPreparing() => null,
  DrawFailed(:final view) => view,
  DrawShuffling(:final view) ||
  DrawPicking(:final view) ||
  DrawRevealing(:final view) ||
  DrawAwaitingReading(:final view) ||
  DrawSlowReading(:final view) ||
  DrawTimeoutPolling(:final view) ||
  DrawGenerationFailed(:final view) ||
  DrawHoldLost(:final view) ||
  DrawDeliveryExpired(:final view) ||
  DrawCrisis(:final view) ||
  DrawReturnedToQuestion(:final view) ||
  DrawCompleted(:final view) => view,
};

/// The S08 layout for [state].
class DrawLayout extends StatelessWidget {
  /// Creates the view.
  const DrawLayout({
    required this.state,
    required this.onClose,
    required this.onShuffled,
    required this.onPick,
    required this.onDrawForMe,
    required this.onReveal,
    required this.onRevealAll,
    required this.onRetry,
    required this.onFinishLater,
    required this.onOpenOptions,
    this.artSet = CardArt.defaultArtSet,
    super.key,
  });

  /// The controller state.
  final DrawState state;

  /// The bundled art set.
  final String artSet;

  /// Close (Home).
  final VoidCallback onClose;

  /// "Shuffle" done: picking starts.
  final VoidCallback onShuffled;

  /// A card back was picked.
  final VoidCallback onPick;

  /// "Draw for me".
  final VoidCallback onDrawForMe;

  /// The next card was flipped.
  final VoidCallback onReveal;

  /// "Reveal all".
  final VoidCallback onRevealAll;

  /// "Try again" (same cards, RC49).
  final VoidCallback onRetry;

  /// "Save and finish later".
  final VoidCallback onFinishLater;

  /// Reading options (S10) after `holdLost`.
  final VoidCallback onOpenOptions;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final view = _viewOf(state);
    return TaroScaffold(
      appBar: TaroAppBar(
        leading: TaroAppBarLeading.close,
        leadingLabel: l10n.commonClose,
        onLeading: onClose,
        status: state is DrawPicking && view != null
            ? l10n.drawPickedProgress(view.placed, view.cardCount)
            : null,
      ),
      body: switch (state) {
        DrawFailed(:final failure) => FailureView.of(
          failure,
          secondaryAction: TaroButton.tertiary(
            label: l10n.commonBackToToday,
            onPressed: onClose,
          ),
        ),
        _ when view == null => TaroLoadingView(
          semanticsLabel: l10n.commonLoading,
          layout: TaroLoadingLayout.cards,
        ),
        DrawCrisis() ||
        DrawReturnedToQuestion() ||
        DrawCompleted() => TaroLoadingView(
          semanticsLabel: l10n.commonLoading,
          layout: TaroLoadingLayout.cards,
        ),
        _ => _ritual(context, view),
      },
    );
  }

  Widget _ritual(BuildContext context, DrawView view) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final (String title, String? body) = switch (state) {
      DrawShuffling() => (l10n.drawShuffleTitle, l10n.drawShuffleHint),
      DrawPicking() => (
        l10n.drawPickTitle(view.cardCount - view.placed),
        l10n.drawPickSubtitle,
      ),
      DrawRevealing() => (l10n.drawRevealTitle, l10n.drawRevealHint),
      DrawGenerationFailed() => (
        l10n.drawGenerationFailedTitle,
        l10n.drawGenerationFailedBody,
      ),
      DrawHoldLost() => (l10n.drawHoldLost, null),
      DrawDeliveryExpired() => (l10n.drawDeliveryExpired, null),
      _ => (l10n.drawAwaitingTitle, l10n.drawAwaitingBody),
    };
    final status = switch (state) {
      DrawSlowReading() => l10n.drawSlowReading,
      DrawTimeoutPolling() => l10n.drawTimeoutPolling,
      _ => null,
    };
    return ListView(
      padding: EdgeInsetsDirectional.only(bottom: tokens.space.s7),
      children: [
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(title, style: tokens.typography.headline),
        ),
        if (body != null) ...[
          SizedBox(height: tokens.space.s3),
          Text(
            body,
            style: tokens.typography.body.copyWith(
              color: tokens.color.text.secondary,
            ),
          ),
        ],
        if (status != null) ...[
          SizedBox(height: tokens.space.s3),
          Semantics(
            liveRegion: true,
            child: Text(status, style: tokens.typography.label),
          ),
        ],
        SizedBox(height: tokens.space.s7),
        _spread(context, view),
        if (state is DrawPicking || state is DrawShuffling) ...[
          SizedBox(height: tokens.space.s7),
          _fan(context, view),
        ],
        SizedBox(height: tokens.space.s7),
        ..._actions(context),
      ],
    );
  }

  /// The spread positions: face-down until revealed; every card stays
  /// face-down on `holdLost` (RC48).
  Widget _spread(BuildContext context, DrawView view) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final showFaces = switch (state) {
      DrawShuffling() || DrawPicking() || DrawHoldLost() => false,
      _ => true,
    };
    final keywords = switch (state) {
      DrawAwaitingReading() ||
      DrawSlowReading() ||
      DrawTimeoutPolling() => true,
      _ => false,
    };
    final revealing = state is DrawRevealing;
    return Wrap(
      spacing: tokens.space.s4,
      runSpacing: tokens.space.s4,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < view.cardCount; i++)
          _Slot(
            card: view.draw.cards[i],
            index: i,
            total: view.cardCount,
            placed: i < view.placed,
            faceUp: showFaces && i < view.revealed,
            showKeywords: keywords,
            artSet: artSet,
            onReveal: revealing && i == view.revealed ? onReveal : null,
            positionName: SpreadText.positionName(
              l10n,
              view.spread.id,
              view.draw.cards[i].positionId,
            ),
          ),
      ],
    );
  }

  Widget _fan(BuildContext context, DrawView view) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final picking = state is DrawPicking && !view.allPlaced;
    return Wrap(
      spacing: tokens.space.s2,
      runSpacing: tokens.space.s2,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < DrawScreen.fanSize; i++)
          TaroCardBack(
            size: TaroCardSize.thumb,
            semanticsLabel: l10n.drawCardBackSemantics(
              view.placed + 1,
              view.cardCount,
            ),
            enabled: picking,
            onTap: picking ? onPick : null,
          ),
      ],
    );
  }

  List<Widget> _actions(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    Widget primary(String label, VoidCallback onPressed) =>
        TaroButton.primary(label: label, expand: true, onPressed: onPressed);
    Widget secondary(String label, VoidCallback onPressed) => Padding(
      padding: EdgeInsetsDirectional.only(top: tokens.space.s3),
      child: TaroButton.secondary(
        label: label,
        expand: true,
        onPressed: onPressed,
      ),
    );
    return switch (state) {
      DrawShuffling() => [
        primary(l10n.drawShuffleButton, onShuffled),
        secondary(l10n.drawForMe, onDrawForMe),
      ],
      DrawPicking() => [secondary(l10n.drawForMe, onDrawForMe)],
      DrawRevealing() => [primary(l10n.drawRevealAll, onRevealAll)],
      DrawGenerationFailed() => [
        primary(l10n.commonRetry, onRetry),
        secondary(l10n.drawFinishLater, onFinishLater),
      ],
      DrawDeliveryExpired() => [primary(l10n.commonRetry, onRetry)],
      DrawHoldLost() => [primary(l10n.outOfReadingsGetMore, onOpenOptions)],
      _ => const [],
    };
  }
}

/// One spread position: an empty slot, a face-down card, or the face.
class _Slot extends ConsumerWidget {
  const _Slot({
    required this.card,
    required this.index,
    required this.total,
    required this.placed,
    required this.faceUp,
    required this.showKeywords,
    required this.artSet,
    required this.onReveal,
    required this.positionName,
  });

  final DrawnCard card;
  final int index;
  final int total;
  final bool placed;
  final bool faceUp;
  final bool showKeywords;
  final String artSet;
  final VoidCallback? onReveal;
  final String positionName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final Widget child;
    if (!placed) {
      child = Semantics(
        label: l10n.drawEmptySlotSemantics(index + 1, positionName),
        child: SizedBox(
          width: TaroCardSize.sm.widthIn(context),
          child: Text(
            positionName,
            textAlign: TextAlign.center,
            style: tokens.typography.caption,
          ),
        ),
      );
    } else if (!faceUp) {
      child = TaroCardBack(
        picked: true,
        semanticsLabel: l10n.drawCardBackSemantics(index + 1, total),
        enabled: onReveal != null,
        onTap: onReveal,
      );
    } else {
      final text = ref.watch(cardTextProvider(card.cardId)).value;
      final name = text?.name ?? '';
      final orientation = card.reversed
          ? l10n.commonReversed
          : l10n.commonUpright;
      child = Column(
        mainAxisSize: MainAxisSize.min,
        spacing: tokens.space.s2,
        children: [
          TaroCardFace(
            image: CardArt.face(card.cardId, artSet: artSet),
            semanticsLabel: l10n.drawCardSemantics(
              name,
              orientation,
              positionName,
            ),
            size: TaroCardSize.sm,
            reversed: card.reversed,
            reversedLabel: l10n.commonReversed,
            name: name,
          ),
          if (showKeywords && text != null)
            SizedBox(
              width: TaroCardSize.sm.widthIn(context),
              child: Text(
                text.keywords(reversed: card.reversed).take(3).join(' · '),
                textAlign: TextAlign.center,
                style: tokens.typography.caption.copyWith(
                  color: tokens.color.text.secondary,
                ),
              ),
            ),
        ],
      );
    }
    return child;
  }
}
