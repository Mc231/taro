import 'dart:io';

import 'package:taro_dart_tools/gen_coverage_all.dart';

/// Generates `test/coverage_all_test.dart` for a package (06 QA4).
Future<void> main(List<String> args) async {
  exitCode = await genCoverageAll(args);
}
