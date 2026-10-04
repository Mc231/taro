import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taro/app_state/balance_controller.dart';
import 'package:taro/common/balance_chip.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/common/duration_text.dart';
import 'package:taro/common/offline_banner.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/home/controller/home_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// Text scales above this switch to the stacked large-text layout (01
/// §12: the 200% layouts).
const double _largeTextThreshold = 1.5;

bool _largeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > _largeTextThreshold;

/// S05 Home, the "Today" tab (01 §7.1, §8.3; canvas `Today*`). The banner
/// is `BannerSlot('home')` below the scroll view and above the tab bar
/// (RC18, RC59); its own `bannerLoaded` / `bannerFailed` states collapse it
/// together with both `space.adGap` spacers, and `adsRemoved` drops it.
class HomeScreen extends ConsumerWidget {
  /// Creates the screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final clock = ref.watch(clockProvider);
    final listing = ref.watch(storeLinksProvider).listing;
    return HomeLayout(
      state: state,
      now: clock.now,
      onOpenStore: () => context.push(RoutePaths.store),
      onOpenDaily: () => context.push(RoutePaths.daily),
      onStartReading: () {
        unawaited(controller.dismissFirstRun());
        unawaited(context.push(RoutePaths.readingSpreads));
      },
      onOpenReading: (reading) => context.push(
        RoutePaths.reading(
          reading.id.value,
          classic: reading.status is ReadingStatusClassic,
        ),
      ),
      onDismissFirstRun: () => unawaited(controller.dismissFirstRun()),
      onDismissUpdate: controller.dismissUpdateNotice,
      onRetryVerification: () => unawaited(controller.retryVerification()),
      onUpdate: listing == null
          ? null
          : () => unawaited(ref.read(urlLauncherProvider).open(listing)),
      onFreeReset: () =>
          unawaited(ref.read(balanceProvider.notifier).refresh()),
    );
  }
}

/// The S05 layout for [state]; [now] (the `Clock`, device-local) picks the
/// date line, the greeting and the free-reading countdown.
class HomeLayout extends StatelessWidget {
  /// Creates the view.
  const HomeLayout({
    required this.state,
    required this.now,
    required this.onOpenStore,
    required this.onOpenDaily,
    required this.onStartReading,
    required this.onOpenReading,
    required this.onDismissFirstRun,
    required this.onDismissUpdate,
    required this.onRetryVerification,
    this.onUpdate,
    this.onFreeReset,
    super.key,
  });

  /// The controller state.
  final HomeState state;

  /// The current local time (the app's `Clock`).
  final DateTime Function() now;

  /// The balance chip: reading options (S11).
  final VoidCallback onOpenStore;

  /// The daily card tile (S13).
  final VoidCallback onOpenDaily;

  /// "Start a reading" (S06).
  final VoidCallback onStartReading;

  /// A recent reading (S09 / S32).
  final ValueChanged<Reading> onOpenReading;

  /// The first-run coachmark was dismissed.
  final VoidCallback onDismissFirstRun;

  /// The `updateAvailable` notice was dismissed.
  final VoidCallback onDismissUpdate;

  /// "Readings unavailable on this device" → Retry.
  final VoidCallback onRetryVerification;

  /// The `updateAvailable` notice's **Update** (opens the store listing);
  /// the action is hidden while `null`.
  final VoidCallback? onUpdate;

  /// The free-reading countdown reached `free.resetsAt` (re-sync).
  final VoidCallback? onFreeReset;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    return switch (state) {
      HomeLoading() => TaroScaffold(
        body: TaroLoadingView(
          semanticsLabel: l10n.commonLoading,
          layout: TaroLoadingLayout.cards,
        ),
      ),
      HomeContent(:final view) => _HomeContent(
        view: view,
        now: now,
        onOpenStore: onOpenStore,
        onOpenDaily: onOpenDaily,
        onStartReading: onStartReading,
        onOpenReading: onOpenReading,
        onDismissFirstRun: onDismissFirstRun,
        onDismissUpdate: onDismissUpdate,
        onRetryVerification: onRetryVerification,
        onUpdate: onUpdate,
        onFreeReset: onFreeReset,
      ),
    };
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({
    required this.view,
    required this.now,
    required this.onOpenStore,
    required this.onOpenDaily,
    required this.onStartReading,
    required this.onOpenReading,
    required this.onDismissFirstRun,
    required this.onDismissUpdate,
    required this.onRetryVerification,
    required this.onUpdate,
    required this.onFreeReset,
  });

  final HomeView view;
  final DateTime Function() now;
  final VoidCallback onOpenStore;
  final VoidCallback onOpenDaily;
  final VoidCallback onStartReading;
  final ValueChanged<Reading> onOpenReading;
  final VoidCallback onDismissFirstRun;
  final VoidCallback onDismissUpdate;
  final VoidCallback onRetryVerification;
  final VoidCallback? onUpdate;
  final VoidCallback? onFreeReset;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final GlobalKey _ctaKey = GlobalKey();
  final GlobalKey _ctaButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final now = widget.now;
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final today = now();
    final gap = SizedBox(height: tokens.space.s7);
    final balance = view.balance;
    final list = ListView(
      padding: EdgeInsetsDirectional.only(
        top: tokens.space.s9,
        bottom: tokens.space.s5,
      ),
      children: [
        _Header(
          date: DateFormat.MMMMEEEEd(l10n.localeName).format(today),
          greeting: _greeting(l10n, today.hour),
          chip: view.deviceUnverified
              ? null
              : _BalanceLiveRegion(
                  child: BalanceChip(onTap: widget.onOpenStore),
                ),
        ),
        if (view.variant == HomeBalanceVariant.zeroReadings &&
            balance != null &&
            !view.deviceUnverified) ...[
          SizedBox(height: tokens.space.s3),
          CountdownText(
            target: balance.free.resetsAt,
            now: now,
            format: (left) =>
                l10n.balanceNextFreeIn(formatCountdown(l10n, left)),
            reachedText: l10n.balanceSyncing,
            unknownText: l10n.balanceNextFreeTomorrow,
            onReached: widget.onFreeReset,
            style: tokens.typography.caption.copyWith(
              color: tokens.color.text.secondary,
            ),
          ),
        ],
        if (view.balanceStale && balance == null && !view.deviceUnverified) ...[
          SizedBox(height: tokens.space.s5),
          TaroInlineNotice(
            kind: TaroNoticeKind.info,
            title: l10n.offlineFirstLaunchNote,
          ),
        ],
        if (view.deviceUnverified) ...[
          SizedBox(height: tokens.space.s5),
          TaroInlineNotice(
            kind: TaroNoticeKind.warning,
            title: l10n.balanceUnavailable,
            body: l10n.errorDeviceUnverifiedBody,
            actions: [
              TaroButton.tertiary(
                label: l10n.commonRetry,
                onPressed: widget.onRetryVerification,
              ),
            ],
          ),
        ],
        if (view.updateAvailable) ...[
          SizedBox(height: tokens.space.s5),
          TaroInlineNotice(
            kind: TaroNoticeKind.info,
            title: l10n.homeUpdateAvailable,
            onDismiss: widget.onDismissUpdate,
            dismissLabel: l10n.commonDismiss,
            actions: [
              if (widget.onUpdate case final update?)
                TaroButton.tertiary(
                  label: l10n.homeUpdateAction,
                  onPressed: update,
                ),
            ],
          ),
        ],
        gap,
        _DailyTile(card: view.dailyCard, onOpen: widget.onOpenDaily),
        gap,
        _ReadingCta(
          key: _ctaKey,
          buttonKey: _ctaButtonKey,
          highlighted: view.firstRun,
          onStart: widget.onStartReading,
        ),
        if (view.recentReadings.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.space.s3,
            children: [
              SizedBox(height: tokens.space.s4),
              Semantics(
                header: true,
                child: Text(
                  l10n.homeRecent,
                  style: tokens.typography.titleSmall.copyWith(
                    color: tokens.color.text.primary,
                  ),
                ),
              ),
              for (final reading in view.recentReadings)
                _RecentRow(
                  reading: reading,
                  today: today,
                  onOpen: () => widget.onOpenReading(reading),
                ),
            ],
          ),
      ],
    );
    // First run: the scrim dims the screen except "Start a reading", which
    // the coachmark points at. There is no banner then (01 §8.3), and the
    // shell's tab bar is outside this layer, so the scrim covers neither.
    // Otherwise the banner sits in the scaffold's bottom bar slot: full
    // width, outside the scroll view, above the tab bar; `BannerSlot` owns
    // both `space.adGap` spacers so they collapse with it (RC18, RC59).
    return TaroCoachmarkLayer(
      visible: view.firstRun,
      // With large text the card is most of the screen: the coachmark
      // points at its button so the bubble has room above it (BUG-13).
      targetKey: _largeText(context) ? _ctaButtonKey : _ctaKey,
      coachmark: TaroCoachmark(
        title: view.variant == HomeBalanceVariant.freeAvailable
            ? l10n.homeCoachmarkTitle
            : l10n.homeStartReading,
        body: view.variant == HomeBalanceVariant.freeAvailable
            ? l10n.homeCoachmarkFreeBody
            : l10n.homeCoachmark,
        dismissLabel: l10n.homeCoachmarkDismiss,
        onDismiss: widget.onDismissFirstRun,
      ),
      child: TaroScaffold(
        topBanner: const OfflineBanner(),
        bottomNavigationBar: view.adsRemoved || view.firstRun
            ? null
            : const BannerSlot(BannerScreen.home),
        // Re-measure the hole while the list scrolls under the scrim.
        body: NotificationListener<ScrollUpdateNotification>(
          onNotification: (_) {
            if (view.firstRun) setState(() {});
            return false;
          },
          child: list,
        ),
      ),
    );
  }

  static String _greeting(TaroLocalizations l10n, int hour) => switch (hour) {
    < 12 => l10n.homeGreetingMorning,
    < 18 => l10n.homeGreetingAfternoon,
    _ => l10n.homeGreetingEvening,
  };
}

/// The date + greeting (one header node) and the balance chip at the end;
/// the chip wraps under the greeting at large text sizes.
class _Header extends StatelessWidget {
  const _Header({required this.date, required this.greeting, this.chip});

  final String date;
  final String greeting;
  final Widget? chip;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = tokens.color;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: tokens.space.s4,
      runSpacing: tokens.space.s4,
      children: [
        MergeSemantics(
          child: Semantics(
            header: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: tokens.space.s2,
              children: [
                Text(
                  date,
                  style: tokens.typography.caption.copyWith(
                    color: c.text.tertiary,
                  ),
                ),
                Text(
                  greeting,
                  style: tokens.typography.headline.copyWith(
                    color: c.text.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        ?chip,
      ],
    );
  }
}

/// Announces a changed balance politely (01 §12): "Balance updated: …".
class _BalanceLiveRegion extends ConsumerWidget {
  const _BalanceLiveRegion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<BalanceChipView>(balanceChipProvider, (previous, next) {
      if (previous?.balance == null ||
          next.balance == null ||
          next.sync != BalanceChipSync.synced) {
        return;
      }
      final l10n = TaroLocalizations.of(context);
      final label = next.label(l10n);
      if (label == previous!.label(l10n)) return;
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          l10n.balanceUpdated(label),
          Directionality.of(context),
        ),
      );
    });
    return child;
  }
}

/// The daily card tile: the face-down card and "Reveal card", or today's
/// card and "Open". The card stacks above its text at large text sizes.
class _DailyTile extends ConsumerWidget {
  const _DailyTile({required this.card, required this.onOpen});

  final DailyCard? card;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final drawn = card;
    final name = drawn == null
        ? null
        : ref.watch(cardTextProvider(drawn.cardId)).value?.name;
    final art = drawn == null
        ? const TaroCardBack()
        : TaroCardFace(
            image: CardArt.face(
              drawn.cardId,
              artSet:
                  ref.watch(deckArtSetProvider).value ?? CardArt.defaultArtSet,
            ),
            semanticsLabel: name ?? '',
            size: TaroCardSize.sm,
            reversed: drawn.reversed,
            reversedLabel: l10n.commonReversed,
          );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: tokens.space.s3,
      children: [
        Text(
          l10n.homeDailyOverline,
          style: tokens.typography.caption.copyWith(color: c.card.frame),
        ),
        Text(
          drawn == null ? l10n.homeDailyTitleNotDrawn : name ?? '',
          style: tokens.typography.cardName.copyWith(color: c.text.primary),
        ),
        Text(
          l10n.homeDailyCaption,
          style: tokens.typography.caption.copyWith(color: c.text.secondary),
        ),
        Text(
          drawn == null ? l10n.homeDailyReveal : l10n.homeDailyOpen,
          style: tokens.typography.label.copyWith(color: c.accent.primary),
        ),
      ],
    );
    final stacked = _largeText(context);
    return TaroSurfaceCard(
      onTap: onOpen,
      semanticsLabel: drawn == null
          ? l10n.homeDailySemanticsNotDrawn
          : l10n.homeDailySemanticsDrawn(name ?? ''),
      child: ExcludeSemantics(
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: tokens.space.s5,
                children: [art, text],
              )
            : Row(
                spacing: tokens.space.s5,
                children: [
                  art,
                  Expanded(child: text),
                ],
              ),
      ),
    );
  }
}

/// "Ask the cards a question" + "Start a reading" (the whole card taps).
class _ReadingCta extends StatelessWidget {
  const _ReadingCta({
    required this.highlighted,
    required this.onStart,
    required this.buttonKey,
    super.key,
  });

  final bool highlighted;
  final VoidCallback onStart;

  /// The key of "Start a reading" (the large-text coachmark target).
  final GlobalKey buttonKey;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final stretch = _largeText(context);
    return TaroSurfaceCard(
      raised: true,
      highlighted: highlighted,
      onTap: onStart,
      padding: EdgeInsetsDirectional.all(tokens.space.s6),
      child: Column(
        crossAxisAlignment: stretch
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.start,
        spacing: tokens.space.s4,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.homeReadingTitle,
              style: tokens.typography.cardName.copyWith(
                color: c.text.primary,
              ),
            ),
          ),
          Text(
            l10n.homeReadingBody,
            style: tokens.typography.body.copyWith(color: c.text.secondary),
          ),
          KeyedSubtree(
            key: buttonKey,
            child: TaroButton.primary(
              label: l10n.homeStartReading,
              expand: stretch,
              onPressed: onStart,
            ),
          ),
        ],
      ),
    );
  }
}

/// A recent reading (`JournalEntryTile`, shared with S14): up to three
/// card-outline thumbs, the title and "Past · Present · Future · Yesterday".
class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.reading,
    required this.today,
    required this.onOpen,
  });

  final Reading reading;
  final DateTime today;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final spread = reading.draw.spreadId;
    final positions = [
      for (final card in reading.draw.cards.take(3))
        SpreadText.positionName(l10n, spread, card.positionId),
    ];
    final meta = [...positions, _day(l10n)].reduce(l10n.commonItemSeparator);
    final question = reading.question?.trim();
    final title =
        reading.content?.title ??
        (question != null && question.isNotEmpty
            ? question
            : SpreadText.name(l10n, spread));
    final classic = reading.status is ReadingStatusClassic;
    final thumbWidth = tokens.space.s7;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.color.bg.surface,
        borderRadius: BorderRadius.circular(tokens.radius.md),
      ),
      child: JournalEntryTile(
        title: title,
        meta: meta,
        status: classic
            ? JournalEntryTileStatus.classic
            : JournalEntryTileStatus.ai,
        statusLabel: classic ? l10n.classicLabel : null,
        onTap: onOpen,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.space.s2,
          children: [
            for (final _ in positions)
              Container(
                width: thumbWidth,
                height: thumbWidth / tokens.size.card.aspectRatio,
                decoration: BoxDecoration(
                  color: tokens.color.card.back,
                  borderRadius: BorderRadius.circular(tokens.radius.xs),
                  border: Border.all(
                    color: tokens.color.card.frame,
                    width: TaroStrokes.control,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _day(TaroLocalizations l10n) {
    final date = DateTime.parse(reading.localDate);
    final day = DateTime(today.year, today.month, today.day);
    return switch (day.difference(date).inDays) {
      0 => l10n.relativeToday,
      1 => l10n.relativeYesterday,
      _ => DateFormat.MMMd(l10n.localeName).format(date),
    };
  }
}
