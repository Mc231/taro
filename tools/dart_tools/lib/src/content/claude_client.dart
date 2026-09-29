/// The Claude call behind `tools/content translate`: a [ClaudeClient] port,
/// the real [AnthropicHttpClient] (Messages API over `package:http`) and the
/// errors it reports. Tests use a fake client; the HTTP client is tested
/// against `package:http/testing.dart`.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

/// Default model: the paid-reading model of 03 BE10 / §8.2 `ai.model.paid`.
const String kDefaultTranslateModel = 'claude-opus-5';

/// One structured-output request.
final class ClaudeRequest {
  /// Creates a request.
  const ClaudeRequest({
    required this.model,
    required this.system,
    required this.user,
    required this.schema,
    this.maxTokens = 16000,
  });

  /// Model ID, e.g. `claude-opus-5`.
  final String model;

  /// System prompt (rules, style guide, glossary, banned phrases).
  final String system;

  /// User message (the English source as JSON).
  final String user;

  /// JSON Schema the answer must follow (`output_config.format`).
  final Map<String, Object?> schema;

  /// Output cap.
  final int maxTokens;
}

/// A failed call: HTTP error, refusal, truncation or unparsable output.
final class ClaudeException implements Exception {
  /// Creates the exception.
  const ClaudeException(this.message);

  /// What went wrong.
  final String message;

  @override
  String toString() => 'ClaudeException: $message';
}

/// Port for one Claude call that returns a JSON object.
// ignore: one_member_abstracts, a port with fakes (CLAUDE.md rule 2).
abstract interface class ClaudeClient {
  /// Sends [request]; returns the decoded JSON object or throws a
  /// [ClaudeException].
  Future<Map<String, Object?>> complete(ClaudeRequest request);
}

/// The Messages API client (`POST /v1/messages`, `anthropic-version:
/// 2023-06-01`) with structured output and server-side refusal fallbacks.
final class AnthropicHttpClient implements ClaudeClient {
  /// Creates a client for [apiKey]; [httpClient] defaults to a new one.
  AnthropicHttpClient({
    required String apiKey,
    http.Client? httpClient,
    Uri? endpoint,
    this.refusalFallbacks = true,
  }) : _apiKey = apiKey,
       _http = httpClient ?? http.Client(),
       _endpoint =
           endpoint ?? Uri.parse('https://api.anthropic.com/v1/messages');

  final String _apiKey;
  final http.Client _http;
  final Uri _endpoint;

  /// Sends `fallbacks: "default"` with the `server-side-fallback-2026-07-01`
  /// beta, so a refused request is retried on a fallback model.
  final bool refusalFallbacks;

  @override
  Future<Map<String, Object?>> complete(ClaudeRequest request) async {
    final body = <String, Object?>{
      'model': request.model,
      'max_tokens': request.maxTokens,
      'system': request.system,
      'messages': [
        {'role': 'user', 'content': request.user},
      ],
      'output_config': {
        'format': {'type': 'json_schema', 'schema': request.schema},
      },
      if (refusalFallbacks) 'fallbacks': 'default',
    };
    final http.Response response;
    try {
      response = await _http.post(
        _endpoint,
        headers: {
          'content-type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
          if (refusalFallbacks)
            'anthropic-beta': 'server-side-fallback-2026-07-01',
        },
        body: jsonEncode(body),
      );
    } on http.ClientException catch (e) {
      throw ClaudeException('network error: ${e.message}');
    }
    final text = utf8.decode(response.bodyBytes);
    if (response.statusCode != 200) {
      final snippet = text.length > 300 ? '${text.substring(0, 300)}…' : text;
      throw ClaudeException('HTTP ${response.statusCode}: $snippet');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const ClaudeException('response is not JSON');
    }
    if (decoded is! Map<String, Object?>) {
      throw const ClaudeException('response is not a JSON object');
    }
    final stop = decoded['stop_reason'];
    if (stop == 'refusal') {
      final details = decoded['stop_details'];
      final category = details is Map ? details['category'] : null;
      throw ClaudeException('refused (category: ${category ?? 'unknown'})');
    }
    if (stop == 'max_tokens') {
      throw const ClaudeException('output truncated at max_tokens');
    }
    final content = decoded['content'];
    final answer = StringBuffer();
    if (content is List) {
      for (final block in content) {
        if (block is Map && block['type'] == 'text') {
          answer.write(block['text']);
        }
      }
    }
    return decodeAnswer(answer.toString());
  }
}

/// Decodes the model's JSON answer (tolerating a Markdown code fence).
Map<String, Object?> decodeAnswer(String text) {
  var raw = text.trim();
  final fence = RegExp(r'^```[a-z]*\n([\s\S]*)\n```$').firstMatch(raw);
  if (fence != null) raw = fence[1]!.trim();
  try {
    final value = jsonDecode(raw);
    if (value is Map<String, Object?>) return value;
  } on FormatException {
    // Reported below.
  }
  throw const ClaudeException('answer is not a JSON object');
}
