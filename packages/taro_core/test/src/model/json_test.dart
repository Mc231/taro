import 'package:taro_core/src/model/json.dart';
import 'package:test/test.dart';

void main() {
  group('readers', () {
    final json = <String, Object?>{
      's': 'x',
      'i': 3,
      'd': 3.0,
      'f': 3.5,
      'n': null,
      'm': {'a': 1},
      'ms': [
        {'a': 1},
      ],
      'ss': ['a', 'b'],
      'bad': [1],
      't': '2026-09-26T10:12:44+02:00',
      'e': 'b',
      'ld': '2026-09-26',
    };
    const byWire = {'a': 1, 'b': 2};

    test('required and optional values', () {
      expect(req<String>(json, 's'), 'x');
      expect(() => req<String>(json, 'i'), throwsFormatException);
      expect(opt<String>(json, 'n'), isNull);
      expect(opt<String>(json, 'missing'), isNull);
      expect(() => opt<String>(json, 'i'), throwsFormatException);
      expect(reqInt(json, 'i'), 3);
      expect(reqInt(json, 'd'), 3);
      expect(() => reqInt(json, 'f'), throwsFormatException);
      expect(optInt(json, 'n'), isNull);
      expect(optInt(json, 'd'), 3);
      expect(reqMap(json, 'm'), {'a': 1});
      expect(optMap(json, 'n'), isNull);
      expect(reqMaps(json, 'ms'), hasLength(1));
      expect(() => reqMaps(json, 'ss'), throwsFormatException);
      expect(reqStrings(json, 'ss'), ['a', 'b']);
      expect(() => reqStrings(json, 'bad'), throwsFormatException);
    });

    test('instants are converted to UTC', () {
      expect(reqInstant(json, 't'), DateTime.utc(2026, 9, 26, 8, 12, 44));
      expect(optInstant(json, 'n'), isNull);
      expect(optInstant(json, 't')!.isUtc, isTrue);
      expect(() => reqInstant(json, 's'), throwsFormatException);
    });

    test('enums by wire name', () {
      expect(reqEnum(json, 'e', byWire), 2);
      expect(() => reqEnum(json, 's', byWire), throwsFormatException);
      expect(optEnum(json, 'n', byWire), isNull);
      expect(optEnum(json, 'e', byWire), 2);
      expect(() => optEnum(json, 's', byWire), throwsFormatException);
    });

    test('local dates', () {
      expect(reqLocalDate(json, 'ld'), '2026-09-26');
      expect(() => reqLocalDate(json, 's'), throwsFormatException);
    });
  });

  group('formatInstant', () {
    test('omits a zero fraction and always ends in Z', () {
      expect(
        formatInstant(DateTime.utc(2026, 9, 26, 8, 15)),
        '2026-09-26T08:15:00Z',
      );
      expect(
        formatInstant(DateTime.utc(2026, 9, 26, 8, 15, 0, 120)),
        '2026-09-26T08:15:00.120Z',
      );
      expect(
        formatInstant(DateTime.utc(2026, 9, 26, 8, 15, 0, 0, 5)),
        '2026-09-26T08:15:00.000005Z',
      );
      expect(
        formatInstant(DateTime.utc(999)),
        '0999-01-01T00:00:00Z',
      );
    });

    test('converts local times to UTC and round trips', () {
      final t = DateTime.utc(2026, 1, 2, 3, 4, 5, 6).toLocal();
      expect(parseInstant('t', formatInstant(t)), t.toUtc());
    });
  });
}
