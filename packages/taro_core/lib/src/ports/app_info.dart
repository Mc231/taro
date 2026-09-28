/// The app platform (`X-Taro-Platform`).
enum AppPlatform {
  /// iOS / iPadOS.
  ios,

  /// Android.
  android,
}

/// Static app and device facts (02 §5).
abstract interface class AppInfo {
  /// The marketing version, for example `1.2.0`.
  String get version;

  /// The build number, for example `34`.
  String get buildNumber;

  /// The platform.
  AppPlatform get platform;

  /// The OS version.
  String get osVersion;

  /// A coarse device class (never a unique model string).
  String get deviceModelClass;
}
