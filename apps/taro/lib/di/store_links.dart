import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

/// The App Store ID of Taro (App Store Connect → App Information → Apple
/// ID). Empty until the app record exists: the iOS store links are then
/// unavailable and their buttons are disabled.
const String kAppStoreId = '';

/// The Play Store package (the release `applicationId`, without the dev or
/// staging suffix).
const String kPlayPackage = 'com.vshyrochuk.taro';

/// This platform's store links: the listing (S30 "Update", S05
/// `updateAvailable`) and the review page (S20 "Rate Taro"). `null` when
/// unknown (iOS before [kAppStoreId] is set).
@immutable
final class StoreLinks {
  /// Creates the links.
  const StoreLinks({required this.listing, required this.review});

  /// The links of [platform] with the App Store ID [appStoreId].
  factory StoreLinks.of(
    AppPlatform platform, {
    String appStoreId = kAppStoreId,
  }) {
    switch (platform) {
      case AppPlatform.ios:
        if (appStoreId.isEmpty) {
          return const StoreLinks(listing: null, review: null);
        }
        final listing = Uri.https('apps.apple.com', '/app/id$appStoreId');
        return StoreLinks(
          listing: listing,
          review: listing.replace(queryParameters: {'action': 'write-review'}),
        );
      case AppPlatform.android:
        final listing = Uri.https('play.google.com', '/store/apps/details', {
          'id': kPlayPackage,
        });
        return StoreLinks(listing: listing, review: listing);
    }
  }

  /// The store listing.
  final Uri? listing;

  /// Where to write a review.
  final Uri? review;
}

/// The [StoreLinks] of this platform.
final storeLinksProvider = Provider<StoreLinks>(
  (ref) => StoreLinks.of(ref.watch(appInfoProvider).platform),
);
