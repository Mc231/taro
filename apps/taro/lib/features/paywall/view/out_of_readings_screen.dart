import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
/// reading available (S07 then shows **Begin** enabled; nothing
/// auto-starts, RC58) and `false` on "Not now" / close / back.
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
    // Resolved while S12 is still on top (the rewarded grant): S12 shows
    // "Reading added" first; S10 closes once S12 is dismissed.
    ref.listen(provider, (_, next) {
      if (next is OutOfReadingsResolved &&
          (ModalRoute.of(context)?.isCurrent ?? true)) {
        Navigator.of(context).pop(true);
      }
    });
    void close() => Navigator.of(context).pop(false);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(controller.dismiss());
      },
      child: OutOfReadingsLayout(
        state: state,
        now: ref.read(clockProvider).now(),
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
        onTerms: () => unawaited(context.push<void>(RoutePaths.legal('terms'))),
        onPrivacy: () =>
            unawaited(context.push<void>(RoutePaths.legal('privacy'))),
      ),
    );
  }
}

/// The S10 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
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
    required this.onTerms,
    required this.onPrivacy,
    super.key,
  });

  /// The controller state.
  final OutOfReadingsState state;

  /// The clock time (for the rewarded cooldown).
  final DateTime now;

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

  /// Terms of Use.
  final VoidCallback onTerms;

  /// Privacy Policy.
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return switch (state) {
      OutOfReadingsResolved() => const SizedBox.shrink(),
      OutOfReadingsContent(
        :final rewarded,
        :final packs,
        :final lowTrustLimited,
        :final nextFreeIn,
        :final nextFreeAt,
      ) =>
        Material(
          color: tokens.color.bg.surfaceRaised,
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: tokens.layout.gutter,
              vertical: tokens.space.s5,
            ),
            children: [
              TaroAppBar(
                leading: TaroAppBarLeading.close,
                leadingLabel: l10n.commonClose,
                onLeading: onClose,
              ),
              Semantics(
                header: true,
                child: Text(
                  lowTrustLimited
                      ? l10n.outOfReadingsLowTrustTitle
                      : l10n.outOfReadingsTitle,
                  style: tokens.typography.title,
                ),
              ),
              SizedBox(height: tokens.space.s3),
              Text(l10n.outOfReadingsBody, style: tokens.typography.body),
              SizedBox(height: tokens.space.s5),
              Text(
                _nextFree(context, l10n, nextFreeIn, nextFreeAt),
                style: tokens.typography.titleSmall,
              ),
              SizedBox(height: tokens.space.s5),
              Text(l10n.outOfReadingsUntilThen, style: tokens.typography.label),
              RewardedOfferRow(option: rewarded, now: now, onTap: onRewarded),
              SizedBox(height: tokens.space.s3),
              _Packs(
                packs: packs,
                onGetMore: onGetMore,
                onRetry: onRetryPacks,
                onContactSupport: onContactSupport,
              ),
              TaroButton.tertiary(label: l10n.commonNotNow, onPressed: onClose),
              PaywallLegalFooter(onTerms: onTerms, onPrivacy: onPrivacy),
            ],
          ),
        ),
    };
  }

  static String _nextFree(
    BuildContext context,
    TaroLocalizations l10n,
    Duration? inDuration,
    DateTime? at,
  ) {
    if (inDuration == null) return l10n.balanceNextFreeTomorrow;
    final duration = formatCountdown(l10n, inDuration);
    if (at == null) return l10n.balanceNextFreeIn(duration);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(at),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return l10n.balanceNextFreeInAt(duration, time);
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
    return switch (packs) {
      PaywallPacksLoading() => ProductOfferTile.loading(
        loadingSemanticsLabel: l10n.commonLoading,
      ),
      PaywallPacksLoaded(:final catalog) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (catalog.packs.firstOrNull case final cheapest?)
            Text(
              l10n.outOfReadingsFromPrice(cheapest.price, cheapest.credits),
              style: context.tokens.typography.caption,
            ),
          TaroButton.secondary(
            label: l10n.outOfReadingsGetMore,
            onPressed: onGetMore,
          ),
        ],
      ),
      PaywallPacksUnavailable() => TaroInlineNotice(
        kind: TaroNoticeKind.info,
        title: l10n.storePricesUnavailable,
        actions: [
          TaroButton.tertiary(label: l10n.commonRetry, onPressed: onRetry),
        ],
      ),
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
