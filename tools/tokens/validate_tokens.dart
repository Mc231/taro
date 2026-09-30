import 'dart:io';

import 'package:taro_dart_tools/tokens.dart';

/// `dart run tools/tokens/validate_tokens.dart`: the 01 §14 token contract
/// check (names in both modes, reduced motion, fonts per script, contrast).
/// The logic lives in `tools/dart_tools/lib/tokens.dart` (covered there).
void main(List<String> args) {
  exitCode = runTokensValidate(args);
}
