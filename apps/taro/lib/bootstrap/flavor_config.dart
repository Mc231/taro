/// Build flavors (02 AR17, §15).
enum Flavor {
  /// Local development against `wrangler dev`.
  dev,

  /// Staging Worker, "Taro Beta".
  staging,

  /// Production.
  prod,
}

/// AdMob app and ad unit IDs for one platform.
final class AdmobIds {
  /// Creates a set of AdMob IDs.
  const AdmobIds({
    required this.appId,
    required this.banner,
    required this.rewarded,
  });

  /// AdMob app ID (`ca-app-pub-…~…`).
  final String appId;

  /// Banner ad unit ID.
  final String banner;

  /// Rewarded ad unit ID.
  final String rewarded;
}

/// Per-flavor configuration read from `--dart-define-from-file=config/<x>.json`
/// (02 §15). Holds no secrets.
final class FlavorConfig {
  /// Creates a configuration.
  const FlavorConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.admobIos,
    required this.admobAndroid,
    required this.playCloudProjectNumber,
    required this.privacyPolicyUrl,
    required this.termsUrl,
    required this.supportEmail,
    required this.universalLinkHost,
  });

  /// Parses the flat key map used by `config/<flavor>.json`.
  ///
  /// Throws [FormatException] when `flavor` is missing or unknown.
  factory FlavorConfig.fromJson(Map<String, Object?> json) {
    String read(String key) => (json[key] as String?) ?? '';
    final flavorName = read(keyFlavor);
    final flavor = Flavor.values.where((f) => f.name == flavorName);
    if (flavor.isEmpty) {
      throw FormatException('Unknown flavor "$flavorName"');
    }
    AdmobIds admob(String platform) => AdmobIds(
      appId: read('admob.$platform.appId'),
      banner: read('admob.$platform.banner'),
      rewarded: read('admob.$platform.rewarded'),
    );
    return FlavorConfig(
      flavor: flavor.single,
      apiBaseUrl: read('apiBaseUrl'),
      admobIos: admob('ios'),
      admobAndroid: admob('android'),
      playCloudProjectNumber: read('playCloudProjectNumber'),
      privacyPolicyUrl: read('privacyPolicyUrl'),
      termsUrl: read('termsUrl'),
      supportEmail: read('supportEmail'),
      universalLinkHost: read('universalLinkHost'),
    );
  }

  /// Builds the configuration for the entrypoint [flavor] from compile-time
  /// [defines] (defaults to [dartDefines]).
  ///
  /// A build without `--dart-define-from-file` still starts (all values are
  /// empty); a config file for a different flavor is a build mistake and
  /// throws [StateError].
  factory FlavorConfig.fromDefines(
    Flavor flavor, {
    Map<String, String> defines = dartDefines,
  }) {
    final declared = defines[keyFlavor] ?? '';
    if (declared.isNotEmpty && declared != flavor.name) {
      throw StateError(
        'Entrypoint flavor "${flavor.name}" was built with the config of '
        '"$declared".',
      );
    }
    return FlavorConfig.fromJson({...defines, keyFlavor: flavor.name});
  }

  /// JSON key of the flavor name.
  static const String keyFlavor = 'flavor';

  /// Values injected by `--dart-define-from-file`.
  static const Map<String, String> dartDefines = {
    'flavor': String.fromEnvironment('flavor'),
    'apiBaseUrl': String.fromEnvironment('apiBaseUrl'),
    'admob.ios.appId': String.fromEnvironment('admob.ios.appId'),
    'admob.ios.banner': String.fromEnvironment('admob.ios.banner'),
    'admob.ios.rewarded': String.fromEnvironment('admob.ios.rewarded'),
    'admob.android.appId': String.fromEnvironment('admob.android.appId'),
    'admob.android.banner': String.fromEnvironment('admob.android.banner'),
    'admob.android.rewarded': String.fromEnvironment('admob.android.rewarded'),
    'playCloudProjectNumber': String.fromEnvironment('playCloudProjectNumber'),
    'privacyPolicyUrl': String.fromEnvironment('privacyPolicyUrl'),
    'termsUrl': String.fromEnvironment('termsUrl'),
    'supportEmail': String.fromEnvironment('supportEmail'),
    'universalLinkHost': String.fromEnvironment('universalLinkHost'),
  };

  /// The build flavor.
  final Flavor flavor;

  /// Worker base URL.
  final String apiBaseUrl;

  /// AdMob IDs on iOS.
  final AdmobIds admobIos;

  /// AdMob IDs on Android.
  final AdmobIds admobAndroid;

  /// Google Cloud project number for Play Integrity.
  final String playCloudProjectNumber;

  /// Privacy policy URL.
  final String privacyPolicyUrl;

  /// Terms of use URL.
  final String termsUrl;

  /// Support e-mail address.
  final String supportEmail;

  /// Host for Universal Links / App Links.
  final String universalLinkHost;

  /// Whether this is the production flavor.
  bool get isProd => flavor == Flavor.prod;
}
