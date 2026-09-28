import 'package:taro_core/src/model/entitlement.dart';
import 'package:taro_core/src/result/result.dart';

/// The Remove Banner Ads entitlement cache (`entitlements`, 04 §6.4).
/// Kept by "Delete all data" (RC37).
abstract interface class EntitlementCache {
  /// The cached entitlement (`Entitlement.unknown` when empty).
  Entitlement read();

  /// Stores [entitlement].
  Future<Result<void>> write(Entitlement entitlement);
}
