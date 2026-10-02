import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

/// The **Support ID** of an install: the first 8 lowercase hex characters
/// of `SHA-256(installId)` (01 §7.10, RC43). It identifies the install to
/// support without revealing the install ID.
String supportIdOf(InstallId installId) =>
    sha256.convert(utf8.encode(installId.value)).toString().substring(0, 8);

/// What "Contact support" puts in the mailto (01 §7.10): the address, the
/// Support ID, app version, OS and locale. The view builds the localized
/// subject and body from it.
@immutable
final class SupportInfo {
  /// Creates the info.
  const SupportInfo({
    required this.email,
    required this.supportId,
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.osVersion,
    required this.locale,
  });

  /// The support address (`FlavorConfig.supportEmail`).
  final String email;

  /// The Support ID ([supportIdOf]).
  final String supportId;

  /// The app version (`1.0.0`).
  final String appVersion;

  /// The build number.
  final String buildNumber;

  /// iOS or Android.
  final AppPlatform platform;

  /// The OS version.
  final String osVersion;

  /// The app locale code.
  final String locale;

  /// The "Email support" link: [subject] and [body] are percent-encoded
  /// (mail apps show a `+` literally).
  Uri mailto({required String subject, required String body}) => Uri.parse(
    'mailto:$email?subject=${Uri.encodeComponent(subject)}'
    '&body=${Uri.encodeComponent(body)}',
  );

  @override
  bool operator ==(Object other) =>
      other is SupportInfo &&
      other.email == email &&
      other.supportId == supportId &&
      other.appVersion == appVersion &&
      other.buildNumber == buildNumber &&
      other.platform == platform &&
      other.osVersion == osVersion &&
      other.locale == locale;

  @override
  int get hashCode => Object.hash(
    email,
    supportId,
    appVersion,
    buildNumber,
    platform,
    osVersion,
    locale,
  );
}

/// Loads the [SupportInfo] of this install (S20 About, S28 Contact
/// support); the locale is read at call time.
Future<Result<SupportInfo>> loadSupportInfo(Ref ref) async {
  final info = ref.read(appInfoProvider);
  final email = ref.read(flavorConfigProvider).supportEmail;
  final locale = ref.read(appLocaleProvider)();
  final identity = await ref.read(installRepositoryProvider).getOrCreate();
  return identity.map(
    (i) => SupportInfo(
      email: email,
      supportId: supportIdOf(i.installId),
      appVersion: info.version,
      buildNumber: info.buildNumber,
      platform: info.platform,
      osVersion: info.osVersion,
      locale: locale,
    ),
  );
}
