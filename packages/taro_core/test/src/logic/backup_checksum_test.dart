import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'logic_support.dart';

/// The golden fixture (02 §12, RC70); its checksum was computed
/// independently (Python `json.dumps(sort_keys=True, separators=(',', ':'),
/// ensure_ascii=False)` + SHA-256, which equals JCS for this ASCII-keyed,
/// integer-only document).
const _goldenChecksum =
    'a83d19893d77cfdfb279fd3d3999a52b03b1115d50dcd35e400ee96d91752389';

Map<String, Object?> _fixture() =>
    jsonDecode(
          File(
            'test/src/logic/fixtures/backup_v1_sample.json',
          ).readAsStringSync(),
        )
        as Map<String, Object?>;

void main() {
  group('BackupChecksum golden fixture', () {
    test('the canonical form and checksum of data match the golden', () {
      final json = _fixture();
      final data = json['data'];
      expect(
        BackupChecksum.canonicalize(data),
        File(
          'test/src/logic/fixtures/backup_v1_sample.canonical.txt',
        ).readAsStringSync(),
      );
      expect(BackupChecksum.ofJson(data), _goldenChecksum);
      expect(json['checksum'], _goldenChecksum);
      expect(BackupChecksum.matches(data, _goldenChecksum), isTrue);
    });

    test('re-exporting the parsed model gives the same checksum', () {
      final json = _fixture();
      final backup = BackupV1.fromJson(json);
      expect(BackupChecksum.of(backup.data), _goldenChecksum);
    });

    test('any change to data changes the checksum', () {
      final json = _fixture();
      final data = json['data']! as Map<String, Object?>;
      final settings = data['settings']! as Map<String, Object?>;
      settings['hapticsEnabled'] = true;
      expect(BackupChecksum.matches(data, _goldenChecksum), isFalse);
    });
  });

  group('BackupChecksum.canonicalize (RFC 8785)', () {
    test('sorts members by UTF-16 code units (RFC 8785 §3.2.3)', () {
      final input = {
        '€': 'Euro Sign',
        '\r': 'Carriage Return',
        'דּ': 'Hebrew Letter Dalet With Dagesh',
        '1': 'One',
        '\u{1F600}': 'Emoji: Grinning Face',
        '\u0080': 'Control',
        'ö': 'Latin Small Letter O With Diaeresis',
      };
      final keys = (jsonDecode(BackupChecksum.canonicalize(input)) as Map).keys
          .toList();
      expect(keys, [
        '\r',
        '1',
        '\u0080',
        'ö',
        '€',
        '\u{1F600}',
        'דּ',
      ]);
    });

    test('no whitespace; nested values', () {
      expect(
        BackupChecksum.canonicalize({
          'b': [1, true, null, 'x'],
          'a': {'d': false, 'c': <Object?>[]},
        }),
        '{"a":{"c":[],"d":false},"b":[1,true,null,"x"]}',
      );
    });

    test('string escapes follow JSON.stringify', () {
      expect(
        BackupChecksum.canonicalize('"\\\b\f\n\r\t\u0001\u001f/\u007f é'),
        r'"\"\\\b\f\n\r\t\u0001\u001f/'
        '\u007f é"',
      );
    });

    test('lone surrogates are escaped; pairs are kept', () {
      expect(BackupChecksum.canonicalize('\u{1F600}'), '"\u{1F600}"');
      expect(
        BackupChecksum.canonicalize(String.fromCharCodes([0xD83D, 0x41])),
        r'"\ud83dA"',
      );
      expect(
        BackupChecksum.canonicalize(String.fromCharCodes([0x41, 0xDE00])),
        r'"A\ude00"',
      );
      expect(
        BackupChecksum.canonicalize(String.fromCharCodes([0xDE00])),
        r'"\ude00"',
      );
      expect(
        BackupChecksum.canonicalize(String.fromCharCodes([0xD83D])),
        r'"\ud83d"',
      );
    });

    test('numbers use the ECMAScript form', () {
      final cases = <num, String>{
        0: '0',
        -7: '-7',
        1.0: '1',
        -0.0: '0',
        0.1: '0.1',
        123.456: '123.456',
        1e21: '1e+21',
        1e-7: '1e-7',
        0.000001: '0.000001',
        4.5e300: '4.5e+300',
      };
      for (final MapEntry(key: n, value: s) in cases.entries) {
        expect(BackupChecksum.canonicalize(n), s, reason: '$n');
      }
    });

    test('rejects non-JSON input', () {
      expect(
        () => BackupChecksum.canonicalize(double.nan),
        throwsArgumentError,
      );
      expect(
        () => BackupChecksum.canonicalize(double.infinity),
        throwsArgumentError,
      );
      expect(() => BackupChecksum.canonicalize({1: 'x'}), throwsArgumentError);
      expect(
        () => BackupChecksum.canonicalize(DateTime(2026)),
        throwsArgumentError,
      );
    });
  });
}
