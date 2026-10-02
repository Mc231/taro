import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  /// The screen-reader sentence of a pack button: "10 readings for $4.99,
  /// $0.50 per reading" (+ ", best value" on the honest badge's pack).
  static String packSemantics(
    TaroLocalizations l10n,
    ProductOffer offer, {
    required bool bestValue,
  }) {
    final label = l10n.storePackSemantics(
      offer.credits,
      offer.price,
      perReading(l10n, offer) ?? offer.price,
    );
    return bestValue ? l10n.storePackSemanticsBestValue(label) : label;
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

/// The 40 dp `color.accent.subtle` icon tile at the start of an S10 / S11
/// option row.
class PaywallIconTile extends StatelessWidget {
  /// Creates the tile.
  const PaywallIconTile(this.icon, {super.key});

  /// The glyph (decorative; the row carries the label).
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ExcludeSemantics(
      child: Container(
        width: tokens.space.s9,
        height: tokens.space.s9,
        decoration: BoxDecoration(
          color: tokens.color.accent.subtle,
          borderRadius: BorderRadius.circular(tokens.radius.md),
        ),
        child: Icon(
          icon,
          size: tokens.size.icon.md,
          color: tokens.color.accent.primary,
        ),
      ),
    );
  }
}

/// The optional rewarded row of S10 / S11 (RC34, RC35, RC57): it says it is
/// an ad (04 §9.1), is tappable only when available, and stays visible but
/// disabled with its reason during a cooldown, after the daily cap or a
/// no-fill (announced with the row). A hidden option (config off, no ads
/// consent, a free reading left) renders nothing. Never auto-shown.
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
    const leading = PaywallIconTile(Icons.smart_display_outlined);
    return switch (option) {
      RewardedOptionHidden() => const SizedBox.shrink(),
      RewardedOptionAvailable(:final amount, :final leftToday) => TaroListTile(
        leading: leading,
        title: l10n.rewardedOfferTitle(amount),
        subtitle: l10n.rewardedOfferLeft(leftToday),
        onTap: onTap,
      ),
      RewardedOptionCoolingDown(:final until) => TaroListTile(
        leading: leading,
        title: l10n.rewardedOfferTitle(1),
        disabledReason: l10n.rewardedCoolingDown(
          formatCountdown(l10n, until.difference(now)),
        ),
      ),
      RewardedOptionCapped() => TaroListTile(
        leading: leading,
        title: l10n.rewardedOfferTitle(1),
        disabledReason: l10n.rewardedCapped,
      ),
      RewardedOptionNoFill() => TaroListTile(
        leading: leading,
        title: l10n.rewardedOfferTitle(1),
        disabledReason: l10n.rewardedNoFill,
      ),
    };
  }
}

/// A centred row of paywall text links (Restore · Terms · Privacy), each
/// with a 48 dp hit area; it wraps at large text.
class PaywallLinks extends StatelessWidget {
  /// Creates the row of `(label, onTap)` [links].
  const PaywallLinks({required this.links, super.key});

  /// The links in reading order.
  final List<(String, VoidCallback)> links;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: context.tokens.space.s3,
    children: [
      for (final (label, onTap) in links)
        TaroButton.tertiary(label: label, onPressed: onTap, expand: false),
    ],
  );
}

/// The paywall legal captions (04 §11 "Consumable disclosure", 05 §3
/// `disclaimerShort`), centred `type.caption` in `color.text.tertiary`.
class PaywallCaption extends StatelessWidget {
  /// Creates the caption.
  const PaywallCaption(this.text, {super.key});

  /// The localised text.
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: tokens.typography.caption.copyWith(
        color: tokens.color.text.tertiary,
      ),
    );
  }
}
