import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/app_state/balance_controller.dart';
import 'package:taro/app_state/crisis_handoff.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/features/reading/controller/draw_controller.dart';
import 'package:taro/features/reading/controller/draw_state.dart';
import 'package:taro/features/reading/controller/reading_session.dart';
import 'package:taro/features/reading/view/draw_panes.dart';
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
    final view = drawViewOf(state);
    final picked = view != null && view.placed > 0;
    final terminal = switch (state) {
      DrawCompleted() || DrawCrisis() || DrawReturnedToQuestion() => true,
      _ => false,
    };
    final confirm = picked && !terminal;
    // Once every card is placed the pending reading is stored (Classic
    // readings are stored only when complete).
    final saved = view != null && view.allPlaced && !view.classic;
    return DrawBackScope(
      confirm: confirm,
      saved: saved,
      child: DrawLayout(
        state: state,
        artSet: ref.watch(deckArtSetProvider).value ?? CardArt.defaultArtSet,
        onClose: () => confirm
            ? unawaited(DrawBackScope.confirmLeave(context, saved: saved))
            : context.go(RoutePaths.home),
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
        final classic = reading.status is ReadingStatusClassic;
        if (!classic) {
          // `haptic.ready` and "Reading ready" (01 §8.3 S08 semantics).
          unawaited(TaroHaptics.ready(context));
          unawaited(
            SemanticsService.sendAnnouncement(
              View.of(context),
              TaroLocalizations.of(context).drawReadingReady,
              Directionality.of(context),
            ),
          );
        }
        ReadingResultBackScope.openFromDraw(
          context,
          RoutePaths.reading(reading.id.value, classic: classic),
        );
      case DrawCrisis(:final safety):
        // S27 shows the Worker's country-aware entries (01 §8.3 S27).
        ref.read(crisisHandoffProvider.notifier).offer(safety.crisisResources);
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

/// The [DrawView] of [state], if it has one.
DrawView? drawViewOf(DrawState state) => switch (state) {
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

/// The S08 layout for [state] (`Draw*.dc.html`). With
/// [DrawView.reducedMotion] (the in-app setting) the ritual runs with the
/// reduced-motion tokens, like the system setting.
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

  /// Close (asks first once a card is picked).
  final VoidCallback onClose;

  /// "I'm ready — draw" after the shuffle: picking starts.
  final VoidCallback onShuffled;

  /// A card was picked and flies to the next position.
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
    final view = drawViewOf(state);
    final status = switch (state) {
      DrawPicking() when view != null && !view.allPlaced =>
        l10n.drawPickedProgress(view.placed, view.cardCount),
      DrawRevealing() when view != null => l10n.drawRevealedProgress(
        view.revealed,
        view.cardCount,
      ),
      _ when view != null => SpreadText.name(l10n, view.spread.id),
      _ => null,
    };
    final loading = TaroLoadingView(
      semanticsLabel: l10n.commonLoading,
      layout: TaroLoadingLayout.cards,
    );
    final body = switch (state) {
      DrawFailed(:final failure) => FailureView.of(
        failure,
        secondaryAction: TaroButton.tertiary(
          label: l10n.commonBackToToday,
          onPressed: onClose,
        ),
      ),
      _ when view == null => loading,
      DrawCrisis() || DrawReturnedToQuestion() || DrawCompleted() => loading,
      DrawShuffling() => ShufflePane(
        view: view,
        artSet: artSet,
        onShuffled: onShuffled,
      ),
      DrawPicking() => PickPane(
        view: view,
        onPick: onPick,
        onDrawForMe: onDrawForMe,
      ),
      _ => ResultPane(
        state: state,
        view: view,
        artSet: artSet,
        onReveal: onReveal,
        onRevealAll: onRevealAll,
        onRetry: onRetry,
        onFinishLater: onFinishLater,
        onOpenOptions: onOpenOptions,
      ),
    };
    final ritual =
        body is ShufflePane || body is PickPane || body is ResultPane;
    final scaffold = TaroScaffold(
      padded: !ritual,
      appBar: TaroAppBar(
        leading: TaroAppBarLeading.close,
        leadingLabel: l10n.commonClose,
        onLeading: onClose,
        status: status,
      ),
      body: body,
    );
    if (view == null || !view.reducedMotion) return scaffold;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: scaffold,
    );
  }
}
