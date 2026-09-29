import 'package:taro/data/content/content_asset_store.dart';
import 'package:taro_core/taro_core.dart';

/// The bundled deck from `assets/deck/deck_meta.json` (01 §10.1, 02 §4).
final class AssetDeckRepository {
  /// Creates the repository over [store].
  AssetDeckRepository(this.store);

  /// The bundled content.
  final ContentAssetStore store;

  Deck? _deck;

  /// The 78-card deck, validated once and cached; `Err(StorageFailure)` if
  /// the manifest is missing, corrupt or not the canonical deck.
  Future<Result<Deck>> deck() async {
    final cached = _deck;
    if (cached != null) return Ok(cached);
    return guardContent(() async {
      final manifest = await store.manifest();
      return _deck = manifest.deck();
    });
  }
}
