import 'dart:io';

import 'package:taro_dart_tools/check_architecture.dart';

/// Import-graph gate (02 §2.1, §11; 06 §6.2). See the library docs.
void main(List<String> args) {
  exitCode = checkArchitecture(args);
}
