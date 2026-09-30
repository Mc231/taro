import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/app_state/balance_controller.dart';
import 'package:taro/app_state/entitlement_controller.dart';
import 'package:taro/app_state/remote_config_controller.dart';
import 'package:taro/app_state/sync_coordinator.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'home_controller.freezed.dart';

/// Secure-storage keys of the S05 one-time notices (GLOSSARY §12).
abstract final class HomeNoticeKeys {
  /// Set once the first-run coachmark was dismissed.
  static const String firstRunDone = 'taro.home_first_run_done';

  /// The `app.recommendedVersion` whose `updateAvailable` notice was shown
  /// (at most once per version, RC73).
  static const String updateNoticeVersion = 'taro.update_notice_version';
}

/// The S05 balance chip variant (01 §8.3 `content` variants).
enum HomeBalanceVariant {
  /// No balance yet (first launch offline).
  unknown,

  /// `free.remaining > 0`.
  freeAvailable,

  /// Free used, purchased/earned readings left.
  freeUsedWithCredits,

  /// Nothing left today.
  zeroReadings,
}

/// Everything S05 renders (01 §7.1, §8.3). The flags combine, so they are
/// fields of `content` rather than separate states.
@freezed
abstract class HomeView with _$HomeView {
  /// Creates a view.
  const factory HomeView({
    required CreditBalance? balance,
    required HomeBalanceVariant variant,
    required bool firstRun,
    required bool balanceStale,
    required bool deviceUnverified,
    required bool adsRemoved,
    required bool updateAvailable,
    DailyCard? dailyCard,
    @Default(<Reading>[]) List<Reading> recentReadings,
  }) = _HomeView;

  const HomeView._();

  /// `dailyCardDrawn` (else `dailyCardNotDrawn`).
  bool get dailyCardDrawn => dailyCard != null;
}

/// S05 Home (01 §8.3). Banner `bannerLoaded` / `bannerFailed` are the
/// `BannerSlot('home')` widget's own states; `adsRemoved` is here.
@freezed
sealed class HomeState with _$HomeState {
  /// The first frame's local data is loading.
  const factory HomeState.loading() = HomeLoading;

  /// The Today tab.
  const factory HomeState.content(HomeView view) = HomeContent;
}

/// Local facts S05 reads once per visit.
@freezed
abstract class HomeFlags with _$HomeFlags {
  /// Creates the flags.
  const factory HomeFlags({
    required bool firstRunDone,
    required String? updateNoticeVersion,
    required bool registered,
  }) = _HomeFlags;
}

/// Process-wide memory of S05's one-time effects (Riverpod 3 recreates a
/// notifier on rebuild, so it cannot hold them).
final class HomeMemo {
  /// Events already logged this process.
  final Set<String> logged = {};

  /// The coachmark was dismissed this process.
  bool firstRunDismissed = false;

  /// The update notice was dismissed this process.
  bool updateDismissed = false;
}

/// S05's process-wide memo (`homeMemoProvider`).
final homeMemoProvider = Provider<HomeMemo>((ref) => HomeMemo());

/// The one-time S05 flags (`homeFlagsProvider`).
final FutureProvider<HomeFlags> homeFlagsProvider = FutureProvider.autoDispose((
  ref,
) async {
  final store = ref.watch(secureStoreProvider);
  final firstRun = await store.read(HomeNoticeKeys.firstRunDone);
  final notice = await store.read(HomeNoticeKeys.updateNoticeVersion);
  final install = await ref.watch(installRepositoryProvider).getOrCreate();
  return HomeFlags(
    firstRunDone: firstRun.valueOrNull != null,
    updateNoticeVersion: notice.valueOrNull,
    registered: install.valueOrNull?.isRegistered ?? false,
  );
});

/// Today's daily card (`homeDailyCardProvider`).
final StreamProvider<DailyCard?> homeDailyCardProvider =
    StreamProvider.autoDispose(
      (ref) => ref.watch(dailyCardRepositoryProvider).watchToday(),
    );

/// The latest readings for "Recent readings" (`homeRecentReadingsProvider`).
final StreamProvider<List<Reading>> homeRecentReadingsProvider =
    StreamProvider.autoDispose(
      (ref) => ref
          .watch(journalRepositoryProvider)
          .watchAll(query: const JournalQuery(includeDailyCards: false))
          .map(
            (items) => [
              for (final item in items)
                if (item case JournalReadingItem(:final reading)) reading,
            ].take(HomeController.recentCount).toList(growable: false),
          ),
    );

/// S05: a pure derivation of the app state plus the one-time notices.
final class HomeController extends Notifier<HomeState> {
  /// How many recent readings Home lists.
  static const int recentCount = 3;

  @override
  HomeState build() {
    final flagsValue = ref.watch(homeFlagsProvider);
    final cardValue = ref.watch(homeDailyCardProvider);
    final recentValue = ref.watch(homeRecentReadingsProvider);
    final balance = ref.watch(balanceProvider);
    final stale = ref.watch(balanceStaleProvider);
    final entitlement = ref.watch(entitlementProvider);
    final updateAvailable = ref.watch(updateAvailableProvider);
    final sync = ref.watch(syncStatusProvider);
    final config = ref.watch(remoteConfigProvider);
    final memo = ref.watch(homeMemoProvider);
    final info = ref.watch(appInfoProvider);
    final analytics = ref.watch(analyticsServiceProvider);
    final store = ref.watch(secureStoreProvider);
    if (flagsValue.isLoading || cardValue.isLoading) {
      return const HomeState.loading();
    }
    final flags =
        flagsValue.value ??
        const HomeFlags(
          firstRunDone: true,
          updateNoticeVersion: null,
          registered: false,
        );
    final recommended = switch (info.platform) {
      AppPlatform.ios => config.appRecommendedVersionIos,
      AppPlatform.android => config.appRecommendedVersionAndroid,
    };
    final showUpdate =
        updateAvailable &&
        !memo.updateDismissed &&
        (flags.updateNoticeVersion != recommended ||
            memo.logged.contains(_updateKey(recommended)));
    final deviceUnverified =
        sync is SyncStatusUnavailable ||
        (!flags.registered && sync is! SyncStatusSynced);
    if (showUpdate && memo.logged.add(_updateKey(recommended))) {
      unawaited(_updateShown(analytics, store, recommended));
    }
    if (deviceUnverified && memo.logged.add('device_unverified')) {
      unawaited(
        analytics.log(
          const DeviceUnverifiedShownEvent(origin: AppNoticeOrigin.launch),
        ),
      );
    }
    return HomeState.content(
      HomeView(
        balance: balance,
        variant: _variant(balance),
        firstRun: !flags.firstRunDone && !memo.firstRunDismissed,
        balanceStale: stale,
        deviceUnverified: deviceUnverified,
        adsRemoved: entitlement.removesAds,
        updateAvailable: showUpdate,
        dailyCard: cardValue.value,
        recentReadings: recentValue.value ?? const [],
      ),
    );
  }

  static String _updateKey(String version) => 'update_available:$version';

  static Future<void> _updateShown(
    AnalyticsService analytics,
    SecureStore store,
    String version,
  ) async {
    await store.write(HomeNoticeKeys.updateNoticeVersion, version);
    await analytics.log(
      const AppUpdateAvailableShownEvent(origin: AppNoticeOrigin.launch),
    );
  }

  static HomeBalanceVariant _variant(CreditBalance? balance) {
    if (balance == null) return HomeBalanceVariant.unknown;
    if (balance.free.remaining > 0) return HomeBalanceVariant.freeAvailable;
    if (balance.bonus + balance.displayPaid > 0) {
      return HomeBalanceVariant.freeUsedWithCredits;
    }
    return HomeBalanceVariant.zeroReadings;
  }

  /// The first-run coachmark was dismissed (or "Start a reading" tapped).
  Future<void> dismissFirstRun() async {
    final memo = ref.read(homeMemoProvider);
    final store = ref.read(secureStoreProvider);
    if (memo.firstRunDismissed) return;
    memo.firstRunDismissed = true;
    ref.invalidateSelf();
    await store.write(HomeNoticeKeys.firstRunDone, '1');
  }

  /// The `updateAvailable` notice was dismissed.
  void dismissUpdateNotice() {
    ref.read(homeMemoProvider).updateDismissed = true;
    ref.invalidateSelf();
  }

  /// "Readings unavailable on this device" → **Retry**: a sync pass and a
  /// fresh registration check.
  Future<void> retryVerification() async {
    final balance = ref.read(balanceProvider.notifier);
    ref.invalidate(homeFlagsProvider);
    await balance.refresh();
  }
}

/// S05 (`homeControllerProvider`).
final NotifierProvider<HomeController, HomeState> homeControllerProvider =
    NotifierProvider.autoDispose(HomeController.new);
