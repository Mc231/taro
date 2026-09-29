import 'package:flutter/services.dart';
import 'package:taro/data/content/asset_crisis_resources_repository.dart';
import 'package:taro/data/content/asset_deck_repository.dart';
import 'package:taro/data/content/asset_meaning_repository.dart';
import 'package:taro/data/content/asset_spread_repository.dart';
import 'package:taro/data/content/content_asset_store.dart';
import 'package:taro/data/content/content_manifest.dart';
import 'package:taro_core/taro_core.dart';

/// [ContentRepository] over the bundled `assets/deck/` content (02 §5,
/// RC26): the deck, spread and meaning repositories plus the crisis
/// directory, sharing one [ContentAssetStore].
final class AssetContentRepository implements ContentRepository {
  /// Creates the repository from its parts.
  AssetContentRepository({
    required this.decks,
    required this.spreadDefinitions,
    required this.meanings,
    required this.crisis,
  });

  /// All parts over one store for [bundle] (`rootBundle` in the app).
  factory AssetContentRepository.fromBundle(
    AssetBundle bundle, {
    BackgroundRunner? runner,
  }) {
    final store = ContentAssetStore(bundle, runner: runner);
    return AssetContentRepository(
      decks: AssetDeckRepository(store),
      spreadDefinitions: AssetSpreadRepository(store),
      meanings: AssetMeaningRepository(store),
      crisis: AssetCrisisResourcesRepository(store),
    );
  }

  /// The deck.
  final AssetDeckRepository decks;

  /// The spreads.
  final AssetSpreadRepository spreadDefinitions;

  /// The card texts.
  final AssetMeaningRepository meanings;

  /// The crisis directory.
  final AssetCrisisResourcesRepository crisis;

  @override
  Future<Result<Deck>> deck() => decks.deck();

  @override
  Future<Result<List<SpreadDefinition>>> spreads() =>
      spreadDefinitions.spreads();

  @override
  Future<Result<CardText>> cardText(CardId cardId, String locale) =>
      meanings.cardText(cardId, locale);

  @override
  Future<Result<List<CrisisResource>>> fallbackCrisisResources(
    String region,
  ) => crisis.select(country: region);
}
