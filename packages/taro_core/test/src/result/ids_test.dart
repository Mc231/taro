import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

/// All 78 valid card IDs per GLOSSARY §1.
List<String> allCardIds() => [
  for (var i = 0; i <= 21; i++) 'major_${i.toString().padLeft(2, '0')}',
  for (final suit in ['wands', 'cups', 'swords', 'pentacles'])
    for (var r = 1; r <= 14; r++) '${suit}_${r.toString().padLeft(2, '0')}',
];

void main() {
  group('CardId', () {
    test('accepts exactly the 78 RC1 IDs', () {
      final ids = allCardIds();
      expect(ids, hasLength(78));
      for (final raw in ids) {
        expect(CardId.isValid(raw), isTrue, reason: raw);
        expect(CardId.parse(raw).value, raw);
        expect(CardId.tryParse(raw), CardId(raw));
      }
    });

    const invalid = [
      '',
      'major_22',
      'major_0',
      'major_000',
      'major_00_fool',
      'cups_00',
      'cups_15',
      'cups_1',
      'Cups_01',
      'coins_01',
      'pentacles_king',
      ' major_00',
      'major_00 ',
      'major_-1',
    ];
    for (final raw in invalid) {
      test('rejects "$raw"', () {
        expect(CardId.isValid(raw), isFalse);
        expect(CardId.tryParse(raw), isNull);
        expect(() => CardId.parse(raw), throwsFormatException);
      });
    }
  });

  group('typed IDs', () {
    test('wrap and expose the raw string', () {
      expect(const SpreadId('celtic_cross').value, 'celtic_cross');
      expect(const PositionId('past').value, 'past');
      expect(const ReadingId('r-1').value, 'r-1');
      expect(const InstallId('i-1').value, 'i-1');
      expect(
        const ProductId('com.vshyrochuk.taro.readings_3').value,
        'com.vshyrochuk.taro.readings_3',
      );
      expect(const IntentId('in-1').value, 'in-1');
    });

    test('equal when the raw strings are equal', () {
      expect(const SpreadId('single'), const SpreadId('single'));
      expect(const ReadingId('a'), isNot(const ReadingId('b')));
    });
  });
}
