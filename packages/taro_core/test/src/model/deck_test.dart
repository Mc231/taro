import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'model_fixtures.dart';

void main() {
  group('kCardIds', () {
    test('is the 78 RC1 IDs in GLOSSARY §1 order', () {
      expect(kCardIds, hasLength(78));
      expect(kCardIds.toSet(), hasLength(78));
      expect(kCardIds.first, const CardId('major_00'));
      expect(kCardIds[21], const CardId('major_21'));
      expect(kCardIds[22], const CardId('wands_01'));
      expect(kCardIds.last, const CardId('pentacles_14'));
      expect(kCardIds.every((id) => CardId.isValid(id.value)), isTrue);
    });
  });

  group('DeckCard', () {
    test('every fixture card is consistent', () {
      for (final card in allCards()) {
        expect(card.problems, isEmpty, reason: card.id.value);
      }
    });

    test('value equality and copyWith', () {
      final a = cardFor(const CardId('cups_03'));
      final b = cardFor(const CardId('cups_03'));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      final c = a.copyWith(astrology: 'venus');
      expect(c.astrology, 'venus');
      expect(c, isNot(a));
      expect(c.copyWith(astrology: null), a);
      expect(a.element, Element.water);
      expect(a.toString(), contains('cups_03'));
    });

    final cases = <String, (DeckCard, String)>{
      'invalid ID': (
        const DeckCard(
          id: CardId('major_22'),
          arcana: Arcana.major,
          suit: null,
          number: 22,
          artKey: 'x',
        ),
        'not an RC1 card ID',
      ),
      'major with suit': (
        const DeckCard(
          id: CardId('major_01'),
          arcana: Arcana.major,
          suit: Suit.cups,
          number: 1,
          artKey: 'x',
        ),
        'has no suit',
      ),
      'minor without suit': (
        const DeckCard(
          id: CardId('cups_01'),
          arcana: Arcana.minor,
          suit: null,
          number: 1,
          artKey: 'x',
        ),
        'needs a suit',
      ),
      'major number out of range': (
        const DeckCard(
          id: CardId('major_00'),
          arcana: Arcana.major,
          suit: null,
          number: -1,
          artKey: 'x',
        ),
        'major number must be 0–21',
      ),
      'minor number out of range': (
        const DeckCard(
          id: CardId('cups_14'),
          arcana: Arcana.minor,
          suit: Suit.cups,
          number: 15,
          artKey: 'x',
        ),
        'minor number must be 1–14',
      ),
      'ID mismatch': (
        const DeckCard(
          id: CardId('cups_03'),
          arcana: Arcana.minor,
          suit: Suit.swords,
          number: 3,
          artKey: 'x',
        ),
        'does not match',
      ),
    };
    for (final MapEntry(key: name, value: c) in cases.entries) {
      test('problems: $name', () {
        expect(c.$1.problems, contains(contains(c.$2)));
      });
    }

    test('expectedId of a minor card without a suit', () {
      expect(cases['minor without suit']!.$1.expectedId, 'none_01');
    });
  });

  group('Deck', () {
    Deck validDeck() => Deck.validated(
      id: 'rws_original',
      version: 1,
      cards: allCards(),
      artSet: 'original',
    );

    test('accepts exactly the 78 canonical cards', () {
      final deck = validDeck();
      expect(deck.cards, hasLength(Deck.size));
      expect(Deck.problemsOf(deck.cards), isEmpty);
      expect(deck.contains(const CardId('major_00')), isTrue);
      expect(deck.card(const CardId('cups_03'))!.suit, Suit.cups);
      expect(() => deck.cards.add(allCards().first), throwsUnsupportedError);
    });

    test('card lookup misses unknown IDs', () {
      final deck = Deck(
        id: 'd',
        version: 1,
        cards: allCards()..removeLast(),
        artSet: 'a',
      );
      expect(deck.card(const CardId('pentacles_14')), isNull);
      expect(deck.contains(const CardId('pentacles_14')), isFalse);
    });

    test('value equality and copyWith', () {
      expect(validDeck(), validDeck());
      expect(validDeck().copyWith(version: 2).version, 2);
    });

    test('rejects 77 cards', () {
      final cards = allCards()..removeLast();
      expect(Deck.problemsOf(cards), [
        'expected 78 cards, got 77',
        'missing pentacles_14',
      ]);
      expect(
        () => Deck.validated(id: 'd', version: 1, cards: cards, artSet: 'a'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('missing pentacles_14'),
          ),
        ),
      );
    });

    test('rejects a duplicate replacing a card', () {
      final cards = allCards()
        ..removeLast()
        ..add(cardFor(const CardId('major_00')));
      expect(
        Deck.problemsOf(cards),
        containsAll(['duplicate card IDs', 'missing pentacles_14']),
      );
    });

    test('rejects an inconsistent card', () {
      final cards = allCards();
      cards[0] = cards[0].copyWith(number: 5);
      expect(Deck.problemsOf(cards), [contains('does not match')]);
    });
  });

  group('CardText', () {
    const aspects = CardAspects(
      relationshipsUpright: 'ru',
      relationshipsReversed: 'rr',
      workUpright: 'wu',
      workReversed: 'wr',
      growthUpright: 'gu',
      growthReversed: 'gr',
    );
    const text = CardText(
      cardId: CardId('major_00'),
      locale: 'en',
      name: 'The Fool',
      keywordsUpright: ['beginnings'],
      keywordsReversed: ['recklessness'],
      shortUpright: 'su',
      shortReversed: 'sr',
      meaningUpright: 'mu',
      meaningReversed: 'mr',
      aspects: aspects,
      reflectionQuestions: ['q1', 'q2', 'q3'],
      sourceHash: 'abc',
      reviewStatus: ReviewStatus.reviewed,
    );

    test('selects text by orientation', () {
      expect(text.keywords(reversed: false), ['beginnings']);
      expect(text.keywords(reversed: true), ['recklessness']);
      expect(text.short(reversed: false), 'su');
      expect(text.short(reversed: true), 'sr');
      expect(text.meaning(reversed: false), 'mu');
      expect(text.meaning(reversed: true), 'mr');
    });

    test('value equality and copyWith', () {
      expect(text, text.copyWith());
      final other = text.copyWith(imageryNote: 'note');
      expect(other.imageryNote, 'note');
      expect(other, isNot(text));
      expect(aspects.copyWith(workUpright: 'x').workUpright, 'x');
      expect(aspects, isNot(aspects.copyWith(growthReversed: 'y')));
    });
  });
}
