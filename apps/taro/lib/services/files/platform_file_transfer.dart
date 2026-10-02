import 'dart:io' show FileSystemException;
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:taro_core/taro_core.dart';

/// Opens the system picker restricted to `.json` files; an empty list when
/// the user cancels.
typedef JsonFilePicker = Future<List<PlatformFile>> Function();

/// Where the iPad share popover points; `null` on phones is fine.
typedef ShareOrigin = Rect? Function();

/// The production [FileTransfer] over `share_plus` and `file_picker`
/// (backup export / import, 02 §5, §12).
///
/// A dismissed share sheet is not an error. Platform and file-system
/// errors map to `StorageFailure`; anything else to `UnexpectedFailure`.
final class PlatformFileTransfer implements FileTransfer {
  /// A transfer over [share] and [pick] (defaults: the plugins).
  PlatformFileTransfer({
    required Logger logger,
    SharePlus? share,
    JsonFilePicker? pick,
    ShareOrigin? origin,
  }) : _logger = logger.child('files'),
       _share = share ?? SharePlus.instance,
       _pick = pick ?? pickJsonFiles,
       _origin = origin ?? centreOfFirstView;

  final Logger _logger;
  final SharePlus _share;
  final JsonFilePicker _pick;
  final ShareOrigin _origin;

  /// The `file_picker` call: one `.json` file.
  static Future<List<PlatformFile>> pickJsonFiles() => FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['json'],
  );

  /// A 1 × 1 rect in the middle of the first Flutter view (iPad popovers
  /// need an anchor); `null` when there is no view.
  static Rect? centreOfFirstView() {
    final views = PlatformDispatcher.instance.views;
    if (views.isEmpty) return null;
    final view = views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: 1,
      height: 1,
    );
  }

  @override
  Future<Result<void>> share(
    Uint8List bytes,
    String fileName,
    String mime,
  ) async {
    try {
      await _share.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: mime, name: fileName)],
          fileNameOverrides: [fileName],
          sharePositionOrigin: _origin(),
        ),
      );
      return const Result.ok(null);
    } on Object catch (error, stack) {
      return Result.err(_failure('share', error, stack));
    }
  }

  @override
  Future<Result<Uint8List?>> pickJson() async {
    try {
      final files = await _pick();
      if (files.isEmpty) return const Result.ok(null);
      final file = files.first;
      final size = await file.length();
      if (size == null || size <= BackupSchemaV1.maxFileBytes) {
        return Result.ok(await file.readAsBytes());
      }
      return Result.ok(await _readPastLimit(file));
    } on Object catch (error, stack) {
      return Result.err(_failure('pick', error, stack));
    }
  }

  /// A file over the backup limit is read only until it passes
  /// [BackupSchemaV1.maxFileBytes], so a huge pick never sits in memory
  /// whole; the validator then reports `tooLarge`.
  static Future<Uint8List> _readPastLimit(PlatformFile file) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.readAsByteStream()) {
      builder.add(chunk);
      if (builder.length > BackupSchemaV1.maxFileBytes) break;
    }
    return builder.takeBytes();
  }

  Failure _failure(String action, Object error, StackTrace stack) {
    _logger.warning('$action failed', error: error, stack: stack);
    return switch (error) {
      PlatformException() || FileSystemException() => const Failure.storage(),
      _ => Failure.unexpected(error: error, stack: stack),
    };
  }
}
