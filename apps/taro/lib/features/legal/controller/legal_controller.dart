import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/app_state/connectivity_controller.dart';
import 'package:taro/app_state/remote_config_controller.dart';
import 'package:taro_core/taro_core.dart';

part 'legal_controller.freezed.dart';

/// The S29 documents (`/legal/:doc`, 01 §7.10 About).
enum LegalDoc {
  /// The disclaimer (ARB, 05 §3; bundled, offline).
  disclaimer,

  /// Terms of Use (`legal.termsUrl`).
  terms,

  /// Privacy Policy (`legal.privacyUrl`).
  privacy,

  /// Open-source licences (`showLicensePage`).
  licenses;

  /// The `:doc` route segment, or `null` when unknown.
  static LegalDoc? fromSegment(String segment) =>
      values.where((d) => d.name == segment).firstOrNull;
}

/// S29 Legal (01 §8.3).
@freezed
sealed class LegalState with _$LegalState {
  /// [doc] is shown: the disclaimer text, the licence list, or [url] in the
  /// in-app webview.
  const factory LegalState.content({required LegalDoc doc, String? url}) =
      LegalContent;

  /// A web document while offline: `TaroErrorView(network)` + a link that
  /// opens [url] in the browser.
  const factory LegalState.offline({
    required LegalDoc doc,
    required String url,
  }) = LegalOffline;
}

/// Drives S29: the selected document, its URL (from remote config, so the
/// hosted pages can move without a release) and the offline variant.
final class LegalController extends Notifier<LegalState> {
  /// A controller opened on [initial].
  LegalController(this.initial);

  /// The document of the route.
  final LegalDoc initial;

  late LegalDoc _doc;
  late ProviderSubscription<bool> _online;
  late ProviderSubscription<RemoteConfig> _config;

  @override
  LegalState build() {
    _doc = initial;
    _online = ref.listen(connectivityProvider, (_, _) => _update());
    _config = ref.listen(remoteConfigProvider, (_, _) => _update());
    return _compute();
  }

  /// Switches the tab.
  void select(LegalDoc doc) {
    _doc = doc;
    _update();
  }

  void _update() => state = _compute();

  LegalState _compute() {
    final config = _config.read();
    final url = switch (_doc) {
      LegalDoc.terms => config.legalTermsUrl,
      LegalDoc.privacy => config.legalPrivacyUrl,
      LegalDoc.disclaimer || LegalDoc.licenses => null,
    };
    if (url != null && !_online.read()) {
      return LegalState.offline(doc: _doc, url: url);
    }
    return LegalState.content(doc: _doc, url: url);
  }
}

/// S29 controllers by initial document.
final NotifierProviderFamily<LegalController, LegalState, LegalDoc>
legalControllerProvider = NotifierProvider.autoDispose.family(
  LegalController.new,
);
