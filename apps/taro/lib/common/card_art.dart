import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';
import 'package:taro_ui/taro_ui.dart';

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
  /// The art set shipped with v1 (= `deck_meta.json` `artSet`; used while
  /// the deck loads, so no placeholder art flashes in).
  static const String defaultArtSet = 'codex_v1';

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

  /// The card back of [artSet] (`card_back` in `art_manifest.json`).
  /// `TaroCardBack` adds the decode width of its size.
  static ImageProvider back({String artSet = defaultArtSet}) =>
      AssetImage('assets/deck/art/$artSet/card_back.webp');

  /// Decodes the back of [artSet] at the width `TaroCardBack` of [size]
  /// decodes it (`ResizeImage` of [back] at [cacheWidthOf] the card width),
  /// so the first face-down cards show the art without the ornament
  /// flashing in. Missing art is ignored.
  static Future<void> precacheBack(
    BuildContext context, {
    String artSet = defaultArtSet,
    TaroCardSize size = TaroCardSize.sm,
  }) => precacheImage(
    ResizeImage(
      back(artSet: artSet),
      width: cacheWidthOf(context, size.widthIn(context)),
    ),
    context,
    onError: (_, _) {},
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

/// Supplies the bundled card back of the deck's art set to every
/// `TaroCardBack` below it (a [TaroCardBackArt]; the default set while the
/// deck loads). `TaroApp` places it above all routes. After the first frame
/// it precaches the back at the `TaroCardBack` decode width
/// ([CardArt.precacheBack]), once per art set.
class CardBackArtScope extends ConsumerStatefulWidget {
  /// Creates the scope around [child].
  const CardBackArtScope({required this.child, super.key});

  /// The subtree whose card backs show the art.
  final Widget child;

  @override
  ConsumerState<CardBackArtScope> createState() => _CardBackArtScopeState();
}

class _CardBackArtScopeState extends ConsumerState<CardBackArtScope> {
  /// The art set whose back is already precached (or scheduled).
  String? _precached;

  @override
  Widget build(BuildContext context) {
    final artSet = ref.watch(deckArtSetProvider).value ?? CardArt.defaultArtSet;
    if (_precached != artSet) {
      // Once per art set, after the frame: never blocks the first frame.
      _precached = artSet;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(CardArt.precacheBack(context, artSet: artSet));
      });
    }
    return TaroCardBackArt(
      image: CardArt.back(artSet: artSet),
      child: widget.child,
    );
  }
}
