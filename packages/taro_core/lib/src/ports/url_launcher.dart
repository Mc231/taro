import 'package:taro_core/src/result/result.dart';

/// Opens a link (02 §5): `tel:` and `sms:` on S27, `mailto:` for Contact
/// support (S28), `https:` help, legal and store links (S27–S30), the
/// in-app browser for the hosted terms and privacy policy (S29), and this
/// app's page in the system settings (S22 notifications, S23 tracking).
/// Only [allowedSchemes] are opened; anything else fails without leaving
/// the app.
abstract interface class UrlLauncher {
  /// The schemes [open] accepts.
  static const Set<String> allowedSchemes = {'tel', 'sms', 'mailto', 'https'};

  /// Opens [uri] in the system handler (dialer, messages, mail, browser).
  /// An unsupported scheme or a missing handler is an `Err`; it never
  /// throws.
  Future<Result<void>> open(Uri uri);

  /// Opens an `https:` [uri] in the in-app browser (SFSafariViewController,
  /// Custom Tabs); any other scheme is an `Err`.
  Future<Result<void>> openInApp(Uri uri);

  /// Opens this app's page in the system settings (notifications, iOS
  /// tracking).
  Future<Result<void>> openAppSettings();
}

/// A [UrlLauncher] that opens nothing and reports success: screenshot
/// mode and host tests.
final class NoOpUrlLauncher implements UrlLauncher {
  /// Creates the no-op launcher.
  const NoOpUrlLauncher();

  @override
  Future<Result<void>> open(Uri uri) async => const Result.ok(null);

  @override
  Future<Result<void>> openInApp(Uri uri) async => const Result.ok(null);

  @override
  Future<Result<void>> openAppSettings() async => const Result.ok(null);
}
