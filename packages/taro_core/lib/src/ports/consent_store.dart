import 'package:taro_core/src/model/consent_state.dart';
import 'package:taro_core/src/result/result.dart';

/// Persistence of [ConsentState] (`consent_state` in `taro_device.db`,
/// never backed up or exported; 02 §5, §9.7).
abstract interface class ConsentStore {
  /// The current consent state (defaults before the first write).
  ConsentState get current;

  /// Emits the state and every change.
  Stream<ConsentState> watch();

  /// Applies [change] atomically and returns the new state.
  Future<Result<ConsentState>> update(
    ConsentState Function(ConsentState current) change,
  );
}
