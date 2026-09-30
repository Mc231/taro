import 'dart:convert';
import 'dart:io';

import 'package:taro_dart_tools/tokens.dart';
import 'package:test/test.dart';

String fixture(String name) =>
    File('test/fixtures/tokens/$name').readAsStringSync();

TokenSet parseFixture(String name) => TokenSet.parse(jsonDecode(fixture(name)));

Matcher _throwsToken(String part) => throwsA(
  isA<TokenException>().having((e) => e.message, 'message', contains(part)),
);

Map<String, Object?> _doc(Map<String, Object?> body) => {
  r'$extensions': {
    'taro.modes': ['light', 'dark'],
  },
  ...body,
};

void main() {
  test('parses the pass fixture in document order', () {
    final set = parseFixture('pass.tokens.json');
    expect(set.modes, ['light', 'dark']);
    expect(set.tokens.keys.first, 'color.bg.canvas');
    expect(set['color.bg.canvas'].type, 'color');
    expect(set['color.bg.canvas'].description, 'Canvas.');
    expect(set['color.bg.canvas'].isModed, isTrue);
    expect(set['color.bg.canvas'].path, ['color', 'bg', 'canvas']);
    expect(set['space.4'].isModed, isFalse);
    expect(set['space.4'].rawIn('dark'), '12px');
    expect(set['motion.duration.fast'].reducedMotion, '0ms');
    expect(() => set['nope'], _throwsToken('unknown token'));
  });

  test('resolves aliases per mode, also inside composites', () {
    final set = parseFixture('pass.tokens.json');
    expect(set.resolve('color.text.link', 'dark'), '#EEEEEE');
    final body = set.resolve('type.body', 'light')! as Map<String, Object?>;
    expect(body['fontFamily'], 'Sans');
    expect(set.resolveValue(['{space.4}'], 'light'), ['12px']);
    expect(TokenSet.aliasOf('{a.b}'), 'a.b');
    expect(TokenSet.aliasOf('a.b'), isNull);
    expect(TokenSet.aliasOf(3), isNull);
  });

  test('missing mode is an error (fixture)', () {
    expect(
      () => parseFixture('fail_missing_mode.tokens.json'),
      _throwsToken('color.bg.canvas: missing mode "dark"'),
    );
  });

  test('alias cycle is an error (fixture)', () {
    final set = parseFixture('fail_alias_cycle.tokens.json');
    expect(
      () => set.resolve('space.a', 'light'),
      _throwsToken('alias cycle: space.a -> space.b -> space.c -> space.a'),
    );
  });

  test('unknown alias target', () {
    final set = TokenSet.parse(
      _doc({
        'space': {
          'a': {r'$type': 'dimension', r'$value': '{space.zz}'},
        },
      }),
    );
    expect(
      () => set.resolve('space.a', 'light'),
      _throwsToken('space.a: alias to unknown token "space.zz"'),
    );
  });

  final malformed = <String, (Object?, String)>{
    'not an object': ([], 'top level must be a JSON object'),
    'no modes': (<String, Object?>{}, 'must list the modes'),
    'bad extensions': (
      {r'$extensions': 3},
      r'$extensions must be an object',
    ),
    'no tokens': (_doc({}), 'no tokens found'),
    'dotted name': (
      _doc({
        'a.b': {r'$type': 'number', r'$value': 1},
      }),
      'invalid name',
    ),
    'leaf not an object': (_doc({'a': 1}), 'must be a token or a group'),
    'no type': (
      _doc({
        'a': {r'$value': 1},
      }),
      r'a: no $type',
    ),
    'modes not an object': (
      _doc({
        'a': {
          r'$type': 'number',
          r'$value': 1,
          r'$extensions': {'taro.modes': 1},
        },
      }),
      'must be an object',
    ),
    'undeclared mode': (
      _doc({
        'a': {
          r'$type': 'number',
          r'$value': 1,
          r'$extensions': {
            'taro.modes': {'light': 1, 'dark': 1, 'sepia': 1},
          },
        },
      }),
      'undeclared mode "sepia"',
    ),
    'colour without modes': (
      _doc({
        'c': {r'$type': 'color', r'$value': '#FFFFFF'},
      }),
      'c: missing modes (every color needs light and dark)',
    ),
    'reduced motion without value': (
      _doc({
        'm': {
          r'$type': 'duration',
          r'$value': '1ms',
          r'$extensions': {'taro.reducedMotion': <String, Object?>{}},
        },
      }),
      r'needs a $value',
    ),
    'reduced motion of another type': (
      _doc({
        'm': {
          r'$type': 'duration',
          r'$value': '1ms',
          r'$extensions': {
            'taro.reducedMotion': {r'$type': 'number', r'$value': 0},
          },
        },
      }),
      'differs from "duration"',
    ),
  };
  for (final MapEntry(key: name, value: (json, message)) in malformed.entries) {
    test('rejects: $name', () {
      expect(() => TokenSet.parse(json), _throwsToken(message));
    });
  }

  test('TokenException prints its message', () {
    expect(const TokenException('boom').toString(), 'boom');
  });
}
