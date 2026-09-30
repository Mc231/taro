import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'deck_browser_controller.freezed.dart';

/// The deck sections of S16 (01 §7.9: Major Arcana, Wands, Cups, Swords,
/// Pentacles), in display order.
enum DeckSectionKind {
  /// The 22 Major Arcana.
  majorArcana,

  /// Wands (fire).
  wands,

  /// Cups (water).
  cups,

  /// Swords (air).
  swords,

  /// Pentacles (earth).
  pentacles;

  /// The section of [card].
  static DeckSectionKind of(DeckCard card) => switch (card.suit) {
    null => majorArcana,
    Suit.wands => wands,
    Suit.cups => cups,
    Suit.swords => swords,
    Suit.pentacles => pentacles,
  };
}

/// One grid tile: the card and its localized name.
@freezed
abstract class DeckTile with _$DeckTile {
  /// Creates a tile.
  const factory DeckTile({required DeckCard card, required String name}) =
      _DeckTile;
}

/// One section of the grid.
@freezed
abstract class DeckSection with _$DeckSection {
  /// Creates a section.
  const factory DeckSection({
    required DeckSectionKind kind,
    required List<DeckTile> tiles,
  }) = _DeckSection;
}

/// S16 Learn deck browser (01 §7.9, §8.3). Learn is offline and ungated.
@freezed
sealed class DeckBrowserState with _$DeckBrowserState {
  /// Reading the bundled deck.
  const factory DeckBrowserState.loading() = DeckBrowserLoading;

  /// The grid grouped by section, filtered by [query].
  const factory DeckBrowserState.content({
    required List<DeckSection> sections,
    @Default('') String query,
  }) = DeckBrowserContent;

  /// No card matches [query] ("No cards match “…”").
  const factory DeckBrowserState.searchEmpty({required String query}) =
      DeckBrowserSearchEmpty;

  /// The bundled content could not be read.
  const factory DeckBrowserState.storageError() = DeckBrowserStorageError;
}

/// Drives S16: the 78 cards with their localized names, and a search over
/// the name and the keywords (01 §7.9).
final class DeckBrowserController extends Notifier<DeckBrowserState> {
  List<({DeckTile tile, String haystack})>? _cards;
  String _query = '';

  @override
  DeckBrowserState build() {
    unawaited(_load());
    return const DeckBrowserState.loading();
  }

  /// Filters by [text] (name or keyword, case-insensitive) and logs
  /// `learn_search` for a non-empty search.
  Future<void> search(String text) async {
    _query = text.trim();
    _update();
    if (_query.isEmpty || _cards == null) return;
    final hits = switch (state) {
      DeckBrowserContent(:final sections) => sections.fold<int>(
        0,
        (sum, s) => sum + s.tiles.length,
      ),
      _ => 0,
    };
    await ref
        .read(analyticsServiceProvider)
        .log(
          LearnSearchEvent(resultsBucket: SearchResultsBucket.fromCount(hits)),
        );
  }

  Future<void> _load() async {
    final content = ref.read(contentRepositoryProvider);
    final locale = ref.read(appLocaleProvider)();
    final deck = await content.deck();
    if (!ref.mounted) return;
    switch (deck) {
      case Err():
        state = const DeckBrowserState.storageError();
      case Ok(value: final d):
        final cards = <({DeckTile tile, String haystack})>[];
        for (final card in d.cards) {
          final text = await content.cardText(card.id, locale);
          if (!ref.mounted) return;
          if (text case Ok(:final value)) {
            cards.add((
              tile: DeckTile(card: card, name: value.name),
              haystack: [
                value.name,
                ...value.keywordsUpright,
                ...value.keywordsReversed,
              ].join('\n').toLowerCase(),
            ));
          } else {
            state = const DeckBrowserState.storageError();
            return;
          }
        }
        _cards = cards;
        _update();
    }
  }

  void _update() {
    final cards = _cards;
    if (cards == null || !ref.mounted) return;
    final needle = _query.toLowerCase();
    final bySection = <DeckSectionKind, List<DeckTile>>{};
    for (final c in cards) {
      if (needle.isNotEmpty && !c.haystack.contains(needle)) continue;
      bySection
          .putIfAbsent(DeckSectionKind.of(c.tile.card), () => [])
          .add(c.tile);
    }
    if (bySection.isEmpty) {
      state = DeckBrowserState.searchEmpty(query: _query);
      return;
    }
    state = DeckBrowserState.content(
      query: _query,
      sections: [
        for (final kind in DeckSectionKind.values)
          if (bySection[kind] case final tiles?)
            DeckSection(
              kind: kind,
              tiles: List.unmodifiable(
                tiles..sort((a, b) => a.card.number.compareTo(b.card.number)),
              ),
            ),
      ],
    );
  }
}

/// S16 controller.
final NotifierProvider<DeckBrowserController, DeckBrowserState>
deckBrowserControllerProvider = NotifierProvider.autoDispose(
  DeckBrowserController.new,
);
