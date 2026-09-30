import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

part 'card_detail_controller.freezed.dart';

/// Opens S17 for [cardId] from [origin] (`learn_card_viewed.origin`).
@freezed
abstract class CardDetailArgs with _$CardDetailArgs {
  /// Creates the arguments.
  const factory CardDetailArgs({
    required CardId cardId,
    @Default(LearnCardOrigin.deck) LearnCardOrigin origin,
  }) = _CardDetailArgs;
}

/// Everything S17 shows for one card.
@freezed
abstract class CardDetailView with _$CardDetailView {
  /// Creates a view.
  const factory CardDetailView({
    required DeckCard card,
    required CardText text,

    /// "In your journal: drawn N times" (local count, links to a filtered
    /// journal; 0 = "Not in your journal yet").
    required int drawnCount,

    /// 1-based position within its section ("Cups · 3 of 14").
    required int position,

    /// The section size.
    required int sectionSize,

    /// The previous card in deck order, if any.
    CardId? previous,

    /// The next card in deck order, if any.
    CardId? next,
  }) = _CardDetailView;
}

/// S17 Learn card detail (01 §7.9, §8.3).
@freezed
sealed class CardDetailState with _$CardDetailState {
  /// Reading the bundled content.
  const factory CardDetailState.loading() = CardDetailLoading;

  /// Upright keywords, meaning and aspects.
  const factory CardDetailState.upright(CardDetailView view) =
      CardDetailUpright;

  /// Reversed keywords, meaning and aspects (art rotated 180°).
  const factory CardDetailState.reversed(CardDetailView view) =
      CardDetailReversed;

  /// Full-screen art (never mirrored); [reversed] is kept for the return.
  const factory CardDetailState.zoomed(
    CardDetailView view, {
    required bool reversed,
  }) = CardDetailZoomed;

  /// The card or its text is missing from the bundle.
  const factory CardDetailState.storageError() = CardDetailStorageError;
}

/// Drives S17 for one card: orientation toggle, zoom, the local "drawn N
/// times" count and previous/next in deck order.
final class CardDetailController extends Notifier<CardDetailState> {
  /// A controller for [args].
  CardDetailController(this.args);

  /// The card and the opening origin.
  final CardDetailArgs args;

  CardDetailView? _view;
  bool _reversed = false;
  bool _zoomed = false;
  int _drawn = 0;

  @override
  CardDetailState build() {
    final journal = ref.watch(journalRepositoryProvider);
    final counts = journal
        .watchAll(query: JournalQuery(cardId: args.cardId))
        .listen((items) {
          _drawn = items.length;
          final view = _view;
          if (view == null) return;
          _view = view.copyWith(drawnCount: _drawn);
          _update();
        }, onError: (Object _) {});
    ref.onDispose(() => unawaited(counts.cancel()));
    unawaited(_load());
    return const CardDetailState.loading();
  }

  /// The Upright / Reversed toggle.
  Future<void> setReversed({required bool reversed}) async {
    if (_view == null || reversed == _reversed) return;
    _reversed = reversed;
    _update();
    await _logViewed();
  }

  /// Tap on the art: full-screen zoom.
  void zoom() {
    if (_view == null) return;
    _zoomed = true;
    _update();
  }

  /// Closes the zoom.
  void closeZoom() {
    _zoomed = false;
    _update();
  }

  Future<void> _load() async {
    final content = ref.read(contentRepositoryProvider);
    final deck = await content.deck();
    final card = deck.valueOrNull?.card(args.cardId);
    if (!ref.mounted) return;
    if (card == null) {
      state = const CardDetailState.storageError();
      return;
    }
    final text = await content.cardText(
      args.cardId,
      ref.read(appLocaleProvider)(),
    );
    if (!ref.mounted) return;
    switch (text) {
      case Err():
        state = const CardDetailState.storageError();
      case Ok(:final value):
        final all = deck.valueOrNull!.cards;
        final ordered = [
          for (final id in kCardIds)
            if (all.any((c) => c.id == id)) id,
        ];
        final index = ordered.indexOf(args.cardId);
        final section = [
          for (final c in all)
            if (c.suit == card.suit) c,
        ]..sort((a, b) => a.number.compareTo(b.number));
        _view = CardDetailView(
          card: card,
          text: value,
          drawnCount: _drawn,
          position: section.indexOf(card) + 1,
          sectionSize: section.length,
          previous: index > 0 ? ordered[index - 1] : null,
          next: index < ordered.length - 1 ? ordered[index + 1] : null,
        );
        _update();
        await _logViewed();
    }
  }

  Future<void> _logViewed() => ref
      .read(analyticsServiceProvider)
      .log(
        LearnCardViewedEvent(
          card: AnalyticsCardId.fromId(args.cardId),
          orientation: _reversed
              ? CardOrientation.reversed
              : CardOrientation.upright,
          origin: args.origin,
        ),
      );

  void _update() {
    final view = _view;
    if (view == null || !ref.mounted) return;
    state = _zoomed
        ? CardDetailState.zoomed(view, reversed: _reversed)
        : _reversed
        ? CardDetailState.reversed(view)
        : CardDetailState.upright(view);
  }
}

/// S17 controllers by card.
final NotifierProviderFamily<
  CardDetailController,
  CardDetailState,
  CardDetailArgs
>
cardDetailControllerProvider = NotifierProvider.autoDispose.family(
  CardDetailController.new,
);
