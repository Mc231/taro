import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/paywall/controller/store_controller.dart';
import 'package:taro/features/paywall/view/paywall_parts.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro/routing/routes.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// The S11 source of the `source` query value (`StoreSource.name`); the
/// Home balance chip when absent or unknown.
StoreSource storeSourceOf(String? name) =>
    StoreSource.values.where((s) => s.name == name).firstOrNull ??
    StoreSource.balanceChip;

/// S11 Store / paywall (04 §11): every pack is its own buy button (no
/// preselection), with close, Restore purchases, Terms, Privacy and the
/// non-restorable consumable line always visible.
class StoreScreen extends ConsumerWidget {
  /// Creates the store opened from [source].
  const StoreScreen({required this.source, super.key});

  /// Where S11 was opened from.
  final StoreSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = storeControllerProvider(source);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    ref.listen(provider, (_, next) {
      // A cancelled store sheet is a silent return (04 §11).
      if (next case StoreReady(phase: StorePhaseCancelled())) {
        controller.acknowledge();
      }
    });
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(controller.dismiss());
      },
      child: StoreLayout(
        state: state,
        now: ref.read(clockProvider).now(),
        onClose: () => Navigator.of(context).maybePop(),
        onBuy: (id) => unawaited(controller.buy(id)),
        onRestore: () => unawaited(controller.restore()),
        onRetry: () => unawaited(controller.retry()),
        onAcknowledge: controller.acknowledge,
        onContinue: () {
          controller.acknowledge();
          unawaited(Navigator.of(context).maybePop());
        },
        onRewarded: () async {
          if (await controller.tapRewarded() && context.mounted) {
            await TaroModals.rewarded<void>(context);
          }
        },
        onContactSupport: () => unawaited(context.push<void>(RoutePaths.help)),
        onTerms: () => unawaited(context.push<void>(RoutePaths.legal('terms'))),
        onPrivacy: () =>
            unawaited(context.push<void>(RoutePaths.legal('privacy'))),
      ),
    );
  }
}

/// The S11 skeleton for one [state] (Phase 13.5; restyled in Phase 16).
class StoreLayout extends StatelessWidget {
  /// Creates the view.
  const StoreLayout({
    required this.state,
    required this.now,
    required this.onClose,
    required this.onBuy,
    required this.onRestore,
    required this.onRetry,
    required this.onAcknowledge,
    required this.onContinue,
    required this.onRewarded,
    required this.onContactSupport,
    required this.onTerms,
    required this.onPrivacy,
    super.key,
  });

  /// The controller state.
  final StoreState state;

  /// The clock time (for the rewarded cooldown).
  final DateTime now;

  /// The close (X).
  final VoidCallback onClose;

  /// Buys one product.
  final ValueChanged<ProductId> onBuy;

  /// Restore purchases.
  final VoidCallback onRestore;

  /// Retries the product query.
  final VoidCallback onRetry;

  /// Clears a failed purchase notice.
  final VoidCallback onAcknowledge;

  /// "Continue" after a grant (back to S07; nothing auto-starts, RC58).
  final VoidCallback onContinue;

  /// The rewarded row.
  final VoidCallback onRewarded;

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
    final body = switch (state) {
      StoreLoading() => <Widget>[
        for (var i = 0; i < 3; i++)
          ProductOfferTile.loading(loadingSemanticsLabel: l10n.commonLoading),
      ],
      StoreUnavailable() => <Widget>[
        TaroEmptyView(
          title: l10n.storeUnavailable,
          largeTitle: false,
          action: TaroButton.secondary(
            label: l10n.commonRetry,
            onPressed: onRetry,
          ),
        ),
      ],
      StoreProductsFailed(:final kind) => <Widget>[
        TaroInlineNotice(
          kind: TaroNoticeKind.warning,
          title: l10n.storePricesUnavailable,
          body: FailureMessage.body(l10n, kind),
          actions: [
            TaroButton.tertiary(label: l10n.commonRetry, onPressed: onRetry),
          ],
        ),
      ],
      StoreReady(:final view, :final phase) => _ready(context, view, phase),
    };
    return TaroScaffold(
      appBar: TaroAppBar(
        leading: TaroAppBarLeading.close,
        leadingLabel: l10n.commonClose,
        onLeading: onClose,
        title: l10n.storeTitle,
      ),
      body: ListView(
        padding: EdgeInsetsDirectional.symmetric(vertical: tokens.space.s5),
        children: [
          Text(l10n.storeBody, style: tokens.typography.body),
          SizedBox(height: tokens.space.s5),
          ...body,
          SizedBox(height: tokens.space.s5),
          TaroButton.tertiary(label: l10n.storeRestore, onPressed: onRestore),
          PaywallLegalFooter(onTerms: onTerms, onPrivacy: onPrivacy),
        ],
      ),
    );
  }

  List<Widget> _ready(
    BuildContext context,
    StoreView view,
    StorePurchasePhase phase,
  ) {
    final l10n = TaroLocalizations.of(context);
    final catalog = view.catalog;
    final blocked = view.purchasesBlocked;
    ProductOfferState tileState(ProductId id) => switch (phase) {
      StorePhasePurchasing(:final productId) when productId == id =>
        ProductOfferState.purchasing,
      StorePhasePending(:final productId) when productId == id =>
        ProductOfferState.pending,
      _ => ProductOfferState.content,
    };
    final removeAds = catalog.removeAds;
    return [
      if (view.offline)
        TaroInlineNotice(
          kind: TaroNoticeKind.warning,
          title: l10n.storeOfflineNotice,
        ),
      ?_phaseNotice(l10n, phase),
      if (blocked != null)
        TaroInlineNotice(
          kind: TaroNoticeKind.info,
          title: PaywallText.blocked(l10n, blocked),
          actions: [
            TaroButton.tertiary(
              label: l10n.storeContactSupport,
              onPressed: onContactSupport,
            ),
          ],
        )
      else ...[
        if (view.paidBlocked)
          TaroInlineNotice(
            kind: TaroNoticeKind.info,
            title: l10n.storeRefundDebt,
          ),
        for (final offer in catalog.packs)
          ProductOfferTile(
            key: ValueKey(offer.productId),
            title: l10n.storePackTitle(offer.credits),
            price: offer.price,
            perReadingPrice: switch (PaywallText.perReading(l10n, offer)) {
              final per? => l10n.storePerReading(per),
              null => null,
            },
            bestValueLabel: catalog.bestValue == offer.productId
                ? l10n.storeLowestPerReading
                : null,
            purchaseSemanticsLabel: l10n.storePackSemantics(
              offer.credits,
              offer.price,
              PaywallText.perReading(l10n, offer) ?? offer.price,
            ),
            state: tileState(offer.productId),
            statusLabel: l10n.storePending,
            onBuy: () => onBuy(offer.productId),
          ),
      ],
      if (view.removeAdsOwned)
        TaroInlineNotice(
          kind: TaroNoticeKind.success,
          title: l10n.storeRemoveAdsOwned,
        )
      else if (removeAds != null)
        ProductOfferTile(
          key: ValueKey(removeAds.productId),
          title: l10n.storeRemoveAdsTitle,
          body: l10n.storeRemoveAdsBody,
          price: removeAds.price,
          purchaseSemanticsLabel: l10n.storeBuyPack(removeAds.price),
          state: tileState(removeAds.productId),
          statusLabel: l10n.storePending,
          onBuy: () => onBuy(removeAds.productId),
        ),
      RewardedOfferRow(option: view.rewarded, now: now, onTap: onRewarded),
    ];
  }

  Widget? _phaseNotice(TaroLocalizations l10n, StorePurchasePhase phase) =>
      switch (phase) {
        StorePhaseIdle() ||
        StorePhasePurchasing() ||
        StorePhasePending() ||
        StorePhaseCancelled() => null,
        StorePhaseVerifying() => TaroInlineNotice(
          kind: TaroNoticeKind.info,
          title: l10n.storeVerifying,
          liveRegion: true,
        ),
        StorePhaseVerificationDeferred() => TaroInlineNotice(
          kind: TaroNoticeKind.info,
          title: l10n.storeVerificationDelayed,
          liveRegion: true,
        ),
        StorePhaseGranted(:final credits) => TaroInlineNotice(
          kind: TaroNoticeKind.success,
          title: credits > 0
              ? l10n.storeGranted(credits)
              : l10n.storeRemoveAdsOwned,
          liveRegion: true,
          actions: [
            TaroButton.primary(
              label: l10n.commonContinue,
              onPressed: onContinue,
            ),
          ],
        ),
        StorePhaseFailed(:final reason, :final transferEligible) =>
          TaroInlineNotice(
            kind: TaroNoticeKind.warning,
            title: PaywallText.failed(l10n, reason),
            body: transferEligible ? l10n.storeTransferHint : null,
            liveRegion: true,
            onDismiss: onAcknowledge,
            dismissLabel: l10n.commonDismiss,
          ),
      };
}
