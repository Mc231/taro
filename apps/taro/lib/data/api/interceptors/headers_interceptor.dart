import 'package:dio/dio.dart';
import 'package:taro/data/api/request_context.dart';
import 'package:taro/data/api/server_clock.dart';
import 'package:taro_core/taro_core.dart';

/// First in the chain (02 §6.3): the common `X-Taro-*` headers, a new
/// `X-Request-Id` per attempt and the action's `Idempotency-Key`; on the way
/// back it feeds every `Date` header into the [ServerClockTracker].
final class HeadersInterceptor extends Interceptor {
  /// Creates the interceptor. [flavor] is sent only when not `null` (dev and
  /// staging builds); [locale] is read per request.
  HeadersInterceptor({
    required AppPlatform platform,
    required String appVersion,
    required String Function() locale,
    required IdGenerator ids,
    required Clock clock,
    required ServerClockTracker serverClock,
    String? flavor,
  }) : _platform = platform,
       _appVersion = appVersion,
       _locale = locale,
       _ids = ids,
       _clock = clock,
       _serverClock = serverClock,
       _flavor = flavor;

  final AppPlatform _platform;
  final String _appVersion;
  final String Function() _locale;
  final IdGenerator _ids;
  final Clock _clock;
  final ServerClockTracker _serverClock;
  final String? _flavor;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options
      ..attempt = options.attempt + 1
      ..headers[TaroHeaders.platform] = _platform.name
      ..headers[TaroHeaders.appVersion] = _appVersion
      ..headers[TaroHeaders.locale] = _locale()
      ..headers[TaroHeaders.requestId] = _ids.uuidV4();
    if (_flavor != null) options.headers[TaroHeaders.flavor] = _flavor;
    final key = options.idempotencyKey;
    if (key != null) options.headers[TaroHeaders.idempotencyKey] = key;
    if (options.data != null) {
      options.headers[TaroHeaders.contentType] = TaroHeaders.json;
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _recordDate(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) _recordDate(response);
    handler.next(err);
  }

  void _recordDate(Response<dynamic> response) => _serverClock.recordDateHeader(
    response.headers.value(TaroHeaders.date),
    receivedAt: _clock.now(),
  );
}
