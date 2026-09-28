import 'dart:typed_data';

import 'package:taro_core/src/result/result.dart';

/// Share sheet and file picker (backup export/import, 02 §5).
abstract interface class FileTransfer {
  /// Shares [bytes] as [fileName] with MIME type [mime].
  Future<Result<void>> share(Uint8List bytes, String fileName, String mime);

  /// Lets the user pick a JSON file; `null` when they cancel.
  Future<Result<Uint8List?>> pickJson();
}
