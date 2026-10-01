import 'package:taro_core/src/result/result.dart';

/// Opens a link outside the app (02 §5): `tel:` and `sms:` on S27, `https:`
/// help and store links (S27, S28, S30). Only these schemes are opened;
/// anything else fails without leaving the app.
abstract interface class UrlLauncher {
  /// The schemes [open] accepts.
  static const Set<String> allowedSchemes = {'tel', 'sms', 'https'};

  /// Opens [uri] in the system handler (dialer, messages, browser). An
  /// unsupported scheme or a missing handler is an `Err`; it never throws.
  Future<Result<void>> open(Uri uri);
}

/// A [UrlLauncher] that opens nothing and reports success: screenshot
/// mode and host tests.
final class NoOpUrlLauncher implements UrlLauncher {
  /// Creates the no-op launcher.
  const NoOpUrlLauncher();

  @override
  Future<Result<void>> open(Uri uri) async => const Result.ok(null);
}
