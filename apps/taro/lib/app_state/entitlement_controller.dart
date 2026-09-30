import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

/// The Remove Banner Ads entitlement (MO7, RC80): the cached value at once
/// (no banner flash on launch), then every flip reported by the store.
final class EntitlementController extends Notifier<Entitlement> {
  @override
  Entitlement build() {
    final entitlement = ref.watch(removeAdsEntitlementProvider);
    final subscription = entitlement.changes.listen((_) {
      state = entitlement.current;
    });
    ref.onDispose(subscription.cancel);
    return entitlement.current;
  }
}

/// The app-wide entitlement (`entitlementProvider`, 02 §7).
final entitlementProvider =
    NotifierProvider<EntitlementController, Entitlement>(
      EntitlementController.new,
    );
