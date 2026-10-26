import 'dart:io';

// Run from the workspace root, which resolves taro_dart_tools as a workspace
// member; the root pubspec deliberately has no dependency on it.
// ignore: depend_on_referenced_packages
import 'package:taro_dart_tools/tokens.dart';

/// `dart run tools/tokens/validate_tokens.dart`: the 01 §14 token contract
/// check (names in both modes, reduced motion, fonts per script, contrast).
/// The logic lives in `tools/dart_tools/lib/tokens.dart` (covered there).
void main(List<String> args) {
  exitCode = runTokensValidate(args);
}
