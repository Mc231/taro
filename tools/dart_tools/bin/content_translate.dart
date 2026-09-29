import 'dart:io';

import 'package:taro_dart_tools/content.dart';

/// Machine-translates en content (tools/content/translate).
Future<void> main(List<String> args) async {
  exitCode = await runContentTranslate(args);
}
