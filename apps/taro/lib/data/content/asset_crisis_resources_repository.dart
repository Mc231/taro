import 'package:taro/data/content/content_asset_store.dart';
import 'package:taro/data/content/content_assets.dart';
import 'package:taro/data/content/content_manifest.dart';
import 'package:taro_core/taro_core.dart';

/// The `verifiedAt` given to a bundled entry the owner has not verified yet
/// ([CrisisResource.unverifiedAt]).
final DateTime kUnverifiedCrisisResourceAt = CrisisResource.unverifiedAt;

/// The bundled crisis-line directory `assets/deck/crisis_resources.json`
/// (RC25, RC81), used by S27 from Help and offline.
final class AssetCrisisResourcesRepository
    implements CrisisResourcesRepository {
  /// Creates the repository over [store].
  AssetCrisisResourcesRepository(this.store);

  /// The bundled content.
  final ContentAssetStore store;

  CrisisDirectory? _directory;

  @override
  Future<Result<CrisisDirectory>> directory() async {
    final cached = _directory;
    if (cached != null) return Ok(cached);
    return guardContent(() async {
      final json = await store.json(ContentAssets.crisisResourcesFile);
      return _directory = parseCrisisDirectory(json);
    });
  }

  /// Up to [CrisisDirectory.maxResults] entries: [country] (device region)
  /// first, else the country of the [locale]'s language, always ending with
  /// the international entries.
  @override
  Future<Result<List<CrisisResource>>> select({
    String? country,
    String? locale,
  }) async => (await directory()).map(
    (d) => d.select(
      country: country,
      locale: locale?.split(RegExp('[-_]')).first.toLowerCase(),
    ),
  );
}

/// Parses the compiled directory, mapping `verifiedAt: null` to
/// [kUnverifiedCrisisResourceAt]; throws a [FormatException].
CrisisDirectory parseCrisisDirectory(Map<String, Object?> json) {
  Object? entry(Object? raw) {
    final e = ContentJson.object(raw);
    return e['verifiedAt'] == null
        ? {...e, 'verifiedAt': kUnverifiedCrisisResourceAt.toIso8601String()}
        : e;
  }

  final countries = ContentJson.map(json, 'countries');
  return CrisisDirectory.fromJson({
    'countries': {
      for (final code in countries.keys)
        code: [
          for (final raw in ContentJson.list(countries, code)) entry(raw),
        ],
    },
    'localeFallback': ContentJson.map(json, 'localeFallback'),
    'international': [
      for (final raw in ContentJson.list(json, 'international')) entry(raw),
    ],
  });
}
