import 'package:flutter/widgets.dart';
import 'package:taro_core/taro_core.dart';

/// The hosted legal page [url] (`legal.privacyUrl`, `legal.termsUrl`) in
/// the app language: the site picks the locale from `?hl=` (05 §7). Other
/// query parameters are kept; an existing `hl` is replaced.
Uri localizedLegalUri(String url, Locale locale) {
  final uri = Uri.parse(url);
  return uri.replace(
    queryParameters: {...uri.queryParameters, 'hl': locale.languageCode},
  );
}

/// Opens the hosted legal page [url] in [locale] (S29, CS10): the in-app
/// browser (SFSafariViewController, Custom Tabs), else the system browser.
/// Used by S04 "Privacy policy" during onboarding and by S29 "Read online".
Future<Result<void>> openLegalUrl(
  UrlLauncher links,
  String url,
  Locale locale,
) async {
  final uri = localizedLegalUri(url, locale);
  final inApp = await links.openInApp(uri);
  return inApp is Err ? links.open(uri) : inApp;
}
