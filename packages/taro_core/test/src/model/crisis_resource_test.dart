import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'model_fixtures.dart';

void main() {
  group('CrisisResource', () {
    // R2-03: `verifiedAt: null` in the bundled source maps to the epoch
    // sentinel; such an entry is not verified and shows no "Last checked".
    test('isVerified is false only for the unverified sentinel', () {
      final r = helpline('Telefonseelsorge');
      expect(r.isVerified, isTrue);
      expect(
        r.copyWith(verifiedAt: CrisisResource.unverifiedAt).isVerified,
        isFalse,
      );
      expect(CrisisResource.unverifiedAt, DateTime.utc(1970));
    });

    test('JSON round trip omits absent optional fields', () {
      final r = helpline('Telefonseelsorge');
      final json = r.toJson();
      expect(json, {
        'name': 'Telefonseelsorge',
        'phone': '0800 111 0 111',
        'languages': ['de'],
        'verifiedAt': '2026-09-01T00:00:00Z',
      });
      expect(CrisisResource.fromJson(json), r);
      final full = r.copyWith(
        sms: '116123',
        url: 'https://x.org',
        hours: '24/7',
      );
      expect(CrisisResource.fromJson(full.toJson()), full);
    });

    test('languages default to empty', () {
      final r = CrisisResource.fromJson({
        'name': 'Find A Helpline',
        'url': 'https://findahelpline.com',
        'verifiedAt': '2026-09-01',
      });
      expect(r.languages, isEmpty);
      expect(r.hasContact, isTrue);
    });

    test('requires a contact channel and verifiedAt (RC81)', () {
      expect(
        () => CrisisResource.fromJson({
          'name': 'Nothing',
          'verifiedAt': '2026-09-01T00:00:00Z',
        }),
        throwsFormatException,
      );
      expect(
        () => CrisisResource.fromJson({'name': 'x', 'phone': '1'}),
        throwsFormatException,
      );
      expect(helpline('x', phone: null).hasContact, isTrue);
    });
  });

  group('CrisisDirectory', () {
    final intl = helpline('Find A Helpline', phone: null);
    final directory = CrisisDirectory(
      countries: {
        'DE': [helpline('DE 1'), helpline('DE 2'), helpline('DE 3')],
        'BR': [helpline('BR 1')],
      },
      localeFallback: const {'de': 'DE', 'pt': 'BR', 'ar': null},
      international: [intl],
    );

    List<String> names(List<CrisisResource> list) => [
      for (final r in list) r.name,
    ];

    test('country first, capped at 3, always with international', () {
      expect(names(directory.select(country: 'de')), [
        'DE 1',
        'DE 2',
        'Find A Helpline',
      ]);
    });

    test('locale fallback when the country is unknown', () {
      expect(names(directory.select(country: 'XX', locale: 'pt')), [
        'BR 1',
        'Find A Helpline',
      ]);
      expect(names(directory.select(locale: 'de')).first, 'DE 1');
    });

    test('international only when nothing matches', () {
      expect(names(directory.select(locale: 'ar')), ['Find A Helpline']);
      expect(names(directory.select()), ['Find A Helpline']);
    });

    test('never exceeds 3 even with many international entries', () {
      final many = directory.copyWith(
        international: [intl, intl, intl, intl],
      );
      expect(many.select(country: 'DE'), hasLength(3));
      expect(many, isNot(directory));
    });

    test('parses the compiled 03 §9.5 document', () {
      final parsed = CrisisDirectory.fromJson({
        'countries': {
          'DE': [
            for (final r in directory.countries['DE']!) r.toJson(),
          ],
          'BR': [directory.countries['BR']!.single.toJson()],
        },
        'localeFallback': {'de': 'DE', 'pt': 'BR', 'ar': null},
        'international': [intl.toJson()],
      });
      expect(parsed, directory);
    });

    test('rejects a malformed document', () {
      expect(
        () => CrisisDirectory.fromJson({
          'countries': {'DE': 'nope'},
          'localeFallback': <String, Object?>{},
          'international': <Object?>[],
        }),
        throwsFormatException,
      );
    });
  });
}
