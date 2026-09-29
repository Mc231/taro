import 'package:dio/dio.dart';
import 'package:taro/data/api/request_context.dart';
import 'package:taro_core/taro_core.dart';

/// Fourth in the chain (02 §6.3, RC28): `X-Taro-AI-Consent: <version>` on
/// `POST /v1/readings/holds` and `POST /v1/readings`, from the stored AI
/// consent. Without a granted consent the header is omitted and the Worker
/// answers `412 AI_CONSENT_REQUIRED` (the gate normally prevents that).
final class AiConsentInterceptor extends Interceptor {
  /// Creates the interceptor.
  AiConsentInterceptor(this._consent);

  final ConsentStore _consent;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.endpoint?.aiConsent ?? false) {
      final ai = _consent.current.ai;
      final version = ai.version;
      if (ai.decision == AiConsentDecision.granted && version != null) {
        options.headers[TaroHeaders.aiConsent] = '$version';
      } else {
        options.headers.remove(TaroHeaders.aiConsent);
      }
    }
    handler.next(options);
  }
}
