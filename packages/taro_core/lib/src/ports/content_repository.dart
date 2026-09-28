import 'package:taro_core/src/model/card_text.dart';
import 'package:taro_core/src/model/crisis_resource.dart';
import 'package:taro_core/src/model/deck.dart';
import 'package:taro_core/src/model/spread.dart';
import 'package:taro_core/src/result/ids.dart';
import 'package:taro_core/src/result/result.dart';

/// Bundled content from `apps/taro/assets/deck/` (02 §5, RC26).
abstract interface class ContentRepository {
  /// The 78-card deck.
  Future<Result<Deck>> deck();

  /// Every spread definition (01 §10.3), enabled or not.
  Future<Result<List<SpreadDefinition>>> spreads();

  /// The text of [cardId] in [locale] (falls back to `en`).
  Future<Result<CardText>> cardText(CardId cardId, String locale);

  /// The bundled crisis resources for [region] (RC25).
  Future<Result<List<CrisisResource>>> fallbackCrisisResources(String region);
}
