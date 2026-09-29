import 'package:taro/data/api/api_timeouts.dart';

/// How a route authenticates (03 §2.1, OpenAPI `x-taro-auth`).
enum EndpointAuth {
  /// No `Authorization` header.
  public,

  /// `Authorization: Bearer <installToken>`; `401 TOKEN_EXPIRED` triggers
  /// one refresh and one retry.
  token,

  /// The token is sent but may be expired (`POST /v1/installs/token`); it is
  /// never refreshed by the auth interceptor.
  tokenMayBeExpired,
}

/// One client call of the RC4 route set (GLOSSARY §4, 02 §6.3).
final class Endpoint {
  /// Creates an endpoint.
  const Endpoint(
    this.id,
    this.method,
    this.path, {
    required this.auth,
    required this.timeout,
    this.idempotent = false,
    this.attested = false,
    this.aiConsent = false,
    this.pollOnTimeout = false,
  });

  /// The GLOSSARY §4 number, e.g. `E10`.
  final String id;

  /// The HTTP method in upper case.
  final String method;

  /// The path template under the base URL, e.g.
  /// `/v1/readings/{clientReadingId}`.
  final String path;

  /// How the route authenticates.
  final EndpointAuth auth;

  /// The client timeout (02 §6.3).
  final Duration timeout;

  /// **idem**: the call carries an `Idempotency-Key`.
  final bool idempotent;

  /// **attest**: the call carries `X-Taro-Attestation` (RC11, RC50).
  final bool attested;

  /// The call carries `X-Taro-AI-Consent` (RC28).
  final bool aiConsent;

  /// A receive timeout is never retried: the caller polls instead (RC31).
  final bool pollOnTimeout;

  /// `METHOD path`, e.g. `POST /v1/readings`.
  String get route => '$method $path';

  /// [path] with every `{name}` replaced by the URL-encoded [params] value.
  ///
  /// Throws an [ArgumentError] when a placeholder has no value.
  String resolve([Map<String, String> params = const {}]) =>
      path.replaceAllMapped(_placeholder, (m) {
        final value = params[m[1]];
        if (value == null) {
          throw ArgumentError.value(params, 'params', 'missing ${m[1]}');
        }
        return Uri.encodeComponent(value);
      });

  static final RegExp _placeholder = RegExp(r'\{(\w+)\}');

  @override
  String toString() => '$id $route';
}

/// The client calls of the canonical v1 surface (RC4; GLOSSARY §4 E02–E17).
///
/// E01 (health) and the AdMob and store callbacks (E18–E20) are never called
/// by the app.
abstract final class Endpoints {
  /// E02 `GET /v1/config` (`If-None-Match`).
  static const config = Endpoint(
    'E02',
    'GET',
    '/v1/config',
    auth: EndpointAuth.public,
    timeout: ApiTimeouts.short,
  );

  /// E03 `POST /v1/attest/challenge`.
  static const challenge = Endpoint(
    'E03',
    'POST',
    '/v1/attest/challenge',
    auth: EndpointAuth.public,
    timeout: ApiTimeouts.short,
  );

  /// E04 `POST /v1/installs`: a fresh key per registration attempt (RC55).
  static const register = Endpoint(
    'E04',
    'POST',
    '/v1/installs',
    auth: EndpointAuth.public,
    timeout: ApiTimeouts.medium,
    idempotent: true,
  );

  /// E05 `POST /v1/installs/token` **attest**.
  static const refreshToken = Endpoint(
    'E05',
    'POST',
    '/v1/installs/token',
    auth: EndpointAuth.tokenMayBeExpired,
    timeout: ApiTimeouts.medium,
    attested: true,
  );

  /// E06 `PUT /v1/installs/me/timezone` **idem**.
  static const timezone = Endpoint(
    'E06',
    'PUT',
    '/v1/installs/me/timezone',
    auth: EndpointAuth.token,
    timeout: ApiTimeouts.medium,
    idempotent: true,
  );

  /// E07 `DELETE /v1/installs/me` **idem**.
  static const deleteInstall = Endpoint(
    'E07',
    'DELETE',
    '/v1/installs/me',
    auth: EndpointAuth.token,
    timeout: ApiTimeouts.medium,
    idempotent: true,
  );

  /// E08 `GET /v1/balance`.
  static const balance = Endpoint(
    'E08',
    'GET',
    '/v1/balance',
    auth: EndpointAuth.token,
    timeout: ApiTimeouts.short,
  );

  /// E09 `POST /v1/readings/holds` **idem** = clientReadingId **attest**.
  static const hold = Endpoint(
    'E09',
    'POST',
    '/v1/readings/holds',
    auth: EndpointAuth.token,
    timeout: ApiTimeouts.medium,
    idempotent: true,
    attested: true,
    aiConsent: true,
  );

  /// E10 `POST /v1/readings` **idem** = clientReadingId **attest**, 60 s.
  static const createReading = Endpoint(
    'E10',
    'POST',
    '/v1/readings',
    auth: EndpointAuth.token,
    timeout: ApiTimeouts.reading,
    idempotent: true,
    attested: true,
    aiConsent: true,
    pollOnTimeout: true,
  );

  /// E11 `GET /v1/readings/{clientReadingId}`.
  static const getReading = Endpoint(
    'E11',
    'GET',
    '/v1/readings/{clientReadingId}',
    auth: EndpointAuth.token,
    timeout: ApiTimeouts.short,
  );

  /// E12 `POST /v1/readings/{clientReadingId}/ack` (no body).
  static const ackReading = Endpoint(
    'E12',
    'POST',
    '/v1/readings/{clientReadingId}/ack',
    auth: EndpointAuth.token,
    timeout: ApiTimeouts.short,
  );

  /// E13 `POST /v1/readings/{clientReadingId}/report` **idem**.
  static const reportReading = Endpoint(
    'E13',
    'POST',
    '/v1/readings/{clientReadingId}/report',
    auth: EndpointAuth.token,
    timeout: ApiTimeouts.medium,
    idempotent: true,
  );

  /// E14 `POST /v1/purchases/verify` **idem**.
  static const verifyPurchase = Endpoint(
    'E14',
    'POST',
    '/v1/purchases/verify',
    auth: EndpointAuth.token,
    timeout: ApiTimeouts.verify,
    idempotent: true,
  );

  /// E15 `POST /v1/rewards/intents` **idem** **attest**.
  static const rewardIntent = Endpoint(
    'E15',
    'POST',
    '/v1/rewards/intents',
    auth: EndpointAuth.token,
    timeout: ApiTimeouts.short,
    idempotent: true,
    attested: true,
  );

  /// E16 `GET /v1/rewards/intents/{intentId}`.
  static const rewardStatus = Endpoint(
    'E16',
    'GET',
    '/v1/rewards/intents/{intentId}',
    auth: EndpointAuth.token,
    timeout: ApiTimeouts.short,
  );

  /// E17 `POST /v1/rewards/intents/{intentId}/cancel`.
  static const rewardCancel = Endpoint(
    'E17',
    'POST',
    '/v1/rewards/intents/{intentId}/cancel',
    auth: EndpointAuth.token,
    timeout: ApiTimeouts.short,
  );

  /// Every client call, in GLOSSARY §4 order.
  static const List<Endpoint> all = [
    config,
    challenge,
    register,
    refreshToken,
    timezone,
    deleteInstall,
    balance,
    hold,
    createReading,
    getReading,
    ackReading,
    reportReading,
    verifyPurchase,
    rewardIntent,
    rewardStatus,
    rewardCancel,
  ];
}
