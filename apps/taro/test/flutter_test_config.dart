import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../../../packages/taro_ui/test/helpers/golden/load_taro_test_fonts.dart';
import '../../../packages/taro_ui/test/helpers/golden/taro_golden_comparator.dart';

/// Runs before every test file of `apps/taro`: installs the 0.1% golden
/// comparator and the bundled Noto test fonts (06 QA8).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  goldenFileComparator = TaroGoldenComparator.replacing(goldenFileComparator);
  await loadTaroTestFonts();
  await testMain();
}
