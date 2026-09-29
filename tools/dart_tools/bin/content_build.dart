import 'dart:io';

import 'package:taro_dart_tools/content.dart';

/// Builds the deck assets and Worker feeds (tools/content/build).
void main(List<String> args) {
  exitCode = runContentBuild(args);
}
