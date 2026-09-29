import 'package:dio/dio.dart';
import 'package:taro/data/api/api_error_mapper.dart';
import 'package:taro/data/api/endpoints.dart';
import 'package:taro/data/api/request_context.dart';
import 'package:taro_core/taro_core.dart';

/// Refreshes the install token (`POST /v1/installs/token`); single-flight
/// is the caller's job (`WorkerClient.refreshToken`).
typedef TokenRefresher = Future<Result<SessionToken>> Function();

/// Second in the chain (02 §6.3): `Authorization: Bearer <installToken>` on
/// token routes; on `401 TOKEN_EXPIRED` one (shared) refresh and one retry;
/// `401 UNAUTHENTICATED`, a second expiry or a rejected refresh →
/// [SessionExpiredFailure] and `onSessionExpired` (the re-register flow).
final class AuthInterceptor extends Interceptor {
  /// Creates the interceptor; [dio] re-sends the request after a refresh.
  AuthInterceptor({
    required Dio dio,
    required SessionTokenStore tokens,
    required TokenRefresher refresh,
    void Function()? onSessionExpired,
  }) : _dio = dio,
       _tokens = tokens,
       _refresh = refresh,
       _onSessionExpired = onSessionExpired;

  final Dio _dio;
  final SessionTokenStore _tokens;
  final TokenRefresher _refresh;
  final void Function()? _onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final auth = options.endpoint?.auth ?? EndpointAuth.public;
    if (auth == EndpointAuth.public) return handler.next(options);
    switch (await _tokens.read()) {
      case Ok(value: final token?):
        options.headers[TaroHeaders.authorization] = 'Bearer ${token.token}';
        handler.next(options);
      case Ok():
        _onSessionExpired?.call();
        handler.reject(
          failureException(options, const Failure.sessionExpired()),
        );
      case Err(:final failure):
        handler.reject(failureException(options, failure));
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final options = err.requestOptions;
    if (err.error is Failure || response?.statusCode != 401) {
      return handler.next(err);
    }
    final code = ApiErrorMapper.parseEnvelope(response!.data)?.code;
    final refreshable =
        code == 'TOKEN_EXPIRED' &&
        options.endpoint?.auth == EndpointAuth.token &&
        !options.authRetried;
    if (!refreshable) {
      if (code == 'UNAUTHENTICATED' || code == 'TOKEN_EXPIRED') {
        _onSessionExpired?.call();
      }
      return handler.next(err);
    }
    switch (await _refresh()) {
      case Ok():
        options.authRetried = true;
        try {
          handler.resolve(await _dio.fetch<dynamic>(options));
        } on DioException catch (retryError) {
          handler.reject(retryError);
        }
      case Err(:final failure):
        handler.reject(
          failureException(
            options,
            _refreshFailure(failure),
            response: response,
          ),
        );
    }
  }

  /// Transport and attestation problems of the refresh surface as they are;
  /// any other refresh failure means the session is gone.
  /// A [SessionExpiredFailure] of the refresh already notified.
  Failure _refreshFailure(Failure failure) {
    final keep = switch (failure) {
      NetworkFailure() ||
      TimeoutFailure() ||
      AttestationFailure() ||
      SessionExpiredFailure() => true,
      _ => false,
    };
    if (keep) return failure;
    _onSessionExpired?.call();
    return const Failure.sessionExpired();
  }
}
