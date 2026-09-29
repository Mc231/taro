import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// One request the [ScriptedHttpAdapter] received.
final class RecordedRequest {
  RecordedRequest(this.options, this.body)
    : method = options.method,
      path = options.uri.path,
      query = options.uri.queryParameters,
      headers = {
        for (final e in options.headers.entries)
          e.key.toLowerCase(): e.value?.toString(),
      };

  /// The options dio sent (timeouts, extra).
  final RequestOptions options;

  /// The HTTP method.
  final String method;

  /// The URL path.
  final String path;

  /// The query.
  final Map<String, String> query;

  /// Headers, keys in lower case.
  final Map<String, String?> headers;

  /// The raw body bytes (empty without a body).
  final Uint8List body;

  /// A header value by case-insensitive [name].
  String? header(String name) => headers[name.toLowerCase()];

  /// The body decoded as JSON, or `null` without a body.
  Object? get json => body.isEmpty ? null : jsonDecode(utf8.decode(body));

  /// `METHOD path`.
  String get route => '$method $path';

  @override
  String toString() => route;
}

/// Builds the reply to one request.
typedef Responder = FutureOr<ResponseBody> Function(RecordedRequest request);

/// A dio [HttpClientAdapter] that answers from a script, in order, and
/// records every request. Running out of script is a test bug.
final class ScriptedHttpAdapter implements HttpClientAdapter {
  final List<RecordedRequest> requests = [];
  final List<Responder> _script = [];

  /// Scripted replies not used yet.
  int get pending => _script.length;

  /// Queues [responder].
  void enqueue(Responder responder) => _script.add(responder);

  /// Queues a reply with [status] and a JSON [json] body (or [raw] text).
  void reply(
    int status, {
    Object? json,
    String? raw,
    Map<String, String> headers = const {},
  }) =>
      enqueue((_) => response(status, json: json, raw: raw, headers: headers));

  /// Queues [times] identical replies.
  void replyTimes(
    int times,
    int status, {
    Object? json,
    Map<String, String> headers = const {},
  }) {
    for (var i = 0; i < times; i++) {
      reply(status, json: json, headers: headers);
    }
  }

  /// Queues a Worker error envelope with [code].
  void error(
    int status,
    String code, {
    Map<String, Object?>? details,
    int? retryAfterSec,
    Map<String, String> headers = const {},
  }) => reply(
    status,
    json: envelope(code, details: details, retryAfterSec: retryAfterSec),
    headers: headers,
  );

  /// Queues a transport failure of [type].
  void fail(DioExceptionType type, {Object? error}) => enqueue(
    (request) => throw DioException(
      requestOptions: request.options,
      type: type,
      error: error,
    ),
  );

  /// Queues a thrown [error] (not a [DioException]).
  void throwError(Exception error) => enqueue((_) => throw error);

  /// Queues a thrown [error] of the [Error] kind.
  void throwBug(Error error) => enqueue((_) => throw error);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[];
    if (requestStream != null) {
      await requestStream.forEach(bytes.addAll);
    }
    final request = RecordedRequest(options, Uint8List.fromList(bytes));
    requests.add(request);
    if (_script.isEmpty) {
      throw StateError('No scripted reply for ${request.route}');
    }
    return _script.removeAt(0)(request);
  }

  @override
  void close({bool force = false}) {}

  /// A response body.
  static ResponseBody response(
    int status, {
    Object? json,
    String? raw,
    Map<String, String> headers = const {},
  }) {
    final text = raw ?? (json == null ? '' : jsonEncode(json));
    return ResponseBody.fromString(
      text,
      status,
      headers: {
        HttpHeaders.contentTypeHeader: ['application/json; charset=utf-8'],
        for (final e in headers.entries) e.key.toLowerCase(): [e.value],
      },
    );
  }

  /// The 03 §2.2 envelope.
  static Map<String, Object?> envelope(
    String code, {
    Map<String, Object?>? details,
    int? retryAfterSec,
  }) => {
    'error': {
      'code': code,
      'message': 'scripted $code',
      'requestId': 'req-$code',
      'retryable': false,
      'retryAfterSec': retryAfterSec,
      'details': ?details,
    },
  };
}
