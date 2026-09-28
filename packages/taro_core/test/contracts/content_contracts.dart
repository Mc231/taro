import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'contract_support.dart';

/// The `ContentRepository` contract (01 §10, 02 §5, RC26): the bundled
/// deck, spreads, card text and crisis fallback.
void runContentRepositoryContract(ContentRepository Function() create) {
  group('ContentRepository contract', () {
    late ContentRepository content;

    setUp(() => content = create());

    test('the deck is the 78 canonical cards', () async {
      final deck = expectOk(await content.deck());
      expect(deck.cards, hasLength(Deck.size));
      expect(Deck.problemsOf(deck.cards), isEmpty);
    });

    test('every v1 spread is present and consistent', () async {
      final spreads = expectOk(await content.spreads());
      expect({for (final s in spreads) s.id}, containsAll(kSpreadIds));
      for (final s in spreads) {
        expect(s.problems, isEmpty, reason: s.id.value);
      }
    });

    test('every card has English text', () async {
      for (final id in kCardIds) {
        final text = expectOk(await content.cardText(id, 'en'));
        expect(text.cardId, id);
        expect(text.name, isNotEmpty);
      }
    });

    test('an unknown locale falls back to English', () async {
      final fallback = expectOk(
        await content.cardText(const CardId('major_00'), 'xx'),
      );
      final en = expectOk(
        await content.cardText(const CardId('major_00'), 'en'),
      );
      expect(fallback, en);
    });

    test('crisis fallback resources have a contact', () async {
      final resources = expectOk(await content.fallbackCrisisResources('DE'));
      expect(resources, isNotEmpty);
      for (final r in resources) {
        expect(r.hasContact, isTrue, reason: r.name);
      }
    });
  });
}

/// The `CrisisResourcesRepository` contract (03 §9.5, RC25, RC81).
void runCrisisResourcesRepositoryContract(
  CrisisResourcesRepository Function() create,
) {
  group('CrisisResourcesRepository contract', () {
    late CrisisResourcesRepository crisis;

    setUp(() => crisis = create());

    test('the directory has international entries', () async {
      final directory = expectOk(await crisis.directory());
      expect(directory.international, isNotEmpty);
    });

    test('select returns at most three, ending internationally', () async {
      final directory = expectOk(await crisis.directory());
      for (final country in [...directory.countries.keys, 'ZZ', null]) {
        final selected = expectOk(await crisis.select(country: country));
        expect(selected.length, lessThanOrEqualTo(CrisisDirectory.maxResults));
        expect(selected.last, directory.international.last);
      }
    });

    test("a known country's lines come first", () async {
      final directory = expectOk(await crisis.directory());
      final country = directory.countries.keys.first;
      final selected = expectOk(await crisis.select(country: country));
      expect(selected.first, directory.countries[country]!.first);
    });

    test('an unknown country falls back by locale', () async {
      final directory = expectOk(await crisis.directory());
      final entry = directory.localeFallback.entries.firstWhere(
        (e) => e.value != null,
      );
      final selected = expectOk(
        await crisis.select(country: 'ZZ', locale: entry.key),
      );
      expect(selected.first, directory.countries[entry.value]!.first);
    });
  });
}
