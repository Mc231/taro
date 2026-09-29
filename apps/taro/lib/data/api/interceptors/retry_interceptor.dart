import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:taro/data/api/api_error_mapper.dart';
import 'package:taro/data/api/api_timeouts.dart';
import 'package:taro/data/api/request_context.dart';
import 'package:taro_core/taro_core.dart';

/// Waits for [duration]; injected so tests run the retry matrix on a fake
/// clock without real timers.
typedef Sleep = Future<void> Function(Duration duration);

/// The production [Sleep].
Future<void> realSleep(Duration duration) => Future<void>.delayed(duration);

/// Fifth in the chain (02 §6.3): at most [ApiTimeouts.maxAttempts]
/// attempts, exponential backoff 0.5 s × 2ⁿ with ±30 % jitter capped at 8 s.
///
/// Only a GET or a request carrying an `Idempotency-Key` is retried, and
/// only on a connection error, 408, 429 `reason=burst` (honouring
/// `Retry-After` ≤ 30 s), 409 `REQUEST_IN_PROGRESS` (honouring
/// `Retry-After`), 502, 503 `AI_UNAVAILABLE` and 504. Never on another 4xx,
/// `503 READINGS_DISABLED` or `503 AI_BUDGET_EXHAUSTED`. A receive timeout
/// of `POST /v1/readings` is handed to the caller, which polls (RC31).
final class RetryInterceptor extends Interceptor {
  /// Creates the interceptor; [dio] re-sends the request.
  RetryInterceptor({
    required Dio dio,
    required RandomSource random,
    required Sleep sleep,
    Logger? logger,
  }) : _dio = dio,
       _random = random,
       _sleep = sleep,
       _logger = logger;

  final Dio _dio;
  final RandomSource _random;
  final Sleep _sleep;
  final Logger? _logger;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final delay =
        err.error is Failure || options.attempt >= ApiTimeouts.maxAttempts
        ? null
        : retryDelay(err);
    if (delay == null) return handler.next(err);
    _logger?.fine(
      'retry ${options.endpoint?.id ?? options.path} '
      'attempt ${options.attempt + 1} in ${delay.inMilliseconds} ms',
    );
    await _sleep(delay);
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.reject(retryError);
    }
  }

  /// Whether [options] may be re-sent at all: a GET or an idempotent call.
  static bool isReplayable(RequestOptions options) =>
      options.method.toUpperCase() == 'GET' ||
      options.headers.containsKey(TaroHeaders.idempotencyKey);

  /// How long to wait before re-sending the request that failed with
  /// [err], or `null` when it must not be retried.
  Duration? retryDelay(DioException err) {
    final options = err.requestOptions;
    if (!isReplayable(options)) return null;
    final backoff = backoffFor(options.attempt);
    switch (err.type) {
      case DioExceptionType.connectionError ||
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout:
        return backoff;
      case DioExceptionType.receiveTimeout || DioExceptionType.transformTimeout:
        return (options.endpoint?.pollOnTimeout ?? false) ? null : backoff;
      case DioExceptionType.badResponse:
        return _statusDelay(err.response!, backoff);
      case DioExceptionType.badCertificate ||
          DioExceptionType.cancel ||
          DioExceptionType.unknown:
        return null;
    }
  }

  Duration? _statusDelay(Response<dynamic> response, Duration backoff) {
    final status = response.statusCode;
    if (status == 408 || status == 502 || status == 504) return backoff;
    final envelope = ApiErrorMapper.parseEnvelope(response.data);
    final code = envelope?.code;
    if (status == 503) return code == 'AI_UNAVAILABLE' ? backoff : null;
    final waitsForServer =
        (status == 429 &&
            code == 'RATE_LIMITED' &&
            (envelope!.details['reason'] ?? 'burst') == 'burst') ||
        (status == 409 && code == 'REQUEST_IN_PROGRESS');
    if (!waitsForServer) return null;
    final retryAfter = ApiErrorMapper.retryAfter(response.headers, envelope);
    if (retryAfter == null) return backoff;
    return retryAfter <= ApiTimeouts.maxRetryAfter ? retryAfter : null;
  }

  /// The backoff after failed attempt [attempt] (1-based):
  /// `min(8 s, 0.5 s × 2^(attempt−1) × (1 ± 0.3))`.
  Duration backoffFor(int attempt) {
    final exponent = math.max(0, attempt - 1);
    final base = ApiTimeouts.backoffBase.inMicroseconds * math.pow(2, exponent);
    const spread = ApiTimeouts.jitterPerMille;
    final jitter = _random.nextInt(2 * spread + 1) - spread;
    final micros = (base * (1000 + jitter) / 1000).round();
    return Duration(
      microseconds: math.min(micros, ApiTimeouts.backoffCap.inMicroseconds),
    );
  }
}
