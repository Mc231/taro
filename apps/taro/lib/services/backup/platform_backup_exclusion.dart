import 'package:flutter/services.dart';
import 'package:taro_core/taro_core.dart';

/// iOS [BackupExclusion]: sets `NSURLIsExcludedFromBackupKey` on each file
/// through the `taro/backup_exclusion` channel (`BackupExclusionPlugin` in
/// `ios/Runner/AppDelegate.swift`; 02 §6.1, RC75). Android uses
/// [NoOpBackupExclusion]: its exclusion is declarative XML.
final class PlatformBackupExclusion implements BackupExclusion {
  /// An exclusion over [channel].
  const PlatformBackupExclusion({this.channel = defaultChannel});

  /// The channel the Runner registers.
  static const defaultChannel = MethodChannel('taro/backup_exclusion');

  /// The platform channel.
  final MethodChannel channel;

  @override
  Future<Result<void>> exclude(List<String> paths) async {
    try {
      await channel.invokeMethod<void>('exclude', {'paths': paths});
      return const Result.ok(null);
    } on PlatformException {
      return const Result.err(Failure.storage());
    } on MissingPluginException {
      return const Result.err(Failure.storage());
    }
  }
}
