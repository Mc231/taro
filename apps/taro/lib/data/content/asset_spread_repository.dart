import 'package:taro/data/content/content_asset_store.dart';
import 'package:taro/data/content/content_assets.dart';
import 'package:taro/data/content/content_manifest.dart';
import 'package:taro_core/taro_core.dart';

/// The bundled spread definitions from `assets/deck/spreads.json`
/// (01 §10.2–10.3).
final class AssetSpreadRepository {
  /// Creates the repository over [store].
  AssetSpreadRepository(this.store);

  /// The bundled content.
  final ContentAssetStore store;

  List<SpreadDefinition>? _spreads;

  /// Every spread, in file order, checked with [SpreadDefinition.problems]
  /// and cached. `enabled` is always `true` here; `spreads.enabled` from
  /// remote config is applied by the caller.
  Future<Result<List<SpreadDefinition>>> spreads() async {
    final cached = _spreads;
    if (cached != null) return Ok(cached);
    return guardContent(() async {
      final json = await store.json(ContentAssets.spreadsFile);
      final spreads = [
        for (final raw in ContentJson.list(json, 'spreads'))
          parseSpread(ContentJson.object(raw)),
      ];
      return _spreads = List.unmodifiable(spreads);
    });
  }
}

/// Parses one compiled spread; throws a [FormatException] on a wrong shape
/// or a broken [SpreadDefinition.problems] invariant.
SpreadDefinition parseSpread(Map<String, Object?> json) {
  final spread = SpreadDefinition(
    id: SpreadId(ContentJson.req<String>(json, 'id')),
    version: ContentJson.req<int>(json, 'version'),
    allowsReversals: ContentJson.req<bool>(json, 'allowsReversals'),
    questionSuggestionKeys: ContentJson.strings(json, 'questionSuggestionKeys'),
    positions: [
      for (final raw in ContentJson.list(json, 'positions'))
        () {
          final p = ContentJson.object(raw);
          return SpreadPosition(
            id: PositionId(ContentJson.req<String>(p, 'id')),
            order: ContentJson.req<int>(p, 'order'),
            x: ContentJson.req<num>(p, 'x').toDouble(),
            y: ContentJson.req<num>(p, 'y').toDouble(),
            rotationDeg: ContentJson.req<num>(p, 'rotationDeg').toDouble(),
          );
        }(),
    ],
  );
  final problems = spread.problems;
  if (problems.isNotEmpty) throw FormatException(problems.join('; '));
  return spread;
}
