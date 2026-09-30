import 'dart:io';

import 'package:taro_dart_tools/tokens.dart';

/// `dart run tools/tokens/generate.dart [--check]`: DTCG tokens →
/// `packages/taro_ui/lib/src/tokens/generated/taro_tokens.g.dart` (02 §14.1).
/// The logic lives in `tools/dart_tools/lib/tokens.dart` (covered there).
void main(List<String> args) {
  exitCode = runTokensGenerate(args);
}
