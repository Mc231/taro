import 'package:taro_dart_tools/tokens.dart';
import 'package:test/test.dart';

Matcher _throwsToken(String part) => throwsA(
  isA<TokenException>().having((e) => e.message, 'message', contains(part)),
);

void main() {
  group('TokenColor', () {
    test('parses hex forms', () {
      expect(TokenColor.parse('#EEF0F4', 'x').dart, 'Color(0xFFEEF0F4)');
      expect(TokenColor.parse('#abc', 'x').dart, 'Color(0xFFAABBCC)');
      expect(TokenColor.parse('#11223344', 'x').dart, 'Color(0x44112233)');
    });

    test('parses rgb and rgba', () {
      expect(
        TokenColor.parse('rgba(15, 17, 32, 0.48)', 'x').dart,
        'Color(0x7A0F1120)',
      );
      expect(TokenColor.parse('rgb(1,2,3)', 'x').argb, 0xFF010203);
    });

    test('rejects bad colours', () {
      expect(() => TokenColor.parse(3, 'c'), _throwsToken('must be a string'));
      expect(() => TokenColor.parse('red', 'c'), _throwsToken('unsupported'));
      expect(
        () => TokenColor.parse('rgb(256, 0, 0)', 'c'),
        _throwsToken('> 255'),
      );
      expect(
        () => TokenColor.parse('rgba(0, 0, 0, 2)', 'c'),
        _throwsToken('alpha'),
      );
    });

    test('contrast follows WCAG', () {
      const black = TokenColor(0, 0, 0);
      const white = TokenColor(255, 255, 255);
      expect(black.contrastOn(white), closeTo(21, 1e-9));
      expect(white.contrastOn(white), closeTo(1, 1e-9));
      // A translucent foreground is composited first.
      const halfBlack = TokenColor(0, 0, 0, 128);
      final mixed = halfBlack.over(white);
      expect(mixed.r, 127);
      expect(halfBlack.contrastOn(white), mixed.contrastOn(white));
      expect(const TokenColor(10, 10, 10).luminance, lessThan(0.01));
    });
  });

  test('dartNum prints short literals', () {
    expect(dartNum(16), '16');
    expect(dartNum(16.0), '16');
    expect(dartNum(0.58), '0.58');
    expect(dartNum(-0.5), '-0.5');
  });

  test('dimensions and numbers', () {
    expect(parseDimension('16px', 'x'), 16);
    expect(parseDimension('0.58', 'x'), 0.58);
    expect(parseDimension(-2, 'x'), -2);
    expect(parseDimension({'value': 4, 'unit': 'px'}, 'x'), 4);
    expect(
      () => parseDimension({'value': 1, 'unit': 'rem'}, 'x'),
      _throwsToken('unit'),
    );
    expect(() => parseDimension('1rem', 'x'), _throwsToken('dimension'));
    expect(parseNumber('0.38', 'x'), 0.38);
    expect(parseNumber(1, 'x'), 1);
    expect(() => parseNumber('a', 'x'), _throwsToken('not a number'));
  });

  test('durations', () {
    expect(parseDurationMicros('100ms', 'x'), 100000);
    expect(parseDurationMicros('1.2s', 'x'), 1200000);
    expect(parseDurationMicros({'value': 2, 'unit': 'ms'}, 'x'), 2000);
    expect(() => parseDurationMicros('1m', 'x'), _throwsToken('duration'));
    expect(
      () => parseDurationMicros({'value': 2, 'unit': 'h'}, 'x'),
      _throwsToken('duration'),
    );
    expect(dartDuration(100000), 'Duration(milliseconds: 100)');
    expect(dartDuration(1500), 'Duration(microseconds: 1500)');
  });

  test('cubic Béziers and font weights', () {
    expect(parseCubicBezier([0.2, 0, 0, 1], 'x'), [0.2, 0, 0, 1]);
    expect(() => parseCubicBezier([1, 2], 'x'), _throwsToken('four'));
    expect(parseFontWeight(500, 'x'), 500);
    expect(parseFontWeight('600', 'x'), 600);
    expect(parseFontWeight('Bold', 'x'), 700);
    expect(() => parseFontWeight(450, 'x'), _throwsToken('weight'));
    expect(() => parseFontWeight(null, 'x'), _throwsToken('weight'));
  });

  group('shadows', () {
    test('none and CSS lists', () {
      expect(parseShadow('none', 'x'), isEmpty);
      final layers = parseShadow(
        '0 1px 2px rgba(20, 23, 41, 0.08), 0 4px 12px 2px #000000',
        'x',
      );
      expect(layers, hasLength(2));
      expect(
        layers.first.dart,
        'BoxShadow(color: Color(0x14141729), offset: Offset(0, 1), '
        'blurRadius: 2)',
      );
      expect(layers.last.dart, contains('spreadRadius: 2'));
      expect(parseShadow('1px 2px #000', 'x').single.blur, 0);
    });

    test('DTCG objects', () {
      final single = parseShadow({
        'color': '#000000',
        'offsetX': '1px',
        'offsetY': '2px',
        'blur': '3px',
      }, 'x');
      expect(single.single.y, 2);
      final list = parseShadow([
        {'color': '#000000'},
      ], 'x');
      expect(list.single.blur, 0);
    });

    test('rejects the unsupported', () {
      expect(() => parseShadow(1, 's'), _throwsToken('unsupported shadow'));
      expect(() => parseShadow([1], 's'), _throwsToken('layer'));
      expect(
        () => parseShadow('inset 0 1px #000', 's'),
        _throwsToken('unsupported shadow'),
      );
      expect(() => parseShadow('0 1px', 's'), _throwsToken('unsupported'));
      expect(() => parseShadow('1px #000', 's'), _throwsToken('2–4 lengths'));
    });
  });
}
