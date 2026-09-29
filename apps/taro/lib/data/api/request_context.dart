import 'package:dio/dio.dart';
import 'package:taro/data/api/endpoints.dart';
import 'package:taro_core/taro_core.dart';

/// Wire header names (03 §2.1, GLOSSARY §4.1).
abstract final class TaroHeaders {
  /// `X-Taro-Platform`.
  static const platform = 'X-Taro-Platform';

  /// `X-Taro-App-Version`.
  static const appVersion = 'X-Taro-App-Version';

  /// `X-Taro-Locale`.
  static const locale = 'X-Taro-Locale';

  /// `X-Taro-Flavor` (dev and staging builds only; Phase 11.3).
  static const flavor = 'X-Taro-Flavor';

  /// `X-Request-Id` (a UUID per attempt).
  static const requestId = 'X-Request-Id';

  /// `Idempotency-Key`.
  static const idempotencyKey = 'Idempotency-Key';

  /// `Authorization`.
  static const authorization = 'Authorization';

  /// `X-Taro-Attestation`.
  static const attestation = 'X-Taro-Attestation';

  /// `X-Taro-AI-Consent`.
  static const aiConsent = 'X-Taro-AI-Consent';

  /// `If-None-Match`.
  static const ifNoneMatch = 'If-None-Match';

  /// `ETag` (response).
  static const etag = 'etag';

  /// `Date` (response).
  static const date = 'date';

  /// `Retry-After` (response).
  static const retryAfter = 'retry-after';

  /// `Content-Type`.
  static const contentType = 'Content-Type';

  /// The JSON content type of every body (03 §2.1).
  static const json = 'application/json; charset=utf-8';
}

/// Per-request state carried in [RequestOptions.extra] between the
/// interceptors (it survives the retries, which re-send the same options).
extension TaroRequestContext on RequestOptions {
  static const String _endpointKey = 'taro.endpoint';
  static const String _idempotencyKey = 'taro.idempotencyKey';
  static const String _attemptKey = 'taro.attempt';
  static const String _authRetriedKey = 'taro.authRetried';

  /// The endpoint of this request, or `null` for a foreign request.
  Endpoint? get endpoint => extra[_endpointKey] as Endpoint?;

  set endpoint(Endpoint? value) => extra[_endpointKey] = value;

  /// The `Idempotency-Key` of the user action, reused on every retry.
  String? get idempotencyKey => extra[_idempotencyKey] as String?;

  set idempotencyKey(String? value) => extra[_idempotencyKey] = value;

  /// The 1-based attempt number of the request in flight.
  int get attempt => (extra[_attemptKey] as int?) ?? 0;

  set attempt(int value) => extra[_attemptKey] = value;

  /// Whether the request was already retried after a token refresh.
  bool get authRetried => (extra[_authRetriedKey] as bool?) ?? false;

  set authRetried(bool value) => extra[_authRetriedKey] = value;
}

/// Builds the [DioException] that carries an already-mapped [failure].
///
/// The error interceptor and the `WorkerClient` pass such exceptions
/// through unchanged.
DioException failureException(
  RequestOptions options,
  Failure failure, {
  Response<Object?>? response,
}) => DioException(
  requestOptions: options,
  response: response,
  error: failure,
  type: response == null
      ? DioExceptionType.unknown
      : DioExceptionType.badResponse,
);

/// The initial [RequestOptions.extra] of a call to [endpoint].
Map<String, Object?> requestExtra(Endpoint endpoint, {String? idempotencyKey}) {
  final options = RequestOptions()
    ..endpoint = endpoint
    ..idempotencyKey = idempotencyKey;
  return options.extra;
}
