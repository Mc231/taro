import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taro/common/disclaimer_footer.dart';
import 'package:taro/common/duration_text.dart';
import 'package:taro/features/paywall/controller/paywall_catalog.dart';
import 'package:taro/l10n/generated/taro_localizations.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

/// Localised price helpers shared by S10 and S11 (04 §11: the store's price
/// string, a per-reading price derived from the store's raw price, never a
/// hard-coded amount).
abstract final class PaywallText {
  /// "$0.50" per reading of [offer], or `null` when it has no credits.
  static String? perReading(TaroLocalizations l10n, ProductOffer offer) {
    final value = offer.perReadingPrice;
    if (value == null) return null;
    return NumberFormat.simpleCurrency(
      locale: l10n.localeName,
      name: offer.currencyCode,
    ).format(value);
  }

  /// The neutral line of a pack purchase block (RC66).
  static String blocked(
    TaroLocalizations l10n,
    PurchasesBlockedReason reason,
  ) => switch (reason) {
    PurchasesBlockedReason.blocked => l10n.storePurchasesBlocked,
    PurchasesBlockedReason.refundDebt => l10n.storeRefundDebt,
    PurchasesBlockedReason.storeDisabled => l10n.storeDisabled,
  };

  /// The message of a failed purchase.
  static String failed(TaroLocalizations l10n, PurchaseErrorKind kind) =>
      switch (kind) {
        PurchaseErrorKind.alreadyClaimed => l10n.failurePurchaseAlreadyClaimed,
        PurchaseErrorKind.purchasesBlocked => l10n.failurePurchasesBlocked,
        PurchaseErrorKind.productUnavailable => l10n.failureProductUnavailable,
        PurchaseErrorKind.network => l10n.failureNetwork,
        PurchaseErrorKind.storeError ||
        PurchaseErrorKind.verifyRejected => l10n.failurePurchase,
        PurchaseErrorKind.unknown => l10n.failureUnexpected,
      };
}

/// The optional rewarded row of S10 / S11 (RC34, RC35, RC57): tappable only
/// when available; a cooldown or a no-fill greys it out with the reason; a
/// hidden option renders nothing. Never auto-shown.
class RewardedOfferRow extends StatelessWidget {
  /// Creates the row; [now] is the clock time the cooldown is measured from.
  const RewardedOfferRow({
    required this.option,
    required this.now,
    required this.onTap,
    super.key,
  });

  /// The evaluated option.
  final RewardedOption option;

  /// The current time (from the `Clock` port).
  final DateTime now;

  /// Opens S12.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    return switch (option) {
      RewardedOptionHidden() => const SizedBox.shrink(),
      RewardedOptionAvailable(:final amount, :final leftToday) => TaroListTile(
        title: l10n.rewardedOfferTitle(amount),
        subtitle: l10n.rewardedOfferLeft(leftToday),
        onTap: onTap,
        showChevron: true,
      ),
      RewardedOptionCoolingDown(:final until) => TaroListTile(
        title: l10n.rewardedOfferTitle(1),
        disabledReason: l10n.rewardedCoolingDown(
          formatCountdown(l10n, until.difference(now)),
        ),
      ),
      RewardedOptionCapped() => TaroListTile(
        title: l10n.rewardedOfferTitle(1),
        disabledReason: l10n.rewardedCapped,
      ),
      RewardedOptionNoFill() => TaroListTile(
        title: l10n.rewardedOfferTitle(1),
        disabledReason: l10n.rewardedNoFill,
      ),
    };
  }
}

/// The paywall footer (04 §11 "Legal" and "Consumable disclosure", 05
/// 3.1.1): the non-restorable line, Terms of Use and Privacy Policy links
/// and the short disclaimer.
class PaywallLegalFooter extends StatelessWidget {
  /// Creates the footer.
  const PaywallLegalFooter({
    required this.onTerms,
    required this.onPrivacy,
    super.key,
  });

  /// Opens the Terms of Use (S29 `terms`).
  final VoidCallback onTerms;

  /// Opens the Privacy Policy (S29 `privacy`).
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final l10n = TaroLocalizations.of(context);
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsetsDirectional.only(top: tokens.space.s7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.storeConsumableDisclosure,
            textAlign: TextAlign.center,
            style: tokens.typography.caption.copyWith(
              color: tokens.color.text.secondary,
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TaroButton.tertiary(label: l10n.commonTerms, onPressed: onTerms),
              TaroButton.tertiary(
                label: l10n.commonPrivacy,
                onPressed: onPrivacy,
              ),
            ],
          ),
          const DisclaimerFooter(centered: true),
        ],
      ),
    );
  }
}
