import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/balance_chip.dart';
import 'package:taro/common/banner_slot.dart';
import 'package:taro/common/card_art.dart';
import 'package:taro/common/offline_banner.dart';
import 'package:taro/common/spread_text.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/home/controller/home_controller.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// S05 Home, the "Today" tab (01 §7.1, §8.3). The banner is
/// `BannerSlot('home')` outside the scroll view (RC18, RC59); its own
/// `bannerLoaded` / `bannerFailed` states collapse it, and `adsRemoved`
/// drops it.
class HomeScreen extends ConsumerWidget {
  /// Creates the screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    return HomeLayout(
      state: state,
      hour: ref.watch(clockProvider).now().hour,
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
    );
  }
}

/// The S05 layout for [state]; [hour] (device-local, from the `Clock`)
/// picks the greeting.
class HomeLayout extends StatelessWidget {
  /// Creates the view.
  const HomeLayout({
    required this.state,
    required this.hour,
    required this.onOpenStore,
    required this.onOpenDaily,
    required this.onStartReading,
    required this.onOpenReading,
    required this.onDismissFirstRun,
    required this.onDismissUpdate,
    required this.onRetryVerification,
    super.key,
  });

  /// The controller state.
  final HomeState state;

  /// The local hour (0–23).
  final int hour;

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
      HomeContent(:final view) => TaroScaffold(
        topBanner: const OfflineBanner(),
        banner: view.adsRemoved ? null : const BannerSlot(BannerScreen.home),
        body: _content(context, view),
      ),
    };
  }

  String _greeting(TaroLocalizations l10n) => switch (hour) {
    < 12 => l10n.homeGreetingMorning,
    < 18 => l10n.homeGreetingAfternoon,
    _ => l10n.homeGreetingEvening,
  };

  Widget _content(BuildContext context, HomeView view) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final gap = SizedBox(height: tokens.space.s7);
    return ListView(
      padding: EdgeInsetsDirectional.only(
        top: tokens.space.s5,
        bottom: tokens.space.s7,
      ),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: tokens.space.s3,
          children: [
            Semantics(
              header: true,
              child: Text(
                _greeting(l10n),
                style: tokens.typography.headline,
              ),
            ),
            BalanceChip(onTap: onOpenStore),
          ],
        ),
        if (view.updateAvailable) ...[
          SizedBox(height: tokens.space.s5),
          TaroInlineNotice(
            kind: TaroNoticeKind.info,
            title: l10n.homeUpdateAvailable,
            onDismiss: onDismissUpdate,
            dismissLabel: l10n.commonDismiss,
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
                onPressed: onRetryVerification,
              ),
            ],
          ),
        ],
        gap,
        _DailyTile(card: view.dailyCard, onOpen: onOpenDaily),
        gap,
        if (view.firstRun) ...[
          TaroCoachmark(
            title: l10n.homeStartReading,
            body: l10n.homeCoachmark,
            dismissLabel: l10n.commonDismiss,
            onDismiss: onDismissFirstRun,
            arrow: TaroCoachmarkArrow.down,
          ),
          SizedBox(height: tokens.space.s3),
        ],
        TaroSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.space.s3,
            children: [
              Text(l10n.homeReadingTitle, style: tokens.typography.title),
              Text(
                l10n.homeReadingBody,
                style: tokens.typography.body.copyWith(
                  color: tokens.color.text.secondary,
                ),
              ),
              TaroButton.primary(
                label: l10n.homeStartReading,
                expand: true,
                onPressed: onStartReading,
              ),
            ],
          ),
        ),
        if (view.recentReadings.isNotEmpty) ...[
          gap,
          Semantics(
            header: true,
            child: Text(l10n.homeRecent, style: tokens.typography.titleSmall),
          ),
          for (final reading in view.recentReadings)
            TaroListTile(
              title:
                  reading.content?.title ??
                  SpreadText.name(l10n, reading.spreadId),
              subtitle: SpreadText.name(l10n, reading.spreadId),
              showChevron: true,
              onTap: () => onOpenReading(reading),
            ),
        ],
      ],
    );
  }
}

/// The daily card tile: tap-to-reveal back, or today's card.
class _DailyTile extends ConsumerWidget {
  const _DailyTile({required this.card, required this.onOpen});

  final DailyCard? card;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final drawn = card;
    final name = drawn == null
        ? null
        : ref.watch(cardTextProvider(drawn.cardId)).value?.name;
    return TaroSurfaceCard(
      onTap: onOpen,
      semanticsLabel: drawn == null
          ? l10n.homeDailySemanticsNotDrawn
          : l10n.homeDailySemanticsDrawn(name ?? ''),
      child: Row(
        spacing: tokens.space.s5,
        children: [
          ExcludeSemantics(
            child: drawn == null
                ? const TaroCardBack(size: TaroCardSize.thumb)
                : TaroCardFace(
                    image: CardArt.face(
                      drawn.cardId,
                      artSet:
                          ref.watch(deckArtSetProvider).value ??
                          CardArt.defaultArtSet,
                    ),
                    semanticsLabel: name ?? '',
                    size: TaroCardSize.thumb,
                    reversed: drawn.reversed,
                  ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: tokens.space.s2,
              children: [
                Text(
                  l10n.homeDailyOverline,
                  style: tokens.typography.caption.copyWith(
                    color: tokens.color.text.tertiary,
                  ),
                ),
                Text(
                  drawn == null ? l10n.homeDailyTitleNotDrawn : name ?? '',
                  style: tokens.typography.titleSmall,
                ),
                Text(
                  l10n.homeDailyCaption,
                  style: tokens.typography.caption.copyWith(
                    color: tokens.color.text.secondary,
                  ),
                ),
                ExcludeSemantics(
                  child: Text(
                    drawn == null ? l10n.homeDailyReveal : l10n.homeDailyOpen,
                    style: tokens.typography.label.copyWith(
                      color: tokens.color.accent.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
