import 'package:dio/dio.dart';
import 'package:taro/data/api/api_error_mapper.dart';
import 'package:taro/data/api/request_context.dart';
import 'package:taro_core/taro_core.dart';

/// Last in the chain (02 §6.3): every [DioException] leaves carrying its
/// [Failure] in [DioException.error] ([ApiErrorMapper], RC5). An exception
/// that already carries one passes unchanged. Only the code, the status
/// and the request ID are logged, never a body or a header value.
final class ErrorInterceptor extends Interceptor {
  /// Creates the interceptor.
  ErrorInterceptor(this._mapper, {Logger? logger}) : _logger = logger;

  final ApiErrorMapper _mapper;
  final Logger? _logger;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is Failure) return handler.next(err);
    final failure = _mapper.fromDioException(err);
    final requestId = err.requestOptions.headers[TaroHeaders.requestId];
    _logger?.warning(
      '${err.requestOptions.endpoint?.id ?? err.requestOptions.path} '
      'failed: ${failure.code} '
      '(status ${err.response?.statusCode ?? '-'}, request $requestId)',
    );
    handler.next(err.copyWith(error: failure));
  }
}
