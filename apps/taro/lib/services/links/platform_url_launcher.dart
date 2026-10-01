import 'package:flutter/services.dart';
import 'package:taro_core/taro_core.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hands [uri] to the platform; `false` when no app can handle it.
typedef LaunchUri = Future<bool> Function(Uri uri);

/// The production [UrlLauncher] over `url_launcher` (02 §5): `tel:` opens
/// the dialer, `sms:` the messages app and `https:` the browser, always
/// outside the app. Only [UrlLauncher.allowedSchemes] are opened; a
/// missing handler or a platform error maps to `UnexpectedFailure`.
final class PlatformUrlLauncher implements UrlLauncher {
  /// A launcher over [launch] (default: `launchUrl` in an external app).
  PlatformUrlLauncher({required Logger logger, LaunchUri? launch})
    : _logger = logger.child('links'),
      _launch = launch ?? launchExternally;

  final Logger _logger;
  final LaunchUri _launch;

  /// The `url_launcher` call, outside the app.
  static Future<bool> launchExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Future<Result<void>> open(Uri uri) async {
    if (!UrlLauncher.allowedSchemes.contains(uri.scheme)) {
      return Result.err(
        Failure.unexpected(
          error: ArgumentError.value(uri.scheme, 'scheme'),
          stack: StackTrace.current,
        ),
      );
    }
    try {
      if (await _launch(uri)) return const Result.ok(null);
      _logger.warning('no handler for ${uri.scheme}:');
      return Result.err(
        Failure.unexpected(
          error: StateError('no handler for ${uri.scheme}'),
          stack: StackTrace.current,
        ),
      );
    } on PlatformException catch (error, stack) {
      _logger.warning('launch failed', error: error, stack: stack);
      return Result.err(Failure.unexpected(error: error, stack: stack));
    }
  }
}
