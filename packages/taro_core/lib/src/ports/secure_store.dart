import 'package:taro_core/src/result/result.dart';

/// Key-value secure storage (Keychain / Keystore, 02 §5, §6.2).
///
/// Keys are the `taro.*` names of 02 §6.2 (GLOSSARY §12).
abstract interface class SecureStore {
  /// The value for [key], or `null` when absent.
  Future<Result<String?>> read(String key);

  /// Stores [value] under [key].
  Future<Result<void>> write(String key, String value);

  /// Removes [key]; succeeds when it is already absent.
  Future<Result<void>> delete(String key);
}
