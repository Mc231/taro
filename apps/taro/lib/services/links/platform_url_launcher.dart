import 'package:flutter/services.dart';
import 'package:taro_core/taro_core.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hands [uri] to the platform; `false` when no app can handle it.
typedef LaunchUri = Future<bool> Function(Uri uri);

/// Opens this app's system settings page; `false` when it could not.
typedef OpenAppSettings = Future<bool> Function();

/// The production [UrlLauncher] over `url_launcher` (02 §5): `tel:` opens
/// the dialer, `sms:` the messages app, `mailto:` the mail app and `https:`
/// the browser, outside the app; [openInApp] uses the in-app browser view
/// (SFSafariViewController, Custom Tabs). [openAppSettings] opens iOS
/// Settings through `app-settings:` and the Android app details screen
/// through the `taro/app_settings` channel (`MainActivity`). A missing
/// handler or a platform error maps to `UnexpectedFailure`.
final class PlatformUrlLauncher implements UrlLauncher {
  /// A launcher over [launch] (default: `launchUrl` in an external app),
  /// [launchInApp] (default: the in-app browser view) and [settings]
  /// (default: [openSettingsFor] on this platform, [isIos]).
  PlatformUrlLauncher({
    required Logger logger,
    bool isIos = false,
    LaunchUri? launch,
    LaunchUri? launchInApp,
    OpenAppSettings? settings,
  }) : _logger = logger.child('links'),
       _launch = launch ?? launchExternally,
       _launchInApp = launchInApp ?? launchInBrowserView,
       _settings = settings ?? openSettingsFor(isIos: isIos);

  /// The Android channel that opens the app details settings screen.
  static const MethodChannel appSettingsChannel = MethodChannel(
    'taro/app_settings',
  );

  final Logger _logger;
  final LaunchUri _launch;
  final LaunchUri _launchInApp;
  final OpenAppSettings _settings;

  /// The `url_launcher` call, outside the app.
  static Future<bool> launchExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  /// The `url_launcher` call, in the in-app browser view.
  static Future<bool> launchInBrowserView(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.inAppBrowserView);

  /// The settings opener of iOS (`app-settings:`) or Android (the channel).
  static OpenAppSettings openSettingsFor({required bool isIos}) => isIos
      ? () => launchUrl(Uri.parse('app-settings:'))
      : () async =>
            await appSettingsChannel.invokeMethod<bool>('open') ?? false;

  @override
  Future<Result<void>> open(Uri uri) =>
      UrlLauncher.allowedSchemes.contains(uri.scheme)
      ? _run(uri.scheme, () => _launch(uri))
      : Future.value(_badScheme(uri));

  @override
  Future<Result<void>> openInApp(Uri uri) => uri.scheme == 'https'
      ? _run('in-app', () => _launchInApp(uri))
      : Future.value(_badScheme(uri));

  @override
  Future<Result<void>> openAppSettings() => _run('settings', _settings);

  static Result<void> _badScheme(Uri uri) => Result.err(
    Failure.unexpected(
      error: ArgumentError.value(uri.scheme, 'scheme'),
      stack: StackTrace.current,
    ),
  );

  Future<Result<void>> _run(String what, Future<bool> Function() call) async {
    try {
      if (await call()) return const Result.ok(null);
      _logger.warning('no handler for $what');
      return Result.err(
        Failure.unexpected(
          error: StateError('no handler for $what'),
          stack: StackTrace.current,
        ),
      );
    } on PlatformException catch (error, stack) {
      _logger.warning('launch failed', error: error, stack: stack);
      return Result.err(Failure.unexpected(error: error, stack: stack));
    } on MissingPluginException catch (error, stack) {
      _logger.warning('launch failed', error: error, stack: stack);
      return Result.err(Failure.unexpected(error: error, stack: stack));
    }
  }
}
