import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

/// The art set of the bundled deck (`deck_meta.json` `artSet`, RC26).
final FutureProvider<String> deckArtSetProvider = FutureProvider((ref) async {
  final deck = await ref.watch(contentRepositoryProvider).deck();
  return deck.valueOrNull?.artSet ?? CardArt.defaultArtSet;
});

/// The text of one card in the app language (`cardTextProvider(cardId)`);
/// `null` when the bundle cannot be read.
final FutureProviderFamily<CardText?, CardId> cardTextProvider = FutureProvider
    .autoDispose
    .family<CardText?, CardId>((ref, id) async {
      final locale = ref.watch(appLocaleProvider)();
      final text = await ref
          .watch(contentRepositoryProvider)
          .cardText(id, locale);
      return text.valueOrNull;
    });

/// Asset images of the bundled card art (`apps/taro/assets/deck/art/`).
abstract final class CardArt {
  /// The art set shipped with v1.
  static const String defaultArtSet = 'placeholder';

  /// The face of [id] in [artSet].
  static ImageProvider face(CardId id, {String artSet = defaultArtSet}) =>
      AssetImage('assets/deck/art/$artSet/${id.value}.webp');
}
