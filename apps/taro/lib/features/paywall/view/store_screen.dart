import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taro/common/balance_chip.dart';
import 'package:taro/common/failure_message.dart';
import 'package:taro/di/providers.dart';
import 'package:taro/features/paywall/controller/paywall_catalog.dart';
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
///
/// A grant shows the "+N readings" toast; opened from S10 (over S07) the
/// store then closes, so S07 shows **Begin** enabled with the same question
/// and the kept draw, and nothing auto-starts (RC58, 01 §9.4).
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
    final l10n = TaroLocalizations.of(context);
    ref.listen(provider, (_, next) {
      switch (next) {
        // A cancelled store sheet is a silent return (04 §11).
        case StoreReady(phase: StorePhaseCancelled()):
          controller.acknowledge();
        case StoreReady(phase: StorePhaseGranted(:final credits)):
          TaroToast.show(
            context,
            message: credits > 0
                ? l10n.storeGranted(credits)
                : l10n.storeRemoveAdsOwned,
          );
          controller.acknowledge();
          if (credits > 0 && source == StoreSource.outOfReadings) {
            unawaited(Navigator.of(context).maybePop());
          }
        default:
          break;
      }
    });
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(controller.dismiss());
      },
      child: StoreLayout(
        state: state,
        balance: const BalanceChip(),
        // A chip that would wrap beside the close moves under it (01 §12).
        balanceInBody: !BalanceChip.fitsAppBar(
          context,
          ref.watch(balanceChipProvider),
        ),
        now: ref.read(clockProvider).now(),
        onClose: () => Navigator.of(context).maybePop(),
        onBuy: (id) => unawaited(controller.buy(id)),
        onRestore: () => unawaited(controller.restore()),
        onRetry: () => unawaited(controller.retry()),
        onAcknowledge: controller.acknowledge,
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

/// The S11 view for one [state] (`Store.dc.html`, `StoreLoading.dc.html`).
/// The header, close, Restore · Terms · Privacy, the consumable disclosure
/// and `disclaimerShort` render in every state. No banner (RC18), no
/// timers or attention-seeking motion (05 §9.5).
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
    required this.onRewarded,
    required this.onContactSupport,
    required this.onTerms,
    required this.onPrivacy,
    this.balance,
    this.balanceInBody = false,
    super.key,
  });

  /// The controller state.
  final StoreState state;

  /// The balance chip at the end of the top bar (`BalanceChip`).
  final Widget? balance;

  /// Whether [balance] sits at the start of the body instead of the top
  /// bar: a long translation or large text would wrap it next to the close.
  final bool balanceInBody;

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
    final c = tokens.color;
    final body = switch (state) {
      StoreLoading() => <Widget>[
        for (var i = 0; i < 4; i++)
          ProductOfferTile.loading(loadingSemanticsLabel: l10n.commonLoading),
      ],
      StoreUnavailable() => <Widget>[
        TaroInlineNotice(
          kind: TaroNoticeKind.warning,
          title: l10n.storeUnavailable,
          liveRegion: true,
          actions: [
            TaroButton.tertiary(label: l10n.commonRetry, onPressed: onRetry),
          ],
        ),
      ],
      StoreProductsFailed(:final kind) => <Widget>[
        TaroInlineNotice(
          kind: TaroNoticeKind.warning,
          title: l10n.storePricesUnavailable,
          body: FailureMessage.body(l10n, kind),
          liveRegion: true,
          actions: [
            TaroButton.tertiary(label: l10n.commonRetry, onPressed: onRetry),
          ],
        ),
      ],
      StoreReady(:final view, :final phase) => _ready(context, view, phase),
    };
    // The close stays visible outside the scroll view (rule 11).
    final topBar = Padding(
      padding: EdgeInsetsDirectional.only(top: tokens.space.s3),
      child: Row(
        children: [
          TaroIconButton(
            icon: Icons.close_rounded,
            semanticsLabel: l10n.commonClose,
            onPressed: onClose,
          ),
          // Expanded so a long translation wraps inside the pill instead of
          // overflowing the bar (01 §12).
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: balanceInBody ? null : balance,
            ),
          ),
        ],
      ),
    );
    final header = <Widget>[
      if (balanceInBody && balance != null) ...[
        Align(alignment: AlignmentDirectional.centerStart, child: balance),
        SizedBox(height: tokens.space.s5),
      ],
      Semantics(
        header: true,
        child: Text(
          l10n.storeTitle,
          style: tokens.typography.headline.copyWith(color: c.text.primary),
        ),
      ),
      SizedBox(height: tokens.space.s3),
      Text(
        l10n.storeBody,
        style: tokens.typography.label.copyWith(color: c.text.secondary),
      ),
    ];
    final footer = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaywallLinks(
          links: [
            (l10n.storeRestore, onRestore),
            (l10n.commonTerms, onTerms),
            (l10n.commonPrivacy, onPrivacy),
          ],
        ),
        SizedBox(height: tokens.space.s3),
        PaywallCaption(l10n.storeConsumableDisclosure),
        SizedBox(height: tokens.space.s2),
        PaywallCaption(l10n.disclaimerShort),
        SizedBox(height: tokens.space.s5),
      ],
    );
    return TaroScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          topBar,
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsetsDirectional.only(top: tokens.space.s5),
                  sliver: SliverList.list(
                    children: [
                      ...header,
                      for (final child in body) ...[
                        SizedBox(height: tokens.space.s5),
                        child,
                      ],
                      SizedBox(height: tokens.space.s8),
                    ],
                  ),
                ),
                // The footer sits at the bottom of a short page and follows the
                // content on a long one (200 % text).
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: AlignmentDirectional.bottomCenter,
                    child: footer,
                  ),
                ),
              ],
            ),
          ),
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
        // Pack buttons hidden; free, rewarded and restore stay (RC66).
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
                ? l10n.storeBestValue
                : null,
            purchaseSemanticsLabel: PaywallText.packSemantics(
              l10n,
              offer,
              bestValue: catalog.bestValue == offer.productId,
            ),
            state: tileState(offer.productId),
            statusLabel: l10n.storePending,
            onBuy: () => onBuy(offer.productId),
          ),
      ],
      if (view.rewarded is! RewardedOptionHidden)
        RewardedOfferRow(option: view.rewarded, now: now, onTap: onRewarded),
      if (view.removeAdsOwned)
        ProductOfferTile(
          key: const ValueKey('removeAdsOwned'),
          title: l10n.storeRemoveAdsTitle,
          price: '',
          purchaseSemanticsLabel: l10n.storeRemoveAdsOwned,
          onBuy: null,
          state: ProductOfferState.owned,
          statusLabel: l10n.storeRemoveAdsOwned,
        )
      else if (removeAds != null)
        ProductOfferTile(
          key: ValueKey(removeAds.productId),
          title: l10n.storeRemoveAdsTitle,
          body: l10n.storeRemoveAdsBody,
          price: removeAds.price,
          outlined: true,
          purchaseSemanticsLabel: l10n.storeBuyPack(removeAds.price),
          state: tileState(removeAds.productId),
          statusLabel: l10n.storePending,
          onBuy: () => onBuy(removeAds.productId),
        ),
    ];
  }

  Widget? _phaseNotice(TaroLocalizations l10n, StorePurchasePhase phase) =>
      switch (phase) {
        StorePhaseIdle() ||
        StorePhasePurchasing() ||
        StorePhasePending() ||
        StorePhaseCancelled() ||
        // The toast announces it (StoreScreen).
        StorePhaseGranted() => null,
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
