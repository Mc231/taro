import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/golden/load_taro_test_fonts.dart';
import 'helpers/golden/taro_golden_comparator.dart';

/// Runs before every test file of `taro_ui`: installs the 0.1% golden
/// comparator and the bundled Noto test fonts (06 QA8).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  goldenFileComparator = TaroGoldenComparator.replacing(goldenFileComparator);
  await loadTaroTestFonts();
  await testMain();
}
