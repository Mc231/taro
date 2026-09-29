import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/services/backup/platform_backup_exclusion.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = PlatformBackupExclusion.defaultChannel;
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  runBackupExclusionContract(PlatformBackupExclusion.new);

  test('sends the paths to the Runner', () async {
    final result = await const PlatformBackupExclusion().exclude([
      '/d/taro_device.db',
      '/d/taro_device.db-wal',
    ]);
    expect(result.isOk, isTrue);
    expect(calls.single.method, 'exclude');
    expect(calls.single.arguments, {
      'paths': ['/d/taro_device.db', '/d/taro_device.db-wal'],
    });
  });

  test('a platform error maps to StorageFailure', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'exclude_failed'),
    );
    final result = await const PlatformBackupExclusion().exclude(['/x']);
    expect(result.failureOrNull, const Failure.storage());
  });

  test('a missing plugin maps to StorageFailure', () async {
    messenger.setMockMethodCallHandler(channel, null);
    final result = await const PlatformBackupExclusion(
      channel: MethodChannel('taro/unregistered'),
    ).exclude(['/x']);
    expect(result.failureOrNull, const Failure.storage());
  });
}
