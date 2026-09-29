import 'dart:io';

import 'package:taro_dart_tools/content.dart';

/// Validates apps/taro/content/source/ (tools/content/validate).
void main(List<String> args) {
  exitCode = runContentValidate(args);
}
