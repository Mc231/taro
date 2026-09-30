// Corpus lines stay whole so each reads like a real log line.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/logging/redactor.dart';

/// Values that must never survive redaction.
const _installId = '7c1e4b2a-93d5-4f60-8a17-2b9c0e5d4f31';
const _installSecret = 'qW3rT7yU9iO1pA5sD8fG2hJ4kL6zX0cV'; // gitleaks:allow
const _deviceKey =
    'Zm9vYmFyYmF6cXV4MTIzNDU2Nzg5MGFiY2RlZmdoaWo'; // gitleaks:allow
const _sessionJwt =
    'eyJhbGciOiJFZERTQSJ9.eyJzdWIiOiI3YzFlNGIyYSIsImV4cCI6MTc5MH0.' // gitleaks:allow
    'c2lnbmF0dXJlLWJ5dGVzLWhlcmUtMTIzNDU2';
const _appleJws =
    'eyJhbGciOiJFUzI1NiIsIng1YyI6WyJNSUlF' // gitleaks:allow
    'Il19.eyJ0cmFuc2FjdGlvbklkIjoiMjAwMDAwMDEifQ.MEUCIQDx9sig';
const _playPurchaseToken =
    'opaque-token-up-to-150-characters.AO-J1OyNtKq3Xr8vWz2LmP5sQ7tU9wY1a'
    'Bc3De5Fg7Hi9Jk1Lm3No5Pq7Rs9Tu1Vw3Xy5Z';
const _integrityToken =
    'eyJhbGciOiJBMjU2S1ciLCJlbmMiOiJBMjU2R0NNIn0.key.iv.ciphertext.tag';
const _question = 'Will my sister forgive me, and should I call her?';
const _note = 'Felt anxious after the Tower card, talked to M.';
const _body = 'I dreamt about my late father';

/// The sensitive corpus: realistic log lines carrying each secret in the
/// shapes the app produces (JSON bodies, Dart toString, headers, URLs,
/// free text).
final List<String> _corpus = <String>[
  'POST /v1/installs {"installId":"$_installId","installSecret":"$_installSecret","platform":"ios"}',
  'register failed: RegisterRequestDto(installId: $_installId, installSecret: $_installSecret)',
  'headers: {Authorization: Bearer $_sessionJwt, X-Taro-Locale: en}',
  'Authorization: Bearer $_sessionJwt',
  'token refreshed: {"token":"$_sessionJwt","expiresAt":"2026-10-01T00:00:00Z"}',
  'verify apple {"signedTransaction":"$_appleJws","productId":"com.vshyrochuk.taro.readings_3"}',
  'raw jws in text: $_appleJws',
  'verify google {"purchaseToken":"$_playPurchaseToken","productId":"x"}',
  'purchaseToken=$_playPurchaseToken&packageName=com.vshyrochuk.taro',
  'play token $_playPurchaseToken seen',
  'register android {"integrityToken":"$_integrityToken","deviceKey":"$_deviceKey"}',
  'deviceKey: $_deviceKey',
  'X-Taro-Attestation: $_integrityToken',
  'reading submit {"question":"$_question","spreadId":"three_card"}',
  "reading submit {'question': '$_question', 'spreadId': 'three_card'}",
  'Reading(id: r1, question: $_question)',
  'note saved {"note":"$_note","readingId":"r1"}',
  'setNote(note: $_note)',
  'report {"reason":"harmful","body":"$_body"}',
  'import row {"reading":{"question":"$_question","note":"$_note"},"id":"r2"}',
  'escaped {"question":"she said \\"$_question\\" twice"}',
  'install $_installId registered',
];

const List<String> _secrets = [
  _installSecret,
  _deviceKey,
  _sessionJwt,
  _appleJws,
  _playPurchaseToken,
  _integrityToken,
  _question,
  _note,
  _body,
  _installId,
];

void main() {
  late Redactor redactor;

  setUp(() {
    redactor = Redactor()
      ..registerInstallId(_installId)
      ..registerSecret(_installSecret)
      ..registerSecret(_deviceKey);
  });

  test('no secret of the sensitive corpus survives', () {
    for (final line in _corpus) {
      final redacted = redactor.redact(line);
      for (final secret in _secrets) {
        expect(redacted, isNot(contains(secret)), reason: line);
      }
      // Long fragments of the secrets must not survive either.
      for (final secret in _secrets.where((s) => s.length > 24)) {
        expect(
          redacted,
          isNot(contains(secret.substring(8, 24))),
          reason: line,
        );
      }
    }
  });

  test('without registration, static rules still cover the corpus', () {
    final bare = Redactor();
    for (final line in _corpus.where((l) => !l.startsWith('install '))) {
      final redacted = bare.redact(line);
      for (final secret in _secrets.where((s) => s != _installId)) {
        expect(redacted, isNot(contains(secret)), reason: line);
      }
    }
  });

  test('install IDs keep their first 8 characters', () {
    expect(
      redactor.redact('install $_installId registered'),
      'install 7c1e4b2a… registered',
    );
    expect(
      Redactor().redact('{"installId":"$_installId"}'),
      '{"installId":"7c1e4b2a…"}',
    );
    expect(
      Redactor().redact('X-Taro-Install-Id: $_installId'),
      'X-Taro-Install-Id: 7c1e4b2a…',
    );
    expect(Redactor.truncateInstallId('short'), 'short');
  });

  test('keeps ordinary text readable', () {
    const lines = [
      'sync started (reason: launch)',
      'balance synced: free=1 paid=3',
      'GET /v1/balance -> 200 in 143 ms',
      'taro.sync: step=balance, result=ok',
      'package:taro/services/logging/logging_logger.dart 42:7',
      'sha256 9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08',
      'https://api.taro.vshyrochuk.com/v1/readings',
      'nothing to see: ',
    ];
    for (final line in lines) {
      expect(redactor.redact(line), line);
    }
  });

  test('structured shapes keep their punctuation', () {
    expect(
      redactor.redact('{"token":"abc","trust":"high"}'),
      '{"token":"<redacted>","trust":"high"}',
    );
    expect(
      redactor.redact("{'note': 'x', 'id': 1}"),
      "{'note': '<redacted>', 'id': 1}",
    );
    expect(
      redactor.redact('a?sessionToken=abc&b=1'),
      'a?sessionToken=<redacted>&b=1',
    );
    expect(
      redactor.redact('Dto(transferToken: abc , trust: low)'),
      'Dto(transferToken: <redacted> , trust: low)',
    );
    expect(
      redactor.redact('{"reading":[{"a":"}"}],"id":"r"}'),
      '{"reading":<redacted>,"id":"r"}',
    );
    expect(
      redactor.redact('question: a, b\nnext line'),
      'question: <redacted>\nnext line',
    );
    expect(
      redactor.redact('{"question":"unterminated'),
      '{"question":"<redacted>"',
    );
    expect(redactor.redact('{"note":{"open":1'), '{"note":<redacted>');
    expect(redactor.redact('token: '), 'token: ');
    expect(redactor.redact('"body": "'), '"body": "<redacted>"');
  });

  test('bearer and basic credentials without a key', () {
    expect(
      redactor.redact('sent Bearer abc123 and Basic dXNlcjpwdw=='),
      'sent Bearer <redacted> and Basic <redacted>',
    );
  });

  test('registration ignores values too short to be secrets', () {
    final r = Redactor()
      ..registerSecret('abc')
      ..registerInstallId('12345678');
    expect(r.redact('abc 12345678'), 'abc 12345678');
  });

  test('redactMap scrubs sensitive keys and every value', () {
    final map = redactor.redactMap({
      'step': 'balance',
      'installSecret': 'anything',
      'question': 'why',
      'installId': _installId,
      'detail': 'Bearer abc',
      'count': 3,
    });
    expect(map, {
      'step': 'balance',
      'installSecret': kRedacted,
      'question': kRedacted,
      'installId': '7c1e4b2a…',
      'detail': 'Bearer <redacted>',
      'count': '3',
    });
  });
}
