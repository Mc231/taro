import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/secure/flutter_secure_store.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';
import '../../../../../packages/taro_core/test/fakes/fakes.dart';

/// Records the options of every call; [error] makes every call throw.
final class _RecordingStorage extends Fake implements FlutterSecureStorage {
  _RecordingStorage([this.error]);

  final Exception? error;
  final List<(String, AppleOptions?, AndroidOptions?)> calls = [];

  Future<T> _call<T>(
    String op,
    AppleOptions? i,
    AndroidOptions? a,
    T value,
  ) async {
    calls.add((op, i, a));
    if (error case final e?) throw e;
    return value;
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => _call('read', iOptions, aOptions, 'value');

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => _call('write', iOptions, aOptions, null);

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => _call('delete', iOptions, aOptions, null);
}

void main() {
  runSecureStoreContract(() {
    FlutterSecureStorage.setMockInitialValues({});
    return FlutterSecureStore(logger: CapturingLogger());
  });

  test('iOS: this device only after first unlock, no iCloud sync', () {
    expect(
      FlutterSecureStore.iosOptions.accessibility,
      KeychainAccessibility.first_unlock_this_device,
    );
    expect(FlutterSecureStore.iosOptions.synchronizable, isFalse);
  });

  test('Android: encrypted prefs, never reset silently', () {
    final options = FlutterSecureStore.androidOptions.toMap();
    expect(options['resetOnError'], 'false');
    expect(options['storageCipherAlgorithm'], 'AES_GCM_NoPadding');
    // Default file names: the backup rules exclude them.
    expect(FlutterSecureStore.androidOptions.preferencesKeyPrefix, isNull);
    expect(FlutterSecureStore.androidOptions.storageNamespace, isNull);
  });

  test('every call passes both platform options', () async {
    final storage = _RecordingStorage();
    final store = FlutterSecureStore(
      logger: CapturingLogger(),
      storage: storage,
    );
    expect(expectOk(await store.read('k')), 'value');
    expectOk(await store.write('k', 'v'));
    expectOk(await store.delete('k'));
    expect(storage.calls, [
      for (final op in ['read', 'write', 'delete'])
        (op, FlutterSecureStore.iosOptions, FlutterSecureStore.androidOptions),
    ]);
  });

  test('a platform error is StorageFailure, logged by type only', () async {
    final logger = CapturingLogger();
    final store = FlutterSecureStore(
      logger: logger,
      storage: _RecordingStorage(
        PlatformException(code: 'Keystore', message: 'secret-value broke'),
      ),
    );
    expect(expectErr(await store.read('k')), const Failure.storage());
    expect(expectErr(await store.write('k', 'v')), const Failure.storage());
    expect(expectErr(await store.delete('k')), const Failure.storage());
    expect(logger.messages, [
      'secure storage read failed: PlatformException',
      'secure storage write failed: PlatformException',
      'secure storage delete failed: PlatformException',
    ]);
    expect(logger.records.first.logger, 'taro.secure');
    expect(logger.at(LogLevel.severe), hasLength(3));
  });
}
