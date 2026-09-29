import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taro_core/taro_core.dart';

/// The [SecureStore] adapter over `flutter_secure_storage` (02 §6.2).
///
/// iOS: Keychain with `first_unlock_this_device` (not synced to iCloud
/// Keychain; survives a reinstall on the same device). Android: the
/// plugin's Keystore-wrapped AES-GCM encrypted preferences, with the
/// default file names that the backup rules exclude, and **no** silent
/// reset on a decryption error: a broken store surfaces as
/// [StorageFailure] (S01 `storageError`) instead of a second install ID.
final class FlutterSecureStore implements SecureStore {
  /// Creates the store over [storage] (the platform plugin by default).
  FlutterSecureStore({required Logger logger, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(),
      _logger = logger.child('secure');

  final FlutterSecureStorage _storage;
  final Logger _logger;

  /// Keychain options: this device only, after the first unlock.
  static const IOSOptions iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  /// Encrypted preferences; a decryption error is reported, not wiped.
  static const AndroidOptions androidOptions = AndroidOptions(
    resetOnError: false,
  );

  @override
  Future<Result<String?>> read(String key) => _guard(
    'read',
    () => _storage.read(
      key: key,
      iOptions: iosOptions,
      aOptions: androidOptions,
    ),
  );

  @override
  Future<Result<void>> write(String key, String value) => _guard(
    'write',
    () => _storage.write(
      key: key,
      value: value,
      iOptions: iosOptions,
      aOptions: androidOptions,
    ),
  );

  @override
  Future<Result<void>> delete(String key) => _guard(
    'delete',
    () => _storage.delete(
      key: key,
      iOptions: iosOptions,
      aOptions: androidOptions,
    ),
  );

  Future<Result<T>> _guard<T>(String op, Future<T> Function() run) async {
    try {
      return Result.ok(await run());
    } on Object catch (error) {
      // The error type only: platform messages may echo keys or values.
      _logger.severe('secure storage $op failed: ${error.runtimeType}');
      return const Result.err(Failure.storage());
    }
  }
}
