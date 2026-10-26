import 'dart:io';

// Run from the workspace root, which resolves taro_dart_tools as a workspace
// member; the root pubspec deliberately has no dependency on it.
// ignore: depend_on_referenced_packages
import 'package:taro_dart_tools/tokens.dart';

/// `dart run tools/tokens/generate.dart [--check]`: DTCG tokens →
/// `packages/taro_ui/lib/src/tokens/generated/taro_tokens.g.dart` (02 §14.1).
/// The logic lives in `tools/dart_tools/lib/tokens.dart` (covered there).
void main(List<String> args) {
  exitCode = runTokensGenerate(args);
}
