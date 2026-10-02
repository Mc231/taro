import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/app_state/balance_controller.dart';
import 'package:taro/common/duration_text.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/paywall/controller/out_of_readings_controller.dart';
import 'package:taro/features/paywall/controller/paywall_catalog.dart';
import 'package:taro/features/paywall/view/paywall_parts.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// The S10 source of the `source` query value (`OutOfReadingsSource.wire`);
/// the question gate when absent or unknown.
OutOfReadingsSource outOfReadingsSourceOf(String? wire) =>
    OutOfReadingsSource.values.where((s) => s.wire == wire).firstOrNull ??
    OutOfReadingsSource.questionGate;

/// S10 Out-of-readings sheet (MO13, 04 §11), opened by
/// `TaroModals.outOfReadings`. Pops `true` once a grant or purchase made a
/// reading available (S07 then shows **Begin** enabled with the same
/// question and the kept draw; nothing auto-starts, RC58, 01 §9.4) and
/// `false` on "Not now" / close / swipe / back.
class OutOfReadingsScreen extends ConsumerWidget {
  /// Creates the sheet for [source].
  const OutOfReadingsScreen({required this.source, super.key});

  /// Where the sheet was opened from.
  final OutOfReadingsSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = outOfReadingsControllerProvider(source);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final clock = ref.read(clockProvider);
    // Resolved while S12 is still on top (the rewarded grant): S12 shows
    // "Reading added" first; S10 closes once S12 is dismissed.
    ref.listen(provider, (_, next) {
      if (next is OutOfReadingsResolved &&
          (ModalRoute.of(context)?.isCurrent ?? true)) {
        Navigator.of(context).pop(true);
      }
    });
    void close() => Navigator.of(context).pop(false);
    void leaveTo(String location) {
      final router = GoRouter.of(context);
      close();
      router.go(location);
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(controller.dismiss());
      },
      child: OutOfReadingsLayout(
        state: state,
        now: clock.now,
        onClose: close,
        onRewarded: () async {
          if (await controller.tapRewarded() && context.mounted) {
            await TaroModals.rewarded<void>(context);
            if (context.mounted &&
                ref.read(provider) is OutOfReadingsResolved) {
              Navigator.of(context).pop(true);
            }
          }
        },
        onGetMore: () {
          if (!controller.tapGetMore()) return;
          final router = GoRouter.of(context);
          close();
          unawaited(
            router.push<void>(
              Uri(
                path: RoutePaths.store,
                queryParameters: {'source': StoreSource.outOfReadings.name},
              ).toString(),
            ),
          );
        },
        onRetryPacks: () => unawaited(controller.retryPacks()),
        onContactSupport: () => unawaited(context.push<void>(RoutePaths.help)),
        onDailyCard: () => leaveTo(RoutePaths.daily),
        onLearn: () => leaveTo(RoutePaths.learn),
        onFreeReset: () =>
            unawaited(ref.read(balanceProvider.notifier).refresh()),
        onTerms: () => unawaited(context.push<void>(RoutePaths.legal('terms'))),
        onPrivacy: () =>
            unawaited(context.push<void>(RoutePaths.legal('privacy'))),
      ),
    );
  }
}

/// The S10 sheet for one [state] (`OutOfReadings.dc.html`): title, the free
/// path countdown from server time, the rewarded and "Get more readings"
/// option rows, the consumable disclosure, the daily card / Learn links,
/// "Not now", Terms · Privacy and `disclaimerShort`. No banner (RC18).
class OutOfReadingsLayout extends StatelessWidget {
  /// Creates the view.
  const OutOfReadingsLayout({
    required this.state,
    required this.now,
    required this.onClose,
    required this.onRewarded,
    required this.onGetMore,
    required this.onRetryPacks,
    required this.onContactSupport,
    required this.onDailyCard,
    required this.onLearn,
    required this.onTerms,
    required this.onPrivacy,
    this.onFreeReset,
    super.key,
  });

  /// The controller state.
  final OutOfReadingsState state;

  /// The clock (the `Clock` port), for the countdown and the cooldown.
  final DateTime Function() now;

  /// Close / "Not now".
  final VoidCallback onClose;

  /// The rewarded row.
  final VoidCallback onRewarded;

  /// "Get more readings" (→ S11).
  final VoidCallback onGetMore;

  /// Retries the store listing.
  final VoidCallback onRetryPacks;

  /// "Contact support" under a purchase block.
  final VoidCallback onContactSupport;

  /// "Until then:" daily card (S13).
  final VoidCallback onDailyCard;

  /// "Until then:" Learn (S16).
  final VoidCallback onLearn;

  /// The free reset has passed (re-sync the balance).
  final VoidCallback? onFreeReset;

  /// Terms of Use.
  final VoidCallback onTerms;

  /// Privacy Policy.
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    if (state is! OutOfReadingsContent) return const SizedBox.shrink();
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    final c = tokens.color;
    final at = now();
    final nextFreeIn = state.nextFreeIn;
    final nextFreeAt = state.nextFreeAt;
    final resetTime = nextFreeAt == null
        ? null
        : MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(nextFreeAt),
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          );
    final gap = SizedBox(height: tokens.space.s6);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: l10n.outOfReadingsSemantics,
      child: TaroSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      state.lowTrustLimited
                          ? l10n.outOfReadingsLowTrustTitle
                          : l10n.outOfReadingsTitle,
                      style: tokens.typography.cardName.copyWith(
                        color: c.text.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: tokens.space.s3),
                TaroIconButton(
                  icon: Icons.close_rounded,
                  semanticsLabel: l10n.commonClose,
                  onPressed: onClose,
                ),
              ],
            ),
            SizedBox(height: tokens.space.s3),
            Text(
              l10n.outOfReadingsBody,
              style: tokens.typography.body.copyWith(color: c.text.secondary),
            ),
            SizedBox(height: tokens.space.s5),
            // The free path is visible in every combination (04 §11).
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.schedule_outlined,
                    size: tokens.size.icon.md,
                    color: c.accent.primary,
                  ),
                ),
                SizedBox(width: tokens.space.s4),
                Expanded(
                  child: CountdownText(
                    target: nextFreeIn == null ? null : at.add(nextFreeIn),
                    now: now,
                    format: (left) {
                      final duration = formatCountdown(l10n, left);
                      return resetTime == null
                          ? l10n.balanceNextFreeIn(duration)
                          : l10n.balanceNextFreeInAt(duration, resetTime);
                    },
                    reachedText: l10n.balanceSyncing,
                    unknownText: l10n.balanceNextFreeTomorrow,
                    onReached: onFreeReset,
                    style: tokens.typography.label.copyWith(
                      color: c.text.primary,
                    ),
                  ),
                ),
              ],
            ),
            gap,
            RewardedOfferRow(
              option: state.rewarded,
              now: at,
              onTap: onRewarded,
            ),
            if (state.rewarded is! RewardedOptionHidden)
              SizedBox(height: tokens.space.s3),
            _Packs(
              packs: state.packs,
              onGetMore: onGetMore,
              onRetry: onRetryPacks,
              onContactSupport: onContactSupport,
            ),
            SizedBox(height: tokens.space.s5),
            Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: tokens.space.s2,
              ),
              child: Text(
                l10n.storeConsumableDisclosure,
                style: tokens.typography.caption.copyWith(
                  color: c.text.tertiary,
                ),
              ),
            ),
            gap,
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: tokens.space.s4,
              runSpacing: tokens.space.s3,
              children: [
                Text(
                  l10n.outOfReadingsUntilThen,
                  style: tokens.typography.body.copyWith(
                    color: c.text.secondary,
                  ),
                ),
                TaroChip.suggestion(
                  label: l10n.commonDailyCard,
                  onPressed: onDailyCard,
                ),
                TaroChip.suggestion(
                  label: l10n.commonLearn,
                  onPressed: onLearn,
                ),
              ],
            ),
            gap,
            TaroButton.secondary(label: l10n.commonNotNow, onPressed: onClose),
            SizedBox(height: tokens.space.s5),
            PaywallLinks(
              links: [
                (l10n.commonTerms, onTerms),
                (l10n.commonPrivacy, onPrivacy),
              ],
            ),
            SizedBox(height: tokens.space.s3),
            PaywallCaption(l10n.disclaimerShort),
          ],
        ),
      ),
    );
  }
}

class _Packs extends StatelessWidget {
  const _Packs({
    required this.packs,
    required this.onGetMore,
    required this.onRetry,
    required this.onContactSupport,
  });

  final PaywallPacks packs;
  final VoidCallback onGetMore;
  final VoidCallback onRetry;
  final VoidCallback onContactSupport;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    const leading = PaywallIconTile(Icons.style_outlined);
    return switch (packs) {
      // Prices are still loading: S11 loads them itself.
      PaywallPacksLoading() => TaroListTile(
        leading: leading,
        title: l10n.outOfReadingsGetMore,
        subtitle: l10n.commonLoading,
        onTap: onGetMore,
      ),
      PaywallPacksLoaded(:final catalog) => TaroListTile(
        leading: leading,
        title: l10n.outOfReadingsGetMore,
        subtitle: switch (catalog.packs.firstOrNull) {
          final cheapest? => l10n.outOfReadingsFromPrice(
            cheapest.price,
            cheapest.credits,
          ),
          null => null,
        },
        onTap: onGetMore,
      ),
      PaywallPacksUnavailable() => TaroListTile(
        leading: leading,
        title: l10n.outOfReadingsGetMore,
        disabledReason: l10n.storePricesUnavailable,
        trailing: TaroButton.tertiary(
          label: l10n.commonRetry,
          onPressed: onRetry,
          expand: false,
        ),
      ),
      // Pack buttons hidden; free and rewarded stay (RC66).
      PaywallPacksBlocked(:final reason) => TaroInlineNotice(
        kind: TaroNoticeKind.info,
        title: PaywallText.blocked(l10n, reason),
        actions: [
          TaroButton.tertiary(
            label: l10n.storeContactSupport,
            onPressed: onContactSupport,
          ),
        ],
      ),
    };
  }
}
