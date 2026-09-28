import 'package:taro_core/src/model/crisis_resource.dart';
import 'package:taro_core/src/result/result.dart';

/// The bundled crisis-line directory (RC25, RC81) for S27 from Help and
/// offline. Declined readings carry the Worker's own selection instead.
abstract interface class CrisisResourcesRepository {
  /// The whole bundled directory.
  Future<Result<CrisisDirectory>> directory();

  /// Up to `CrisisDirectory.maxResults` resources for [country] (device
  /// region), falling back by [locale], then international.
  Future<Result<List<CrisisResource>>> select({
    String? country,
    String? locale,
  });
}
