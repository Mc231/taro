import 'dart:io';

import 'package:taro_dart_tools/content.dart';

/// App assets vs Worker feeds parity (tools/content/sync_check).
void main(List<String> args) {
  exitCode = runContentSyncCheck(args);
}
