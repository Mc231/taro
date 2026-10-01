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

  /// The face of [id] in [artSet]. With [cacheWidth] (physical pixels) the
  /// art is decoded at that width instead of its full size (02 §17).
  static ImageProvider face(
    CardId id, {
    String artSet = defaultArtSet,
    int? cacheWidth,
  }) => ResizeImage.resizeIfNeeded(
    cacheWidth,
    null,
    AssetImage('assets/deck/art/$artSet/${id.value}.webp'),
  );

  /// The decode width in physical pixels of a card [logicalWidth] wide in
  /// [context] (the `cacheWidth` of [face]).
  static int cacheWidthOf(BuildContext context, double logicalWidth) =>
      (logicalWidth * MediaQuery.devicePixelRatioOf(context)).ceil();

  /// Decodes the faces of [ids] ahead of their reveal (02 §17: the spread
  /// art is precached before the cards turn over). Missing art is ignored.
  static Future<void> precacheFaces(
    BuildContext context,
    Iterable<CardId> ids, {
    required double logicalWidth,
    String artSet = defaultArtSet,
  }) {
    final width = cacheWidthOf(context, logicalWidth);
    return Future.wait([
      for (final id in ids)
        precacheImage(
          face(id, artSet: artSet, cacheWidth: width),
          context,
          onError: (_, _) {},
        ),
    ]);
  }
}
