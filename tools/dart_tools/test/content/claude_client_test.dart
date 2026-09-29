import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taro_dart_tools/content.dart';
import 'package:test/test.dart';

const _request = ClaudeRequest(
  model: 'claude-opus-5',
  system: 'sys',
  user: 'user',
  schema: {'type': 'object'},
);

AnthropicHttpClient _client(
  Future<http.Response> Function(http.Request) handler, {
  bool fallbacks = true,
}) => AnthropicHttpClient(
  apiKey: 'key',
  httpClient: MockClient(handler),
  refusalFallbacks: fallbacks,
);

http.Response _json(Object body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

Map<String, Object?> _message(String text, {String stop = 'end_turn'}) => {
  'stop_reason': stop,
  'content': [
    {'type': 'thinking', 'thinking': ''},
    {'type': 'text', 'text': text},
  ],
};

Future<String> _failure(AnthropicHttpClient client) async {
  try {
    await client.complete(_request);
  } on ClaudeException catch (e) {
    return e.toString();
  }
  fail('expected a ClaudeException');
}

void main() {
  test('sends a structured-output request and decodes the answer', () async {
    late http.Request sent;
    final client = _client((request) async {
      sent = request;
      return _json(_message('{"a": "ü"}'));
    });
    expect(await client.complete(_request), {'a': 'ü'});
    expect(sent.url.toString(), 'https://api.anthropic.com/v1/messages');
    expect(sent.headers['x-api-key'], 'key');
    expect(sent.headers['anthropic-version'], '2023-06-01');
    expect(sent.headers['anthropic-beta'], 'server-side-fallback-2026-07-01');
    final body = jsonDecode(sent.body) as Map<String, Object?>;
    expect(body['model'], 'claude-opus-5');
    expect(body['max_tokens'], 16000);
    expect(body['system'], 'sys');
    expect(body['fallbacks'], 'default');
    expect(body['output_config'], {
      'format': {
        'type': 'json_schema',
        'schema': {'type': 'object'},
      },
    });
  });

  test('without refusal fallbacks', () async {
    late http.Request sent;
    final client = _client((request) async {
      sent = request;
      return _json(_message('{}'));
    }, fallbacks: false);
    await client.complete(_request);
    expect(sent.headers.containsKey('anthropic-beta'), isFalse);
    expect((jsonDecode(sent.body) as Map).containsKey('fallbacks'), isFalse);
  });

  test('HTTP errors', () async {
    final long = 'x' * 400;
    expect(
      await _failure(_client((_) async => http.Response(long, 529))),
      contains('HTTP 529: ${'x' * 300}…'),
    );
    expect(
      await _failure(_client((_) async => http.Response('bad', 400))),
      contains('HTTP 400: bad'),
    );
  });

  test('network error', () async {
    final client = _client((_) async => throw http.ClientException('down'));
    expect(await _failure(client), contains('network error: down'));
  });

  test('refusal and truncation', () async {
    expect(
      await _failure(
        _client(
          (_) async => _json({
            ..._message(''),
            'stop_reason': 'refusal',
            'stop_details': {'category': 'cyber'},
          }),
        ),
      ),
      contains('refused (category: cyber)'),
    );
    expect(
      await _failure(
        _client((_) async => _json({'stop_reason': 'refusal'})),
      ),
      contains('category: unknown'),
    );
    expect(
      await _failure(
        _client((_) async => _json(_message('{', stop: 'max_tokens'))),
      ),
      contains('truncated'),
    );
  });

  test('malformed responses', () async {
    expect(
      await _failure(_client((_) async => http.Response('nope', 200))),
      contains('response is not JSON'),
    );
    expect(
      await _failure(_client((_) async => _json([1]))),
      contains('response is not a JSON object'),
    );
    expect(
      await _failure(_client((_) async => _json(_message('[1]')))),
      contains('answer is not a JSON object'),
    );
    expect(
      await _failure(_client((_) async => _json({'stop_reason': 'end_turn'}))),
      contains('answer is not a JSON object'),
    );
  });

  test('decodeAnswer accepts a fenced answer', () {
    expect(decodeAnswer('```json\n{"a": 1}\n```'), {'a': 1});
    expect(() => decodeAnswer('x'), throwsA(isA<ClaudeException>()));
  });

  test('the default client and endpoint are constructible', () {
    final client = AnthropicHttpClient(apiKey: 'k');
    expect(client.refusalFallbacks, isTrue);
  });
}
