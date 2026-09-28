part of '../taro_analytics_event.dart';

/// Monetization events (04 §14, which owns names and params; RC3, RC68).
/// Products are always the alias ([AnalyticsProduct]), never the raw ID.
sealed class MonetizationEvent extends TaroAnalyticsEvent {
  const MonetizationEvent._() : super._();
}

/// `reading_gate_evaluated`: `ReadingGate` decided after Begin was tapped.
final class ReadingGateEvaluatedEvent extends MonetizationEvent {
  /// Creates the event.
  const ReadingGateEvaluatedEvent({
    required this.decision,
    required this.spread,
  }) : super._();

  /// The `GateDecision` variant.
  final GateDecisionKind decision;

  /// The spread.
  final AnalyticsSpread spread;

  @override
  String get eventName => 'reading_gate_evaluated';

  @override
  Map<String, Object> get parameters => {
    'decision': analyticsWire(decision),
    'spread_id': spread.wire,
  };
}

/// `free_reading_used`: the Worker committed a free reading.
final class FreeReadingUsedEvent extends MonetizationEvent {
  /// Creates the event.
  const FreeReadingUsedEvent({required this.bucket}) : super._();

  /// The bucket charged.
  final ChargeSource bucket;

  @override
  String get eventName => 'free_reading_used';

  @override
  Map<String, Object> get parameters => {'bucket': analyticsWire(bucket)};
}

/// `reading_credit_consumed`: the Worker committed a bonus or paid reading.
final class ReadingCreditConsumedEvent extends MonetizationEvent {
  /// Creates the event.
  const ReadingCreditConsumedEvent({required this.bucket}) : super._();

  /// The bucket charged.
  final ChargeSource bucket;

  @override
  String get eventName => 'reading_credit_consumed';

  @override
  Map<String, Object> get parameters => {'bucket': analyticsWire(bucket)};
}

/// `out_of_readings_viewed`: S10 was shown.
final class OutOfReadingsViewedEvent extends MonetizationEvent {
  /// Creates the event.
  const OutOfReadingsViewedEvent({
    required this.source,
    required this.rewardedAvailable,
    required this.freeResetInMin,
  }) : super._();

  /// What opened S10 (RC74).
  final OutOfReadingsSource source;

  /// Whether the rewarded option is offered (RC34).
  final bool rewardedAvailable;

  /// Minutes until `free.resetsAt`.
  final int freeResetInMin;

  @override
  String get eventName => 'out_of_readings_viewed';

  @override
  Map<String, Object> get parameters => {
    'source': source.wire,
    'rewarded_available': rewardedAvailable,
    'free_reset_in_min': freeResetInMin,
  };
}

/// `store_viewed`: S11 was shown.
final class StoreViewedEvent extends MonetizationEvent {
  /// Creates the event.
  const StoreViewedEvent({required this.source}) : super._();

  /// What opened S11.
  final StoreSource source;

  @override
  String get eventName => 'store_viewed';

  @override
  Map<String, Object> get parameters => {'source': source.wire};
}

/// `paywall_dismissed`: S10 or S11 was closed.
final class PaywallDismissedEvent extends MonetizationEvent {
  /// Creates the event.
  const PaywallDismissedEvent({
    required this.surface,
    required this.secondsVisible,
    required this.actionTaken,
  }) : super._();

  /// S10 or S11.
  final PaywallSurface surface;

  /// Seconds on screen.
  final int secondsVisible;

  /// What the user did.
  final PaywallAction actionTaken;

  @override
  String get eventName => 'paywall_dismissed';

  @override
  Map<String, Object> get parameters => {
    'surface': surface.wire,
    'seconds_visible': secondsVisible,
    'action_taken': actionTaken.wire,
  };
}

/// `iap_products_loaded`: the store product query finished.
final class IapProductsLoadedEvent extends MonetizationEvent {
  /// Creates the event.
  const IapProductsLoadedEvent({
    required this.count,
    required this.ms,
    required this.result,
  }) : super._();

  /// Products found.
  final int count;

  /// Query duration.
  final int ms;

  /// The query outcome.
  final IapLoadResult result;

  @override
  String get eventName => 'iap_products_loaded';

  @override
  Map<String, Object> get parameters => {
    'count': count,
    'ms': ms,
    'result': result.wire,
  };
}

/// `purchase_started`: Buy was tapped.
final class PurchaseStartedEvent extends MonetizationEvent {
  /// Creates the event.
  const PurchaseStartedEvent({
    required this.product,
    required this.priceMicros,
    required this.currency,
  }) : super._();

  /// The product alias.
  final AnalyticsProduct product;

  /// The store price in micros.
  final int priceMicros;

  /// The store currency.
  final AnalyticsCurrency currency;

  @override
  String get eventName => 'purchase_started';

  @override
  Map<String, Object> get parameters => {
    'product': product.wire,
    'price_micros': priceMicros,
    'currency': currency.wire,
  };
}

/// `purchase_pending`: the store reported a pending (deferred) purchase.
final class PurchasePendingEvent extends MonetizationEvent {
  /// Creates the event.
  const PurchasePendingEvent({required this.product}) : super._();

  /// The product alias.
  final AnalyticsProduct product;

  @override
  String get eventName => 'purchase_pending';

  @override
  Map<String, Object> get parameters => {'product': product.wire};
}

/// `purchase_cancelled`: the user cancelled the store sheet.
final class PurchaseCancelledEvent extends MonetizationEvent {
  /// Creates the event.
  const PurchaseCancelledEvent({required this.product, this.error}) : super._();

  /// The product alias.
  final AnalyticsProduct product;

  /// The store error, if any.
  final PurchaseErrorKind? error;

  @override
  String get eventName => 'purchase_cancelled';

  @override
  Map<String, Object> get parameters => {
    'product': product.wire,
    'error': ?error?.wire,
  };
}

/// `purchase_failed`: the store or the Worker verification failed.
final class PurchaseFailedEvent extends MonetizationEvent {
  /// Creates the event.
  const PurchaseFailedEvent({required this.product, this.error}) : super._();

  /// The product alias.
  final AnalyticsProduct product;

  /// What failed, if known.
  final PurchaseErrorKind? error;

  @override
  String get eventName => 'purchase_failed';

  @override
  Map<String, Object> get parameters => {
    'product': product.wire,
    'error': ?error?.wire,
  };
}

/// `purchase_verification_delayed`: verification was deferred (Worker
/// unreachable); the outbox retries.
final class PurchaseVerificationDelayedEvent extends MonetizationEvent {
  /// Creates the event.
  const PurchaseVerificationDelayedEvent({required this.product}) : super._();

  /// The product alias.
  final AnalyticsProduct product;

  @override
  String get eventName => 'purchase_verification_delayed';

  @override
  Map<String, Object> get parameters => {'product': product.wire};
}

/// `iap_verify_result`: the Worker answered a verify call.
final class IapVerifyResultEvent extends MonetizationEvent {
  /// Creates the event.
  const IapVerifyResultEvent({
    required this.product,
    required this.status,
    required this.ms,
    required this.attempt,
  }) : super._();

  /// The product alias.
  final AnalyticsProduct product;

  /// The verify outcome.
  final IapVerifyStatus status;

  /// Call duration.
  final int ms;

  /// 1-based attempt number.
  final int attempt;

  @override
  String get eventName => 'iap_verify_result';

  @override
  Map<String, Object> get parameters => {
    'product': product.wire,
    'status': status.wire,
    'ms': ms,
    'attempt': attempt,
  };
}

/// `iap_verify_stuck`: an outbox row is older than
/// `store.verifyRetryWindowHours`.
final class IapVerifyStuckEvent extends MonetizationEvent {
  /// Creates the event.
  const IapVerifyStuckEvent({required this.product, required this.hours})
    : super._();

  /// The product alias.
  final AnalyticsProduct product;

  /// Hours since the purchase.
  final int hours;

  @override
  String get eventName => 'iap_verify_stuck';

  @override
  Map<String, Object> get parameters => {
    'product': product.wire,
    'hours': hours,
  };
}

/// `purchase_completed`: the Worker answered `granted`. The only revenue
/// source of truth for analytics (04 §14).
final class PurchaseCompletedEvent extends MonetizationEvent {
  /// Creates the event.
  const PurchaseCompletedEvent({
    required this.product,
    required this.valueMicros,
    required this.currency,
    required this.credits,
    required this.isFirstPurchase,
  }) : super._();

  /// The product alias.
  final AnalyticsProduct product;

  /// The price paid in micros (param `value`).
  final int valueMicros;

  /// The store currency.
  final AnalyticsCurrency currency;

  /// Credits granted (0 for Remove Ads).
  final int credits;

  /// Whether this is the install's first purchase.
  final bool isFirstPurchase;

  @override
  String get eventName => 'purchase_completed';

  @override
  Map<String, Object> get parameters => {
    'product': product.wire,
    'value': valueMicros,
    'currency': currency.wire,
    'credits': credits,
    'is_first_purchase': isFirstPurchase,
  };
}

/// `restore_completed`: Restore purchases finished.
final class RestoreCompletedEvent extends MonetizationEvent {
  /// Creates the event.
  const RestoreCompletedEvent({required this.result}) : super._();

  /// What was restored.
  final RestoreResult result;

  @override
  String get eventName => 'restore_completed';

  @override
  Map<String, Object> get parameters => {'result': result.wire};
}

/// `remove_ads_changed`: the Remove Ads entitlement flipped.
final class RemoveAdsChangedEvent extends MonetizationEvent {
  /// Creates the event.
  const RemoveAdsChangedEvent({required this.owned, required this.source})
    : super._();

  /// Whether Remove Ads is now owned.
  final bool owned;

  /// What changed it.
  final RemoveAdsSource source;

  @override
  String get eventName => 'remove_ads_changed';

  @override
  Map<String, Object> get parameters => {
    'owned': owned,
    'source': source.wire,
  };
}

/// `rewarded_offer_shown`: the rewarded option was rendered.
final class RewardedOfferShownEvent extends MonetizationEvent {
  /// Creates the event.
  const RewardedOfferShownEvent({required this.eligible, this.ineligibleReason})
    : super._();

  /// Whether the offer can be taken.
  final bool eligible;

  /// Why not, when not eligible.
  final RewardUnavailableReason? ineligibleReason;

  @override
  String get eventName => 'rewarded_offer_shown';

  @override
  Map<String, Object> get parameters => {
    'eligible': eligible,
    if (ineligibleReason case final reason?)
      'ineligible_reason': analyticsWire(reason),
  };
}

/// `rewarded_offer_tapped`: the rewarded option was tapped (RC34).
final class RewardedOfferTappedEvent extends MonetizationEvent {
  /// Creates the event.
  const RewardedOfferTappedEvent({required this.source}) : super._();

  /// S10 or S11.
  final RewardedSource source;

  @override
  String get eventName => 'rewarded_offer_tapped';

  @override
  Map<String, Object> get parameters => {'source': source.wire};
}

/// `rewarded_ad_result`: the rewarded ad lifecycle ended.
final class RewardedAdResultEvent extends MonetizationEvent {
  /// Creates the event.
  const RewardedAdResultEvent({required this.result}) : super._();

  /// The ad outcome.
  final RewardedAdResult result;

  @override
  String get eventName => 'rewarded_ad_result';

  @override
  Map<String, Object> get parameters => {'result': result.wire};
}

/// `rewarded_grant_result`: polling for the SSV grant finished (RC57).
final class RewardedGrantResultEvent extends MonetizationEvent {
  /// Creates the event.
  const RewardedGrantResultEvent({required this.result, required this.waitMs})
    : super._();

  /// The grant outcome.
  final RewardedGrantResult result;

  /// Time from ad completion to the result.
  final int waitMs;

  @override
  String get eventName => 'rewarded_grant_result';

  @override
  Map<String, Object> get parameters => {
    'result': result.wire,
    'wait_ms': waitMs,
  };
}

/// `ad_banner_impression`: a banner was shown (RC18).
final class AdBannerImpressionEvent extends MonetizationEvent {
  /// Creates the event.
  const AdBannerImpressionEvent({required this.screenId}) : super._();

  /// The banner screen (`kBannerAllowList`).
  final BannerScreen screenId;

  @override
  String get eventName => 'ad_banner_impression';

  @override
  Map<String, Object> get parameters => {'screen_id': screenId.id};
}

/// `ad_banner_failed`: a banner failed to load.
final class AdBannerFailedEvent extends MonetizationEvent {
  /// Creates the event.
  const AdBannerFailedEvent({required this.screenId, this.errorCode})
    : super._();

  /// The banner screen (`kBannerAllowList`).
  final BannerScreen screenId;

  /// The AdMob error code, if any.
  final int? errorCode;

  @override
  String get eventName => 'ad_banner_failed';

  @override
  Map<String, Object> get parameters => {
    'screen_id': screenId.id,
    'error_code': ?errorCode,
  };
}

/// `config_value_clamped`: a remote-config value was clamped or replaced by
/// its default (RC8).
final class ConfigValueClampedEvent extends MonetizationEvent {
  /// Creates the event.
  const ConfigValueClampedEvent({required this.key}) : super._();

  /// The config key.
  final ConfigKey key;

  @override
  String get eventName => 'config_value_clamped';

  @override
  Map<String, Object> get parameters => {'key': key.wire};
}
