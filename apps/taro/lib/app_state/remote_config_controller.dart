import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

/// The remote config (02 §9.4): the cached document at once, then every
/// refresh.
final class RemoteConfigController extends Notifier<RemoteConfig> {
  @override
  RemoteConfig build() {
    final repository = ref.watch(remoteConfigRepositoryProvider);
    final subscription = repository.watch().listen((config) {
      state = config;
    });
    ref.onDispose(subscription.cancel);
    return repository.current;
  }
}

/// The app-wide remote config (`remoteConfigProvider`, 02 §7).
final remoteConfigProvider =
    NotifierProvider<RemoteConfigController, RemoteConfig>(
      RemoteConfigController.new,
    );

/// Whether the installed version is below `app.minVersion.{ios,android}`:
/// the router redirects to S30 `/update` (RC73).
final updateRequiredProvider = Provider<bool>((ref) {
  final config = ref.watch(remoteConfigProvider);
  final info = ref.watch(appInfoProvider);
  final min = switch (info.platform) {
    AppPlatform.ios => config.appMinVersionIos,
    AppPlatform.android => config.appMinVersionAndroid,
  };
  return compareVersions(info.version, min) < 0;
});

/// Whether the installed version is below `app.recommendedVersion.*`: the
/// dismissible S05 `updateAvailable` notice (RC73).
final updateAvailableProvider = Provider<bool>((ref) {
  final config = ref.watch(remoteConfigProvider);
  final info = ref.watch(appInfoProvider);
  final recommended = switch (info.platform) {
    AppPlatform.ios => config.appRecommendedVersionIos,
    AppPlatform.android => config.appRecommendedVersionAndroid,
  };
  return compareVersions(info.version, recommended) < 0;
});

/// Compares two `major.minor.patch` versions numerically; missing or
/// non-numeric parts count as 0 and a `+build` suffix is ignored.
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .split('+')
      .first
      .split('.')
      .map((p) => int.tryParse(p.trim()) ?? 0)
      .toList();
  final x = parts(a);
  final y = parts(b);
  final length = x.length > y.length ? x.length : y.length;
  for (var i = 0; i < length; i++) {
    final left = i < x.length ? x[i] : 0;
    final right = i < y.length ? y[i] : 0;
    if (left != right) return left.compareTo(right);
  }
  return 0;
}
