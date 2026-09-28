import 'package:taro_core/src/model/remote_config.dart';
import 'package:taro_core/src/result/result.dart';

/// Worker remote config (`GET /v1/config` with ETag, 02 §5, §9.4).
abstract interface class RemoteConfigRepository {
  /// The current config: last fetched, else cached, else
  /// `RemoteConfig.defaults`.
  RemoteConfig get current;

  /// Emits every new config.
  Stream<RemoteConfig> watch();

  /// Fetches the config (304 keeps [current]).
  Future<Result<RemoteConfig>> refresh();
}
