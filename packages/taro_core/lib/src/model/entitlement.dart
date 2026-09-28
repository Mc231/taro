import 'package:freezed_annotation/freezed_annotation.dart';

part 'entitlement.freezed.dart';

/// Ownership of a non-consumable (02 §4, 04 §6.4).
enum EntitlementState {
  /// Owned.
  owned,

  /// Not owned.
  notOwned,

  /// Not known yet (store not queried).
  unknown,
}

/// Where the entitlement state came from.
enum EntitlementSource {
  /// A store query or transaction.
  store,

  /// The local `entitlements` cache.
  cache,
}

/// The Remove Banner Ads entitlement (02 §4 `Entitlement`).
@freezed
abstract class Entitlement with _$Entitlement {
  /// Creates an entitlement.
  const factory Entitlement({
    /// Remove Banner Ads ownership.
    required EntitlementState removeAds,

    /// Where [removeAds] came from.
    required EntitlementSource source,

    /// When the store last confirmed it.
    DateTime? verifiedAt,
  }) = _Entitlement;

  const Entitlement._();

  /// Nothing known yet, from the cache.
  static const Entitlement unknown = Entitlement(
    removeAds: EntitlementState.unknown,
    source: EntitlementSource.cache,
  );

  /// Whether banners are removed. `unknown` behaves as not owned; a cached
  /// `owned` counts as owned (04 §6.4).
  bool get removesAds => removeAds == EntitlementState.owned;
}
