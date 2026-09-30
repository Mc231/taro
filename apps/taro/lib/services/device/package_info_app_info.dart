import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:taro_core/taro_core.dart';

/// Reads the package metadata.
typedef PackageInfoReader = Future<PackageInfo> Function();

/// The production [AppInfo] over `package_info_plus` and
/// `device_info_plus` (02 §5). Facts are read once by [load].
///
/// [deviceModelClass] is coarse on purpose: `phone` or `tablet`, never a
/// model string.
final class PackageInfoAppInfo implements AppInfo {
  /// Facts read elsewhere; use [load] in the app.
  const PackageInfoAppInfo({
    required this.version,
    required this.buildNumber,
    required this.platform,
    required this.osVersion,
    required this.deviceModelClass,
  });

  /// The shortest side (logical px) from which a device is a tablet.
  static const double tabletShortestSide = 600;

  /// Reads the facts. [targetPlatform] defaults to the running platform and
  /// [shortestSide] to the first Flutter view's (Android tablets only;
  /// iOS reports the model family).
  static Future<PackageInfoAppInfo> load({
    PackageInfoReader? packageInfo,
    DeviceInfoPlugin? deviceInfo,
    TargetPlatform? targetPlatform,
    double? shortestSide,
  }) async {
    final package = await (packageInfo ?? PackageInfo.fromPlatform)();
    final devices = deviceInfo ?? DeviceInfoPlugin();
    final platform =
        (targetPlatform ?? defaultTargetPlatform) == TargetPlatform.iOS
        ? AppPlatform.ios
        : AppPlatform.android;
    final String osVersion;
    final bool tablet;
    switch (platform) {
      case AppPlatform.ios:
        final ios = await devices.iosInfo;
        osVersion = ios.systemVersion;
        tablet = ios.model.toLowerCase().contains('ipad');
      case AppPlatform.android:
        final android = await devices.androidInfo;
        osVersion = android.version.release;
        tablet =
            (shortestSide ?? firstViewShortestSide()) >= tabletShortestSide;
    }
    return PackageInfoAppInfo(
      version: marketingVersion(package.version),
      buildNumber: buildNumberOf(package.buildNumber),
      platform: platform,
      osVersion: osVersion.isEmpty ? 'unknown' : osVersion,
      deviceModelClass: tablet ? 'tablet' : 'phone',
    );
  }

  /// The shortest side of the first Flutter view in logical px (0 when
  /// there is none).
  static double firstViewShortestSide() {
    final views = PlatformDispatcher.instance.views;
    if (views.isEmpty) return 0;
    final view = views.first;
    return (view.physicalSize / view.devicePixelRatio).shortestSide;
  }

  /// The leading `major.minor.patch` of [raw] (flavor suffixes dropped),
  /// `0.0.0` when absent.
  static String marketingVersion(String raw) =>
      RegExp(r'^\d+\.\d+\.\d+').stringMatch(raw.trim()) ?? '0.0.0';

  /// [raw] when it is all digits, else `0`.
  static String buildNumberOf(String raw) =>
      RegExp(r'^\d+$').hasMatch(raw.trim()) ? raw.trim() : '0';

  @override
  final String version;

  @override
  final String buildNumber;

  @override
  final AppPlatform platform;

  @override
  final String osVersion;

  @override
  final String deviceModelClass;
}
